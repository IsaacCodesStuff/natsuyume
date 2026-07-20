#ifndef LIBRARYMANAGER_H
#define LIBRARYMANAGER_H

#include <string>
#include <vector>
#include <functional>
#include <mutex>
#include <queue>
#include "library.h"
#include "fileindexer.h"

class LibraryManager
{
public:
    LibraryManager();
    ~LibraryManager();

    // --- Initialization ---
    bool open(const std::string &dataDir);

    // --- Callbacks ---
    std::function<void()> onLibraryChanged;
    std::function<void()> onScanningChanged;
    std::function<void(int current, int total, const std::string &file)>
                          onScanProgressChanged;
    std::function<void()> onScanFoldersChanged;
    std::function<void()> onAlbumSortChanged;
    std::function<void()> onTrackSortChanged;
    std::function<void()> onArtistSortChanged;

    // --- Library access ---
    Library *library() const;

    std::vector<std::string> allAlbums()                              const;
    std::vector<std::string> allArtists()                             const;
    std::vector<std::string> allArtistsSorted()                       const;
    std::vector<std::string> albumsForArtist(const std::string &artist) const;
    std::vector<Track>       tracksForAlbum(const std::string &album) const;
    std::vector<Track>       tracksForArtist(const std::string &artist) const;
    std::string              albumCoverPath(const std::string &album) const;

    // --- Scanning ---
    void scanFolder(const std::string &folderPath);
    void cancelScan();
    void rescanAllFolders();
    void addScanFolder(const std::string &path);
    void removeScanFolder(const std::string &path);

    std::vector<std::string> scanFolders()  const;
    bool        isScanning()   const;
    int         scanProgress() const;
    int         scanTotal()    const;
    std::string scanningFile() const;

    // --- Sort ---
    int  albumSort()             const;
    bool albumSortAscending()    const;
    void setAlbumSort(int sort);
    void setAlbumSortAscending(bool ascending);

    int  trackSort()             const;
    bool trackSortAscending()    const;
    void setTrackSort(int sort);
    void setTrackSortAscending(bool ascending);

    int  artistSort()            const;
    bool artistSortAscending()   const;
    void setArtistSort(int sort);
    void setArtistSortAscending(bool ascending);

    // --- Settings persistence (backed by SQLite via dataDir) ---
    void loadSettings();
    void saveSettings();

    // --- Called by NatsuyumeCore on the main thread ---
    void drainCallbacks();

private:
    Library     *m_library = nullptr;
    FileIndexer *m_indexer = nullptr;

    std::vector<std::string> m_scanFolders;
    int         m_scanProgress = 0;
    int         m_scanTotal    = 0;
    std::string m_scanningFile;
    std::string m_dataDir;

    Library::AlbumSort  m_albumSort           = Library::AlbumSort::Name;
    bool                m_albumSortAscending  = true;
    Library::TrackSort  m_trackSort           = Library::TrackSort::TrackNumber;
    bool                m_trackSortAscending  = true;
    Library::ArtistSort m_artistSort          = Library::ArtistSort::Name;
    bool                m_artistSortAscending = true;

    // Thread-safe callback queue
    std::mutex                        m_callbackMutex;
    std::queue<std::function<void()>> m_pendingCallbacks;

    void post(std::function<void()> fn);
    void connectIndexerCallbacks();
    void scanFoldersSequentially(int index);
};

#endif // LIBRARYMANAGER_H