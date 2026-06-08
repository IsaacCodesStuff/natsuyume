#ifndef COVERIMAGEPROVIDER_H
#define COVERIMAGEPROVIDER_H

#include <QQuickImageProvider>
#include <QImage>

class CoverImageProvider : public QQuickImageProvider
{
public:
    explicit CoverImageProvider();

    void updateCover(const QImage &image);
    QImage requestImage(const QString &id, QSize *size, const QSize &requestedSize) override;

private:
    QImage m_currentCover;
};

#endif // COVERIMAGEPROVIDER_H