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

QStringList FileIndexer::collectFiles(const QString &folderPath) const
{
    QDir dir(folderPath);
    QStringList files;
    QDirIterator it(
        folderPath,
        QDir::Files | QDir::NoDotAndDotDot,
        QDirIterator::Subdirectories
        );
    int count = 0;
    while (it.hasNext()) {
        QString path = it.next();
        count++;
        QString ext = QFileInfo(path).suffix().toLower();
        if (s_supportedExtensions.contains(ext))
            files.append(path);
    }
    return files;
}

void FileIndexer::doScan(const QString &folderPath)
{
    QStringList files = collectFiles(folderPath);
    int total = files.size();

    emit scanStarted(total);

    for (int i = 0; i < total; i++) {
        if (m_cancelled) {
            emit scanCancelled();
            return;
        }

        const QString &path = files.at(i);

        if (!m_knownPaths.contains(path)) {
            Track track = Metadata::read(path);
            emit trackFound(track);
            m_knownPaths.insert(path);
        }

        emit scanProgress(i + 1, total, QFileInfo(path).fileName());
    }

    emit scanFinished();
}