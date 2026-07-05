#ifndef QUEUEMANAGER_H
#define QUEUEMANAGER_H

#include <QObject>
#include <QStringList>
#include "queuesession.h"
#include "library.h"

class QueueManager : public QObject
{
    Q_OBJECT

public:
    explicit QueueManager(QueueSession *session, QObject *parent = nullptr);

    // --- Queue lifecycle ---
    void openFilesInNewQueue(const QStringList &paths,
                             const QString &name = QString(),
                             bool shuffle = false);
    void addPathsToNewQueue(const QStringList &paths,
                            const QString &name = QString());
    void addPathsToQueue(int queueIndex, const QStringList &paths);
    void closeQueue(int index);
    void renameQueue(int index, const QString &name);
    void moveQueue(int from, int to);
    void viewQueue(int index);

    // --- Track manipulation (viewed queue) ---
    void addTrackToQueue(const QString &path);
    void addAlbumToQueue(const QString &album,
                         Library::TrackSort sort,
                         bool ascending);
    void removeTrackAt(int index);
    void moveTrack(int from, int to);
    void sortQueue(int sort, bool ascending);
    void reverseQueue();

    // --- Track lookup ---
    QVariantList trackList()                          const;
    QVariantMap  trackInfoByPath(const QString &path) const;
    qint64       queueTotalDuration()                 const;
    bool         isAlbumActiveQueue(const QString &album,
                            Library::TrackSort sort,
                            bool ascending)   const;

    // --- Jump ---
    void jumpToTrack(int index);
    void jumpToTrackByPath(const QString &path);

    // --- Persistence ---
    void saveQueues(int viewedIndex);
    void loadQueues(float volume);

    // --- Queue naming ---
    QString generateQueueName() const;

    // --- Queue names for UI ---
    QStringList queueNames() const;

    // --- Set library function ---
    void setLibrary(Library *library);

signals:
    // Emitted when QueueManager needs PlaybackManager to act —
    // PlayerController connects these during wiring
    void playbackTransferRequested(int newQueueIndex);
    void playbackDestroyRequested(int queueIndex);
    void playbackInitRequested(int queueIndex);
    void playbackInitNewRequested(int queueIndex);
    void playbackRestoreRequested(int queueIndex); // startup only

private:
    QueueSession *m_session;
    Library      *m_library;

    void connectQueueSignals(Queue *queue);
};

#endif // QUEUEMANAGER_H