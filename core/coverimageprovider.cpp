#include "coverimageprovider.h"

CoverImageProvider::CoverImageProvider()
    : QQuickImageProvider(QQuickImageProvider::Image)
{}

void CoverImageProvider::updateCover(const QImage &image)
{
    m_currentCover = image;
}

QImage CoverImageProvider::requestImage(const QString &id, QSize *size, const QSize &requestedSize)
{
    Q_UNUSED(id)

    if (m_currentCover.isNull())
        return QImage();

    QImage result = requestedSize.isValid()
                        ? m_currentCover.scaled(requestedSize, Qt::KeepAspectRatio, Qt::SmoothTransformation)
                        : m_currentCover;

    if (size)
        *size = result.size();

    return result;
}