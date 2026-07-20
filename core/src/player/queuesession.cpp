#include "queuesession.h"
#include <algorithm>

QueueSession::QueueSession() = default;

QueueSession::~QueueSession()
{
    for (Queue *q : m_queues)
        delete q;
    m_queues.clear();
}

Queue *QueueSession::playingQueue() const
{
    if (m_playingQueueIndex < 0 ||
        m_playingQueueIndex >= (int)m_queues.size())
        return nullptr;
    return m_queues.at(m_playingQueueIndex);
}

Queue *QueueSession::viewedQueue() const
{
    if (m_viewedQueueIndex < 0 ||
        m_viewedQueueIndex >= (int)m_queues.size())
        return nullptr;
    return m_queues.at(m_viewedQueueIndex);
}

Queue *QueueSession::queueAt(int index) const
{
    if (index < 0 || index >= (int)m_queues.size()) return nullptr;
    return m_queues.at(index);
}

int QueueSession::queueCount() const
{
    return (int)m_queues.size();
}

int QueueSession::playingQueueIndex() const { return m_playingQueueIndex; }
int QueueSession::viewedQueueIndex()  const { return m_viewedQueueIndex; }

void QueueSession::setPlayingQueueIndex(int index)
{
    if (m_playingQueueIndex == index) return;
    m_playingQueueIndex = index;
    if (onPlayingQueueChanged) onPlayingQueueChanged();
    if (onQueuesChanged)       onQueuesChanged();
}

void QueueSession::setViewedQueueIndex(int index)
{
    if (m_viewedQueueIndex == index) return;
    m_viewedQueueIndex = index;
    if (onViewedQueueChanged) onViewedQueueChanged();
    if (onQueuesChanged)      onQueuesChanged();
}

void QueueSession::appendQueue(Queue *queue)
{
    if (!queue) return;
    m_queues.push_back(queue);
    if (onQueuesChanged) onQueuesChanged();
}

void QueueSession::removeQueueAt(int index)
{
    if (!isValidIndex(index)) return;
    m_queues.erase(m_queues.begin() + index);
    if (onQueuesChanged) onQueuesChanged();
}

void QueueSession::moveQueue(int from, int to)
{
    if (!isValidIndex(from) || !isValidIndex(to)) return;
    if (from == to) return;

    Queue *q = m_queues[from];
    m_queues.erase(m_queues.begin() + from);
    m_queues.insert(m_queues.begin() + to, q);

    if (onQueuesChanged) onQueuesChanged();
}

bool QueueSession::isValidIndex(int index) const
{
    return index >= 0 && index < (int)m_queues.size();
}