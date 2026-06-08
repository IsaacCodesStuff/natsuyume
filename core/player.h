#ifndef PLAYER_H
#define PLAYER_H

#include <QObject>
#include <QList>
#include <QStringList>
#include <QtQml/qqml.h>
#include "queue.h"
#include "coverimageprovider.h"
#include "library.h"
#include "fileindexer.h"
#include "albumcoverprovider.h"

class Player : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    // --- Playback ---
    Q_PROPERTY(bool isPlaying READ isPlaying NOTIFY isPlayingChanged)
    Q_PROPERTY(qint64 position READ position NOTIFY positionChanged)
    Q_PROPERTY(qint64 duration READ duration NOTIFY durationChanged)
    Q_PROPERTY(float volume READ volume WRITE setVolume NOTIFY volumeChanged)

    // --- Metadata ---
    Q_PROPERTY(QString trackTitle READ trackTitle NOTIFY metadataChanged)
    Q_PROPERTY(QString trackArtist READ trackArtist NOTIFY metadataChanged)
    Q_PROPERTY(QString trackAlbum READ trackAlbum NOTIFY metadataChanged)
    Q_PROPERTY(bool hasCoverArt READ hasCoverArt NOTIFY metadataChanged)

    // --- Track navigation ---
    Q_PROPERTY(int trackIndex READ trackIndex NOTIFY trackChanged)
    Q_PROPERTY(int trackCount READ trackCount NOTIFY trackChanged)
    Q_PROPERTY(bool hasPrevious READ hasPrevious NOTIFY trackChanged)
    Q_PROPERTY(bool hasNext READ hasNext NOTIFY trackChanged)

    // --- Multi-queue ---
    Q_PROPERTY(int queueCount READ queueCount NOTIFY queuesChanged)
    Q_PROPERTY(int activeQueueIndex READ activeQueueIndex NOTIFY queuesChanged)
    Q_PROPERTY(QStringList queueNames READ queueNames NOTIFY queuesChanged)

    // --- Repeat ---
    Q_PROPERTY(int repeatMode READ repeatMode NOTIFY repeatModeChanged)

    // --- Shuffle ---
    Q_PROPERTY(bool isShuffled READ isShuffled NOTIFY shuffleChanged)

    // --- Favorites ---
    Q_PROPERTY(bool isFavorite READ isFavorite NOTIFY isFavoriteChanged)

    // --- Track List ---
    Q_PROPERTY(QVariantList trackList READ trackList NOTIFY trackChanged)

    // --- Library ---
    Q_PROPERTY(QStringList allAlbums READ allAlbums NOTIFY libraryChanged)
    Q_PROPERTY(QStringList allArtists READ allArtists NOTIFY libraryChanged)
    Q_PROPERTY(bool isScanning READ isScanning NOTIFY scanningChanged)
    Q_PROPERTY(int scanProgress READ scanProgress NOTIFY scanProgressChanged)
    Q_PROPERTY(int scanTotal READ scanTotal NOTIFY scanProgressChanged)
    Q_PROPERTY(QString scanningFile READ scanningFile NOTIFY scanProgressChanged)

    Q_INVOKABLE QString albumCoverPath(const QString &album) const;

    // --- Sort ---
    Q_PROPERTY(int albumSort READ albumSort WRITE setAlbumSort NOTIFY albumSortChanged)
    Q_PROPERTY(bool albumSortAscending READ albumSortAscending WRITE setAlbumSortAscending NOTIFY albumSortChanged)
    Q_PROPERTY(int trackSort READ trackSort WRITE setTrackSort NOTIFY trackSortChanged)
    Q_PROPERTY(bool trackSortAscending READ trackSortAscending WRITE setTrackSortAscending NOTIFY trackSortChanged)

public:
    explicit Player(QObject *parent = nullptr);
    ~Player();

    // --- Playback getters ---
    bool isPlaying() const;
    qint64 position() const;
    qint64 duration() const;
    float volume() const;

    // --- Metadata getters ---
    QString trackTitle() const;
    QString trackArtist() const;
    QString trackAlbum() const;
    bool hasCoverArt() const;

    // --- Track navigation getters ---
    int trackIndex() const;
    int trackCount() const;
    bool hasPrevious() const;
    bool hasNext() const;

    // --- Multi-queue getters ---
    int queueCount() const;
    int activeQueueIndex() const;
    QStringList queueNames() const;

    // --- Repeat getter ---
    int repeatMode() const;

    // --- Shuffle getter ---
    bool isShuffled() const;

    // --- Favorites getter ---
    bool isFavorite() const;

    // --- Track List getter ---
    QVariantList trackList() const;

    // --- Library ---
    QStringList allAlbums() const;
    QStringList allArtists() const;
    bool isScanning() const;
    int scanProgress() const;
    int scanTotal() const;

    // --- Sort ---
    int  albumSort() const;
    bool albumSortAscending() const;
    int  trackSort() const;
    bool trackSortAscending() const;

    // --- Invokables ---
    Q_INVOKABLE void setVolume(float volume);

    Q_INVOKABLE void play();
    Q_INVOKABLE void pause();
    Q_INVOKABLE void seekTo(qint64 positionMs);
    Q_INVOKABLE void playNext();
    Q_INVOKABLE void playPrevious();

    Q_INVOKABLE void cycleRepeatMode();
    Q_INVOKABLE void toggleShuffle();

    Q_INVOKABLE void openFilesInNewQueue(const QStringList &filePaths);
    Q_INVOKABLE void addTrackToActiveQueue(const QString &filePath);
    Q_INVOKABLE void switchToQueue(int index);
    Q_INVOKABLE void closeQueue(int index);
    Q_INVOKABLE void renameQueue(int index, const QString &name);

    Q_INVOKABLE void toggleFavorite();

    Q_INVOKABLE void jumpToTrack(int index);
    Q_INVOKABLE void removeTrackAt(int index);

    Q_INVOKABLE void scanFolder(const QString &folderPath);
    Q_INVOKABLE void cancelScan();
    Q_INVOKABLE QVariantList tracksForAlbum(const QString &album) const;
    Q_INVOKABLE QVariantList tracksForArtist(const QString &artist) const;

    void setCoverImageProvider(CoverImageProvider *provider);
    void setAlbumCoverProvider(AlbumCoverProvider *provider);
    void registerAlbumCovers(AlbumCoverProvider *provider);

    void setKnownPaths(const QSet<QString> &paths);

    Q_INVOKABLE void setAlbumSort(int sort);
    Q_INVOKABLE void setAlbumSortAscending(bool ascending);
    Q_INVOKABLE void setTrackSort(int sort);
    Q_INVOKABLE void setTrackSortAscending(bool ascending);

signals:
    void isPlayingChanged();
    void positionChanged();
    void durationChanged();
    void volumeChanged();
    void metadataChanged();
    void trackChanged();
    void queuesChanged();
    void repeatModeChanged();
    void shuffleChanged();
    void isFavoriteChanged();
    void coverArtChanged();
    void libraryChanged();
    void scanningChanged();
    void scanProgressChanged();
    void albumSortChanged();
    void trackSortChanged();

private:
    QList<Queue*> m_queues;
    int m_activeQueueIndex;
    float m_volume;
    QStringList m_favorites;

    Queue *activeQueue() const;
    QString generateQueueName() const;
    void connectQueueSignals(Queue *queue);

    CoverImageProvider *m_coverImageProvider = nullptr;
    void pushCoverArt();

    Library     *m_library;
    FileIndexer *m_indexer;
    int          m_scanProgress;
    int          m_scanTotal;

    QString scanningFile() const;
    QString m_scanningFile;
    AlbumCoverProvider *m_albumCoverProvider = nullptr;

    Library::AlbumSort m_albumSort;
    bool               m_albumSortAscending;
    Library::TrackSort m_trackSort;
    bool               m_trackSortAscending;
};

#endif // PLAYER_H