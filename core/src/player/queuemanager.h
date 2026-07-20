#ifndef QUEUEMANAGER_H
#define QUEUEMANAGER_H

#include <string>
#include <vector>
#include <functional>
#include <cstdint>
#include "queuesession.h"
#include "library.h"
#include "coretypes.h"

class QueueManager
{
public:
    explicit QueueManager(QueueSession *session);

    // --- Callbacks ---
    std::function<void(int newQueueIndex)> onPlaybackTransferRequested;
    std::function<void(int queueIndex)>    onPlaybackDestroyRequested;
    std::function<void(int queueIndex)>    onPlaybackInitRequested;
    std::function<void(int queueIndex)>    onPlaybackInitNewRequested;
    std::function<void(int queueIndex)>    onPlaybackRestoreRequested;

    // --- Queue lifecycle ---
    void openFilesInNewQueue(const std::vector<std::string> &paths,
                             const std::string &name = {},
                             bool shuffle = false);
    void addPathsToNewQueue(const std::vector<std::string> &paths,
                            const std::string &name = {});
    void addPathsToQueue(int queueIndex,
                         const std::vector<std::string> &paths);
    void closeQueue(int index);
    void renameQueue(int index, const std::string &name);
    void moveQueue(int from, int to);
    void viewQueue(int index);

    // --- Track manipulation (viewed queue) ---
    void addTrackToQueue(const std::string &path);
    void addAlbumToQueue(const std::string &album,
                         Library::TrackSort sort,
                         bool ascending);
    void removeTrackAt(int index);
    void moveTrack(int from, int to);
    void sortQueue(int sort, bool ascending);
    void reverseQueue();

    // --- Track lookup ---
    std::vector<Natsuyume::CoreTrack> trackList()                            const;
    Natsuyume::CoreTrack              trackInfoByPath(const std::string &path) const;
    int64_t                           queueTotalDuration()                   const;
    bool                              isAlbumActiveQueue(const std::string &album,
                                              Library::TrackSort sort,
                                              bool ascending) const;

    // --- Jump ---
    void jumpToTrack(int index);
    void jumpToTrackByPath(const std::string &path);

    // --- Persistence ---
    void saveQueues(int viewedIndex);
    void loadQueues(float volume);

    // --- Helpers ---
    std::string              generateQueueName() const;
    std::vector<std::string> queueNames()        const;
    void                     setLibrary(Library *library);

private:
    QueueSession *m_session;
    Library      *m_library = nullptr;

    void connectQueueCallbacks(Queue *queue);
};

#endif // QUEUEMANAGER_H