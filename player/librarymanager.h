#ifndef LIBRARYMANAGER_H
#define LIBRARYMANAGER_H

#include <QObject>
#include <QStringList>
#include <QVariantList>
#include <QSet>
#include "library.h"
#include "fileindexer.h"
#include "albumcoverprovider.h"

class LibraryManager : public QObject
{
    Q_OBJECT

public:
    explicit LibraryManager(QObject *parent = nullptr);
    ~LibraryManager();

    // --- Initialization ---
    bool open();
    void setAlbumCoverProvider(AlbumCoverProvider *provider);

    // --- Library access ---
    Library *library() const;

    QStringList  allAlbums()                                           const;
    QStringList  allArtists()                                          const;
    QStringList  allArtistsSorted()                                    const;
    QStringList  albumsForArtist(const QString &artist)                const;
    QVariantList tracksForAlbum(const QString &album)                  const;
    QVariantList tracksForArtist(const QString &artist)                const;
    QString      albumCoverPath(const QString &album)                  const;

    // --- Scanning ---
    void scanFolder(const QString &folderPath);
    void cancelScan();
    void rescanAllFolders();
    void addScanFolder(const QString &path);
    void removeScanFolder(const QString &path);

    QStringList scanFolders()   const;
    bool        isScanning()    const;
    int         scanProgress()  const;
    int         scanTotal()     const;
    QString     scanningFile()  const;

    // --- Sort ---
    int  albumSort()              const;
    bool albumSortAscending()     const;
    void setAlbumSort(int sort);
    void setAlbumSortAscending(bool ascending);

    int  trackSort()              const;
    bool trackSortAscending()     const;
    void setTrackSort(int sort);
    void setTrackSortAscending(bool ascending);

    int  artistSort()             const;
    bool artistSortAscending()    const;
    void setArtistSort(int sort);
    void setArtistSortAscending(bool ascending);

    // --- Settings ---
    void loadSettings();
    void saveSettings();

signals:
    void libraryChanged();
    void scanningChanged();
    void scanProgressChanged();
    void albumSortChanged();
    void trackSortChanged();
    void artistSortChanged();
    void scanFoldersChanged();

private:
    Library            *m_library      = nullptr;
    FileIndexer        *m_indexer      = nullptr;
    AlbumCoverProvider *m_albumCoverProvider = nullptr;

    QStringList m_scanFolders;
    int         m_scanProgress = 0;
    int         m_scanTotal    = 0;
    QString     m_scanningFile;

    Library::AlbumSort  m_albumSort          = Library::AlbumSort::Name;
    bool                m_albumSortAscending = true;
    Library::TrackSort  m_trackSort          = Library::TrackSort::TrackNumber;
    bool                m_trackSortAscending = true;
    Library::ArtistSort m_artistSort         = Library::ArtistSort::Name;
    bool                m_artistSortAscending = true;

    void registerAlbumCovers();
    void connectIndexerSignals();
    void scanFoldersSequentially(int index);
};

#endif // LIBRARYMANAGER_H