#include "albumcoverprovider.h"
#include <QMutexLocker>
#include <QDebug>
#include <QFileInfo>

AlbumCoverProvider::AlbumCoverProvider()
    : QQuickImageProvider(QQuickImageProvider::Image)
{}

void AlbumCoverProvider::registerAlbum(const QString &albumId, const QString &filePath)
{
    QMutexLocker locker(&m_mutex);
    m_albumPaths[albumId] = filePath;
}

bool AlbumCoverProvider::hasAlbum(const QString &albumId) const
{
    QMutexLocker locker(&m_mutex);
    return m_albumPaths.contains(albumId);
}

QImage AlbumCoverProvider::requestImage(const QString &id, QSize *size, const QSize &requestedSize)
{
    QString albumName = id.section('?', 0, 0);

    QString filePath;
    {
        QMutexLocker locker(&m_mutex);
        filePath = m_albumPaths.value(albumName);
    }

    // Determine output size
    QSize outputSize = requestedSize.isValid() ? requestedSize : QSize(256, 256);

    // Always create a valid fallback image
    auto makeFallback = [&]() -> QImage {
        QImage img(outputSize, QImage::Format_ARGB32);
        img.fill(Qt::transparent);
        return img;
    };

    if (filePath.isEmpty() || !QFileInfo::exists(filePath))
        return makeFallback();

    Track track;
    {
        QMutexLocker readLocker(&m_readMutex);
        try {
            track = Metadata::read(filePath);
        } catch (...) {
            qWarning() << "AlbumCoverProvider: crashed on" << filePath;
            return makeFallback();
        }
    }

    if (track.coverArt.isNull())
        return makeFallback();

    QImage result = track.coverArt.scaled(
        outputSize,
        Qt::KeepAspectRatio,
        Qt::SmoothTransformation
        );

    if (size)
        *size = result.size();

    return result;
}