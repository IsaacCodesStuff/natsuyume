#ifndef ALBUMCOVERPROVIDER_H
#define ALBUMCOVERPROVIDER_H

#include <QQuickImageProvider>
#include <QMap>
#include <QMutex>
#include "metadata.h"

class AlbumCoverProvider : public QQuickImageProvider
{
public:
    explicit AlbumCoverProvider();

    void registerAlbum(const QString &albumId, const QString &filePath);
    QImage requestImage(const QString &id, QSize *size, const QSize &requestedSize) override;
    bool hasAlbum(const QString &albumId) const;

private:
    QMap<QString, QString> m_albumPaths;
    mutable QMutex m_mutex;
    mutable QMutex m_readMutex;
};

#endif // ALBUMCOVERPROVIDER_H