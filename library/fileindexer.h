#ifndef FILEINDEXER_H
#define FILEINDEXER_H

#include <atomic>
#include <functional>
#include <string>
#include <thread>
#include <unordered_set>
#include <vector>

#include "track.h"

class FileIndexer
{
public:
    // Callbacks replacing Qt signals
    using TracksFoundCallback    = std::function<void(const std::vector<Track> &)>;
    using ScanProgressCallback   = std::function<void(int scanned, int total, const std::string &currentFile)>;
    using ScanStartedCallback    = std::function<void(int totalFiles)>;
    using ScanFinishedCallback   = std::function<void()>;
    using ScanCancelledCallback  = std::function<void()>;
    using ScanningChangedCallback = std::function<void(bool scanning)>;

    FileIndexer();
    ~FileIndexer();

    void scanFolder(const std::string &folderPath);
    void cancel();
    void setKnownPaths(const std::unordered_set<std::string> &paths);
    bool isScanning() const;

    // Callback setters
    void onTracksFound(TracksFoundCallback cb)        { m_onTracksFound    = std::move(cb); }
    void onScanProgress(ScanProgressCallback cb)      { m_onScanProgress   = std::move(cb); }
    void onScanStarted(ScanStartedCallback cb)        { m_onScanStarted    = std::move(cb); }
    void onScanFinished(ScanFinishedCallback cb)      { m_onScanFinished   = std::move(cb); }
    void onScanCancelled(ScanCancelledCallback cb)    { m_onScanCancelled  = std::move(cb); }
    void onScanningChanged(ScanningChangedCallback cb){ m_onScanningChanged = std::move(cb); }

    static const std::vector<std::string> s_supportedExtensions;

private:
    std::thread  m_thread;
    std::atomic<bool> m_cancelled{false};
    std::atomic<bool> m_scanning{false};

    std::unordered_set<std::string> m_knownPaths;
    std::unordered_set<std::string> m_knownPathsSnapshot;

    TracksFoundCallback     m_onTracksFound;
    ScanProgressCallback    m_onScanProgress;
    ScanStartedCallback     m_onScanStarted;
    ScanFinishedCallback    m_onScanFinished;
    ScanCancelledCallback   m_onScanCancelled;
    ScanningChangedCallback m_onScanningChanged;

    void doScan(const std::string &folderPath);
};

#endif // FILEINDEXER_H