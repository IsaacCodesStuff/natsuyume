#include "queuesession.h"

QueueSession::QueueSession(QObject *parent)
    : QObject{parent}
{
}

QueueSession::~QueueSession()
{
    qDeleteAll(m_queues);
    m_queues.clear();
}

// --- Queue access ---

Queue *QueueSession::playingQueue() const
{
    if (m_playingQueueIndex < 0 || m_playingQueueIndex >= m_queues.size())
        return nullptr;
    return m_queues.at(m_playingQueueIndex);
}

Queue *QueueSession::viewedQueue() const
{
    if (m_viewedQueueIndex < 0 || m_viewedQueueIndex >= m_queues.size())
        return nullptr;
    return m_queues.at(m_viewedQueueIndex);
}

Queue *QueueSession::queueAt(int index) const
{
    if (index < 0 || index >= m_queues.size())
        return nullptr;
    return m_queues.at(index);
}

int QueueSession::queueCount() const
{
    return m_queues.size();
}

// --- Index access ---

int QueueSession::playingQueueIndex() const
{
    return m_playingQueueIndex;
}

int QueueSession::viewedQueueIndex() const
{
    return m_viewedQueueIndex;
}

// --- Index mutation ---

void QueueSession::setPlayingQueueIndex(int index)
{
    if (m_playingQueueIndex == index)
        return;
    m_playingQueueIndex = index;
    emit playingQueueChanged();
    emit queuesChanged();
}

void QueueSession::setViewedQueueIndex(int index)
{
    if (m_viewedQueueIndex == index)
        return;
    m_viewedQueueIndex = index;
    emit viewedQueueChanged();
    emit queuesChanged();
}

// --- Queue list mutation ---

void QueueSession::appendQueue(Queue *queue)
{
    if (!queue) return;
    m_queues.append(queue);
    emit queuesChanged();
}

void QueueSession::removeQueueAt(int index)
{
    if (!isValidIndex(index)) return;
    m_queues.removeAt(index);
    emit queuesChanged();
}

void QueueSession::moveQueue(int from, int to)
{
    if (!isValidIndex(from) || !isValidIndex(to)) return;
    if (from == to) return;
    m_queues.move(from, to);
    emit queuesChanged();
}

// --- Convenience ---

bool QueueSession::isValidIndex(int index) const
{
    return index >= 0 && index < m_queues.size();
}