#ifndef QUEUESESSION_H
#define QUEUESESSION_H

#include <vector>
#include <functional>
#include "queue.h"

class QueueSession
{
public:
    QueueSession();
    ~QueueSession();

    // --- Callbacks ---
    std::function<void()> onQueuesChanged;
    std::function<void()> onPlayingQueueChanged;
    std::function<void()> onViewedQueueChanged;

    // --- Queue access ---
    Queue *playingQueue() const;
    Queue *viewedQueue()  const;
    Queue *queueAt(int index) const;
    int    queueCount()       const;

    // --- Index access ---
    int playingQueueIndex() const;
    int viewedQueueIndex()  const;

    // --- Index mutation ---
    void setPlayingQueueIndex(int index);
    void setViewedQueueIndex(int index);

    // --- Queue list mutation ---
    void appendQueue(Queue *queue);
    void removeQueueAt(int index);
    void moveQueue(int from, int to);

    // --- Convenience ---
    bool isValidIndex(int index) const;

private:
    std::vector<Queue *> m_queues;
    int m_playingQueueIndex = -1;
    int m_viewedQueueIndex  = -1;
};

#endif // QUEUESESSION_H