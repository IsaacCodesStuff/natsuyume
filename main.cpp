#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include "playercontroller.h"
#include "coverimageprovider.h"
#include "albumcoverprovider.h"
#include "trackcoverprovider.h"
#include <QPixmapCache>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QQuickStyle::setStyle("Basic");
    QQmlApplicationEngine engine;

    CoverImageProvider *coverProvider = new CoverImageProvider();
    engine.addImageProvider("covers", coverProvider);

    AlbumCoverProvider *albumCoverProvider = new AlbumCoverProvider();
    engine.addImageProvider("albumcovers", albumCoverProvider);

    TrackCoverProvider *trackCoverProvider = new TrackCoverProvider();
    engine.addImageProvider("trackcovers", trackCoverProvider);

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);

    QPixmapCache::setCacheLimit(10 * 1024); // 10 MB instead of Qt's default 100 MB

    engine.loadFromModule("natsuyume_player", "Main");

    const auto rootObjects = engine.rootObjects();
    QObject *root = rootObjects.first();
    PlayerController *player = root->findChild<PlayerController*>();
    if (player) {
        player->setCoverImageProvider(coverProvider);
        player->setAlbumCoverProvider(albumCoverProvider);
    }

    return QGuiApplication::exec();
}