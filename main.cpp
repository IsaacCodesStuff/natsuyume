#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include "natsuyumecore.h"
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

    QPixmapCache::setCacheLimit(10 * 1024);

    // Create and initialise the core before loading QML
    Natsuyume::NatsuyumeCore *core = new Natsuyume::NatsuyumeCore();
    core->init();

    // Create the Qt adapter, injecting the core
    PlayerController *player = new PlayerController(core, nullptr);
    player->setCoverImageProvider(coverProvider);
    player->setAlbumCoverProvider(albumCoverProvider);

    // Expose to QML
    engine.setInitialProperties({{"player", QVariant::fromValue(player)}});

    engine.loadFromModule("natsuyume_player", "Main");

    int result = QGuiApplication::exec();

    core->shutdown();
    delete player;
    delete core;

    return result;
}