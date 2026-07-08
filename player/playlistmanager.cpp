#include "playlistmanager.h"
#include <QSettings>

PlaylistManager::PlaylistManager(QueueSession *session, QObject *parent)
    : QObject{parent},
    m_session{session}
{
}

void PlaylistManager::setLibrary(Library *library)
{
    m_library = library;

    if (m_library) {
        connect(m_library, &Library::playlistsChanged,
                this, &PlaylistManager::playlistsChanged);
        // Don't load favorites here — database isn't open yet
    }
}

void PlaylistManager::initialize()
{
    if (m_library)
        m_favorites = m_library->allFavoritePaths();
}

// --- Settings ---

void PlaylistManager::loadSettings()
{
    QSettings s;
    m_playlistSort = static_cast<Library::TrackSort>(
        s.value("sort/playlistSort", 0).toInt());
    m_playlistSortAscending = s.value("sort/playlistSortAscending", true).toBool();

    emit playlistSortChanged();
}

void PlaylistManager::saveSettings()
{
    QSettings s;
    s.setValue("sort/playlistSort",          static_cast<int>(m_playlistSort));
    s.setValue("sort/playlistSortAscending", m_playlistSortAscending);
}

// --- Playlists ---

QVariantList PlaylistManager::allPlaylists() const
{
    QVariantList result;
    if (!m_library) return result;

    for (const PlaylistInfo &p : m_library->allPlaylists()) {
        QVariantMap map;
        map["id"]   = p.id;
        map["name"] = p.name;
        result << map;
    }
    return result;
}

int PlaylistManager::createPlaylist(const QString &name)
{
    if (!m_library) return -1;
    return m_library->createPlaylist(name);
}

void PlaylistManager::deletePlaylist(int playlistId)
{
    if (m_library) m_library->deletePlaylist(playlistId);
}

void PlaylistManager::renamePlaylist(int playlistId, const QString &name)
{
    if (m_library) m_library->renamePlaylist(playlistId, name);
}

void PlaylistManager::addTrackToPlaylist(int playlistId, const QString &path)
{
    if (m_library) m_library->addTrackToPlaylist(playlistId, path);
}

void PlaylistManager::removeTrackFromPlaylist(int playlistId, const QString &path)
{
    if (m_library) m_library->removeTrackFromPlaylist(playlistId, path);
}

void PlaylistManager::moveTrackInPlaylist(int playlistId, int from, int to)
{
    if (m_library) m_library->moveTrackInPlaylist(playlistId, from, to);
}

void PlaylistManager::sortPlaylist(int playlistId)
{
    if (m_library)
        m_library->sortPlaylist(playlistId, m_playlistSort, m_playlistSortAscending);
}

int PlaylistManager::saveQueueAsPlaylist(const QString &name)
{
    if (!m_library) return -1;

    Queue *q = m_session->viewedQueue();
    if (!q) return -1;

    QStringList paths;
    for (const Track &t : q->tracks())
        paths << t.path;

    return m_library->saveQueueAsPlaylist(name, paths);
}

QVariantList PlaylistManager::tracksForPlaylist(int playlistId) const
{
    QVariantList result;
    if (!m_library) return result;

    if (playlistId == kFavoritesPlaylistId) {
        if (!m_library) return result;
        // Get all favorited paths
        QSet<QString> favPaths = m_library->allFavoritePaths();
        // Fetch full track data for each, using library sort order
        QList<Track> allTracks = m_library->allTracks();
        for (const Track &t : allTracks) {
            if (favPaths.contains(t.path)) {
                QVariantMap map;
                map["path"]     = t.path;
                map["title"]    = t.title;
                map["artist"]   = t.artist;
                map["album"]    = t.album;
                map["duration"] = t.duration;
                result << map;
            }
        }
        return result;
    }

    QList<Track> tracks = (playlistId == kAllSongsPlaylistId)
                              ? m_library->allTracks()
                              : m_library->tracksForPlaylist(playlistId);

    for (const Track &t : tracks) {
        QVariantMap map;
        map["path"]     = t.path;
        map["title"]    = t.title;
        map["artist"]   = t.artist;
        map["album"]    = t.album;
        map["duration"] = t.duration;
        result << map;
    }
    return result;
}

void PlaylistManager::openPlaylistInNewQueue(int playlistId, const QString &name)
{
    if (!m_library) return;

    QList<Track> tracks = (playlistId == kAllSongsPlaylistId)
                              ? m_library->allTracks()
                              : m_library->tracksForPlaylist(playlistId);

    QStringList paths;
    for (const Track &t : std::as_const(tracks))
        paths << t.path;

    if (!paths.isEmpty())
        emit openInNewQueueRequested(paths, name);
}

// --- Playlist sort ---

int  PlaylistManager::playlistSort()          const { return static_cast<int>(m_playlistSort); }
bool PlaylistManager::playlistSortAscending() const { return m_playlistSortAscending; }

void PlaylistManager::setPlaylistSort(int sort)
{
    m_playlistSort = static_cast<Library::TrackSort>(sort);
    emit playlistSortChanged();
    saveSettings();
}

void PlaylistManager::setPlaylistSortAscending(bool ascending)
{
    m_playlistSortAscending = ascending;
    emit playlistSortChanged();
    saveSettings();
}

// --- Favorites ---

bool PlaylistManager::isFavorite(const QString &path) const
{
    return m_favorites.contains(path);
}

void PlaylistManager::toggleFavorite(const QString &path)
{
    if (path.isEmpty()) return;

    bool nowFavorite = !m_favorites.contains(path);

    if (nowFavorite)
        m_favorites.insert(path);
    else
        m_favorites.remove(path);

    if (m_library)
        m_library->setFavorite(path, nowFavorite);

    emit isFavoriteChanged();
    emit playlistsChanged(); // ← refresh Favorites playlist view
}

// --- Request relays ---

void PlaylistManager::requestAddToPlaylist(const QString &path)
{
    emit addToPlaylistRequested(path);
}

void PlaylistManager::requestAddAlbumToPlaylist(const QString &albumName)
{
    emit addAlbumToPlaylistRequested(albumName);
}