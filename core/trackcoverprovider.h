#ifndef TRACKCOVERPROVIDER_H
#define TRACKCOVERPROVIDER_H

#include <QQuickImageProvider>
#include <QMutex>
#include "metadata.h"

class TrackCoverProvider : public QQuickImageProvider
{
public:
    explicit TrackCoverProvider();

    QImage requestImage(const QString &id, QSize *size,
                        const QSize &requestedSize) override;

private:
    mutable QMutex m_mutex;
};

#endif // TRACKCOVERPROVIDER_H