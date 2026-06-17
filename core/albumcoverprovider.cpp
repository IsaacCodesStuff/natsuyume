#include "albumcoverprovider.h"
#include <QMutexLocker>
#include <QDebug>
#include <QFileInfo>

AlbumCoverProvider::AlbumCoverProvider()
    : QQuickImageProvider(QQuickImageProvider::Image),
    m_cache(5 * 1024) // 5 MB is plenty for scaled thumbnails
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
    QSize outputSize = requestedSize.isValid() ? requestedSize : QSize(256, 256);

    auto makeFallback = [&]() -> QImage {
        QImage img(outputSize, QImage::Format_ARGB32);
        img.fill(Qt::transparent);
        return img;
    };

    // Build cache key including size so different sizes cache separately
    QString cacheKey = albumName + QString("_%1x%2")
                                       .arg(outputSize.width())
                                       .arg(outputSize.height());

    // Check cache first
    {
        QMutexLocker locker(&m_mutex);
        if (QImage *cached = m_cache.object(cacheKey)) {
            if (size) *size = cached->size();
            return *cached;
        }
    }

    QString filePath;
    {
        QMutexLocker locker(&m_mutex);
        filePath = m_albumPaths.value(albumName);
    }

    if (filePath.isEmpty() || !QFileInfo::exists(filePath))
        return makeFallback();

    Track track;
    {
        QMutexLocker readLocker(&m_readMutex);
        try {
            track = Metadata::read(filePath, true);
        } catch (...) {
            qWarning() << "AlbumCoverProvider: crashed on" << filePath;
            return makeFallback();
        }
    }

    if (track.coverArt.isNull())
        return makeFallback();

    // Scale first, then cache the small thumbnail
    QImage scaled = track.coverArt.scaled(
        outputSize,
        Qt::KeepAspectRatio,
        Qt::SmoothTransformation
        );

    // Cost in KB — scaled thumbnail is tiny
    int cost = scaled.sizeInBytes() / 1024;
    {
        QMutexLocker locker(&m_mutex);
        m_cache.insert(cacheKey, new QImage(scaled), qMax(1, cost));
    }

    if (size) *size = scaled.size();
    return scaled;
}