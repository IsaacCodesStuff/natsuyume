#include "userdatamanager.h"
#include <QSettings>
#include <QVariantMap>
#include <QSqlQuery>

UserDataManager::UserDataManager(QObject *parent)
    : QObject(parent)
{
    m_userData = new UserData(this);
}

bool UserDataManager::open()
{
    if (!m_userData->open()) return false;

    // Wire UserData signals up to manager signals
    connect(m_userData, &UserData::playlistsChanged,
            this, &UserDataManager::playlistsChanged);
    connect(m_userData, &UserData::favoritesChanged,
            this, &UserDataManager::isFavoriteChanged);

    return true;
}

void UserDataManager::setLibrary(Library *library)
{
    m_library = library;
}

// --- Favorites ---

bool UserDataManager::isFavorite(const QString &path) const
{
    return m_userData->isFavorite(path);
}

void UserDataManager::toggleFavorite(const QString &path)
{
    bool current = m_userData->isFavorite(path);
    m_userData->setFavorite(path, !current);
    // isFavoriteChanged emitted via signal chain from UserData::favoritesChanged
}

QSet<QString> UserDataManager::allFavoritePaths() const
{
    return m_userData->allFavoritePaths();
}

// --- Play stats ---

void UserDataManager::incrementPlayCount(const QString &path)
{
    m_userData->incrementPlayCount(path);
}

void UserDataManager::applyUserData(Track &track) const
{
    m_userData->applyUserData(track);
}

void UserDataManager::applyUserData(QList<Track> &tracks) const
{
    m_userData->applyUserData(tracks);
}

// --- Playlists ---

QVariantList UserDataManager::allPlaylists() const
{
    QVariantList result;
    for (const PlaylistInfo &p : m_userData->allPlaylists()) {
        QVariantMap map;
        map["id"]        = p.id;
        map["name"]      = p.name;
        map["imagePath"] = p.imagePath;
        result.append(map);
    }
    return result;
}

int UserDataManager::createPlaylist(const QString &name)
{
    return m_userData->createPlaylist(name);
}

void UserDataManager::deletePlaylist(int playlistId)
{
    m_userData->deletePlaylist(playlistId);
}

void UserDataManager::renamePlaylist(int playlistId, const QString &name)
{
    m_userData->renamePlaylist(playlistId, name);
}

void UserDataManager::setPlaylistImage(int playlistId, const QString &imagePath)
{
    m_userData->setPlaylistImage(playlistId, imagePath);
}

void UserDataManager::addTrackToPlaylist(int playlistId, const QString &path)
{
    m_userData->addTrackToPlaylist(playlistId, path);
}

void UserDataManager::removeTrackFromPlaylist(int playlistId, const QString &path)
{
    m_userData->removeTrackFromPlaylist(playlistId, path);
}

void UserDataManager::moveTrackInPlaylist(int playlistId, int from, int to)
{
    m_userData->moveTrackInPlaylist(playlistId, from, to);
}

void UserDataManager::sortPlaylist(int playlistId)
{
    // UserData can't sort by metadata — fetch sorted paths from Library,
    // then rewrite positions in userdata.db
    if (!m_library) return;

    QStringList paths = m_userData->playlistTrackPaths(playlistId);

    // Filter to only paths still in the library, sorted by library sort
    QList<Track> tracks;
    for (const QString &path : paths) {
        Track t = m_library->trackByPath(path);
        if (t.isValid()) tracks.append(t);
    }

    // Sort by current playlist sort setting
    QString sortCol = [this]() -> QString {
        switch (static_cast<Library::TrackSort>(m_playlistSort)) {
        case Library::TrackSort::Title:       return "title";
        case Library::TrackSort::Artist:      return "artist";
        case Library::TrackSort::Year:        return "year";
        case Library::TrackSort::Duration:    return "duration";
        case Library::TrackSort::TrackNumber: return "trackNumber";
        default:                              return "title";
        }
    }();

    std::sort(tracks.begin(), tracks.end(),
              [&](const Track &a, const Track &b) {
                  if (sortCol == "title")   return m_playlistSortAscending
                                 ? a.title < b.title
                                 : a.title > b.title;
                  if (sortCol == "artist")  return m_playlistSortAscending
                                 ? a.artist < b.artist
                                 : a.artist > b.artist;
                  if (sortCol == "year")    return m_playlistSortAscending
                                 ? a.year < b.year
                                 : a.year > b.year;
                  if (sortCol == "duration") return m_playlistSortAscending
                                 ? a.duration < b.duration
                                 : a.duration > b.duration;
                  // TrackNumber default
                  return m_playlistSortAscending
                             ? a.trackNumber < b.trackNumber
                             : a.trackNumber > b.trackNumber;
              });

    // Rewrite positions in userdata.db
    QSqlQuery q(m_userData->db());
    q.exec("BEGIN TRANSACTION");
    q.prepare(R"(
        UPDATE playlist_tracks SET position = :pos
        WHERE playlist_id = :id AND path = :path
    )");
    for (int i = 0; i < tracks.size(); ++i) {
        q.bindValue(":pos",  i);
        q.bindValue(":id",   playlistId);
        q.bindValue(":path", tracks[i].path);
        q.exec();
    }
    q.exec("COMMIT");
    emit playlistsChanged();
}

int UserDataManager::saveQueueAsPlaylist(const QString &name,
                                         const QStringList &paths)
{
    return m_userData->saveQueueAsPlaylist(name, paths);
}

QList<Track> UserDataManager::tracksForPlaylist(int playlistId) const
{
    if (!m_library) return {};

    QStringList paths = m_userData->playlistTrackPaths(playlistId);
    QList<Track> result;
    result.reserve(paths.size());

    for (const QString &path : paths) {
        Track t = m_library->trackByPath(path);
        if (t.isValid()) {
            m_userData->applyUserData(t);
            result.append(t);
        }
        // Tracks not in library are silently skipped —
        // they still exist in userdata.db and will reappear
        // if the library is rescanned and finds them again
    }
    return result;
}

void UserDataManager::openPlaylistInNewQueue(int playlistId,
                                             const QString &name)
{
    QStringList paths = m_userData->playlistTrackPaths(playlistId);
    if (!paths.isEmpty())
        emit openInNewQueueRequested(paths, name);
}

// --- Playlist sort ---

int  UserDataManager::playlistSort()          const { return static_cast<int>(m_playlistSort); }
bool UserDataManager::playlistSortAscending() const { return m_playlistSortAscending; }

void UserDataManager::setPlaylistSort(int sort)
{
    m_playlistSort = static_cast<Library::TrackSort>(sort);
    emit playlistSortChanged();
    saveSettings();
}

void UserDataManager::setPlaylistSortAscending(bool ascending)
{
    m_playlistSortAscending = ascending;
    emit playlistSortChanged();
    saveSettings();
}

// --- Artist images ---

void UserDataManager::setArtistImage(const QString &artist,
                                     const QString &imagePath)
{
    m_userData->setArtistImage(artist, imagePath);
}

QString UserDataManager::artistImage(const QString &artist) const
{
    return m_userData->artistImage(artist);
}

// --- Clear operations ---

void UserDataManager::clearUserData()
{
    m_userData->clearAll();
}

void UserDataManager::clearLibrary()
{
    if (m_library) m_library->clear();
}

// --- Settings ---

void UserDataManager::loadSettings()
{
    QSettings s;
    m_playlistSort = static_cast<Library::TrackSort>(
        s.value("sort/playlistSort", 0).toInt());
    m_playlistSortAscending = s.value("sort/playlistSortAscending", true).toBool();
    emit playlistSortChanged();
}

void UserDataManager::saveSettings()
{
    QSettings s;
    s.setValue("sort/playlistSort",          static_cast<int>(m_playlistSort));
    s.setValue("sort/playlistSortAscending", m_playlistSortAscending);
}

// --- Request relay ---

void UserDataManager::requestAddToPlaylist(const QString &path)
{
    emit addToPlaylistRequested(path);
}

void UserDataManager::requestAddAlbumToPlaylist(const QString &albumName)
{
    emit addAlbumToPlaylistRequested(albumName);
}

QList<PlaylistInfo> UserDataManager::rawPlaylists() const
{
    return m_userData->allPlaylists();
}