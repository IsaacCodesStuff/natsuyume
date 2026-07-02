#ifndef FILEINDEXER_H
#define FILEINDEXER_H

#include <QObject>
#include <QSet>
#include <QStringList>
#include <QThread>
#include "track.h"
#include "metadata.h"

class FileIndexer : public QObject
{
    Q_OBJECT

public:
    explicit FileIndexer(QObject *parent = nullptr);
    ~FileIndexer();

    void scanFolder(const QString &folderPath);
    void cancel();
    void setKnownPaths(const QSet<QString> &paths);

    bool isScanning() const;

signals:
    void scanStarted(int totalFiles);
    void trackFound(const Track &track);
    void tracksFound(const QList<Track> &tracks);
    void scanProgress(int scanned, int total, const QString &currentFile);
    void scanFinished();
    void scanCancelled();
    void scanningChanged();

private:
    QThread *m_thread;
    bool m_cancelled;
    bool m_scanning;

    QSet<QString> m_knownPaths;
    QSet<QString> m_knownPathsSnapshot;

    static const QStringList s_supportedExtensions;

    void doScan(const QString &folderPath);
};

#endif // FILEINDEXER_H