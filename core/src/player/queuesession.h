#ifndef QUEUESESSION_H
#define QUEUESESSION_H

#include <QObject>
#include <QList>
#include "queue.h"

class QueueSession : public QObject
{
    Q_OBJECT

public:
    explicit QueueSession(QObject *parent = nullptr);
    ~QueueSession();

    // --- Queue access ---
    Queue *playingQueue() const;
    Queue *viewedQueue()  const;

    Queue *queueAt(int index) const;
    int    queueCount()       const;

    // --- Index access ---
    int playingQueueIndex() const;
    int viewedQueueIndex()  const;

    // --- Index mutation (only QueueManager and PlayerController should call these) ---
    void setPlayingQueueIndex(int index);
    void setViewedQueueIndex(int index);

    // --- Queue list mutation (only QueueManager should call these) ---
    void appendQueue(Queue *queue);
    void removeQueueAt(int index);
    void moveQueue(int from, int to);

    // --- Convenience ---
    bool isValidIndex(int index) const;

signals:
    void queuesChanged();
    void playingQueueChanged();
    void viewedQueueChanged();

private:
    QList<Queue *> m_queues;
    int            m_playingQueueIndex = -1;
    int            m_viewedQueueIndex  = -1;
};

#endif // QUEUESESSION_H