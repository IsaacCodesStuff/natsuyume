#include "fileindexer.h"
#include <QDir>
#include <QDirIterator>
#include <QFileInfo>
#include <QDebug>

const QStringList FileIndexer::s_supportedExtensions = {
    "mp3", "flac", "wav", "ogg", "opus", "m4a"
};

FileIndexer::FileIndexer(QObject *parent)
    : QObject{parent},
    m_thread(nullptr),
    m_cancelled(false),
    m_scanning(false)
{}

FileIndexer::~FileIndexer()
{
    cancel();
}

bool FileIndexer::isScanning() const
{
    return m_scanning;
}

void FileIndexer::scanFolder(const QString &folderPath)
{
    if (m_scanning)
        return;
    m_cancelled = false;
    m_scanning  = true;
    m_knownPaths = m_knownPathsSnapshot; // sync to current library state before scanning
    m_thread = QThread::create([this, folderPath]() {
        doScan(folderPath);
    });

    connect(m_thread, &QThread::finished, this, [this]() {
        m_scanning = false;
        emit scanningChanged();  // we need to add this signal
        m_thread->deleteLater();
        m_thread = nullptr;
    });

    m_thread->start();
}

void FileIndexer::setKnownPaths(const QSet<QString> &paths)
{
    m_knownPathsSnapshot = paths;
}

void FileIndexer::cancel()
{
    if (!m_scanning) return;
    m_cancelled = true;

    if (m_thread) {
        m_thread->wait();
        m_thread->deleteLater();
        m_thread = nullptr;
    }

    m_scanning = false;
}

void FileIndexer::doScan(const QString &folderPath)
{
    // Count pass — lightweight, no metadata reads
    int total = 0;
    {
        QDirIterator counter(folderPath, QDir::Files | QDir::NoDotAndDotDot,
                             QDirIterator::Subdirectories);
        while (counter.hasNext()) {
            counter.next();
            if (s_supportedExtensions.contains(
                    QFileInfo(counter.filePath()).suffix().toLower()))
                total++;
        }
    }

    emit scanStarted(total);

    QDirIterator it(folderPath, QDir::Files | QDir::NoDotAndDotDot,
                    QDirIterator::Subdirectories);
    int i = 0;
    QList<Track> batch;
    const int batchSize = 10;

    while (it.hasNext()) {
        if (m_cancelled) {
            if (!batch.isEmpty())
                emit tracksFound(batch);
            emit scanCancelled();
            return;
        }

        QString path = it.next();
        if (!s_supportedExtensions.contains(
                QFileInfo(path).suffix().toLower()))
            continue;

        if (!m_knownPaths.contains(path)) {
            Track track = Metadata::read(path, false);
            batch.append(track);
            m_knownPaths.insert(path);

            if (batch.size() >= batchSize) {
                emit tracksFound(batch);
                batch.clear();
            }
        }

        emit scanProgress(++i, total, QFileInfo(path).fileName());
    }

    // Emit any remaining tracks
    if (!batch.isEmpty())
        emit tracksFound(batch);

    emit scanFinished();
}