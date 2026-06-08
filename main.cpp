#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include "core/player.h"
#include "core/coverimageprovider.h"
#include "core/albumcoverprovider.h"
#include "core/trackcoverprovider.h"

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

    engine.loadFromModule("natsuyume_player", "Main");

    const auto rootObjects = engine.rootObjects();
    QObject *root = rootObjects.first();
    Player *player = root->findChild<Player*>();
    if (player) {
        player->setCoverImageProvider(coverProvider);
        player->setAlbumCoverProvider(albumCoverProvider);
        player->registerAlbumCovers(albumCoverProvider);
    }

    return QGuiApplication::exec();
}