#include "trackcoverprovider.h"
#include <QMutexLocker>
#include <QFileInfo>
#include <QUrl>

TrackCoverProvider::TrackCoverProvider()
    : QQuickImageProvider(QQuickImageProvider::Image)
{}

QImage TrackCoverProvider::requestImage(const QString &id,
                                        QSize *size,
                                        const QSize &requestedSize)
{
    // Decode percent-encoded path
    QString path = QUrl::fromPercentEncoding(id.toUtf8());

    // Strip cache-busting suffix if present
    path = path.section('?', 0, 0);

    QSize outputSize = requestedSize.isValid() ? requestedSize : QSize(48, 48);

    auto makeFallback = [&]() -> QImage {
        QImage img(outputSize, QImage::Format_ARGB32);
        img.fill(Qt::transparent);
        return img;
    };

    if (path.isEmpty() || !QFileInfo::exists(path))
        return makeFallback();

    QMutexLocker locker(&m_mutex);

    Track track;
    try {
        track = Metadata::read(path);
    } catch (...) {
        return makeFallback();
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