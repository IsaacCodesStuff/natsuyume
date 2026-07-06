#include "playback.h"
#include <QDebug>

Playback::Playback(QObject *parent)
    : QObject{parent}
{
    m_player = new QMediaPlayer(this);
    m_audioOutput = new QAudioOutput(this);
    m_player->setAudioOutput(m_audioOutput);

    connect(m_player, &QMediaPlayer::playbackStateChanged, this, [this]() {
        emit playbackStateChanged();
    });

    connect(m_player, &QMediaPlayer::errorOccurred, this,
            [this](QMediaPlayer::Error error, const QString &errorString) {
            });

    connect(m_player, &QMediaPlayer::positionChanged, this, [this]() {
        emit positionChanged();
    });

    connect(m_player, &QMediaPlayer::durationChanged, this, [this]() {
        emit durationChanged();
    });

    connect(m_player, &QMediaPlayer::mediaStatusChanged, this,
            [this](QMediaPlayer::MediaStatus status) {
                // Reset position immediately when new source starts loading
                // so QML doesn't show stale position during the async load window
                if (status == QMediaPlayer::LoadingMedia) {
                    emit positionChanged();
                    emit durationChanged();
                }

                if (status == QMediaPlayer::LoadedMedia) {
                    if (m_player->source() != m_expectedSource)
                        return;
                    if (m_pendingAutoPlay) {
                        m_pendingAutoPlay = false;
                        m_player->play();
                    }
                    emit readyToPlay();
                }

                if (status == QMediaPlayer::EndOfMedia)
                    emit trackEnded();
            });
}

Playback::~Playback()
{
    qDebug() << "Playback instance DESTROYED:" << this;
}

void Playback::play()
{
    qDebug() << "[" << this << "] Playback::play() CALLED. State before:" << m_player->playbackState();
    m_player->play();
    qDebug() << "[" << this << "] State immediately after play():" << m_player->playbackState();
}

void Playback::pause()
{
    qDebug() << "[" << this << "] Playback::pause() CALLED. State before:" << m_player->playbackState();
    m_player->pause();
}

void Playback::seekTo(qint64 positionMs)
{
    m_player->setPosition(positionMs);
}

void Playback::loadTrack(const Track &track, bool autoPlay)
{
    if (!track.isValid())
        return;
    m_pendingAutoPlay = autoPlay;
    m_expectedSource = QUrl::fromLocalFile(track.path);
    m_player->setSource(m_expectedSource);
}

bool Playback::isPlaying() const
{
    return m_player->playbackState() == QMediaPlayer::PlayingState;
}

qint64 Playback::position() const { return m_player->position(); }
qint64 Playback::duration() const { return m_player->duration(); }
float Playback::volume() const { return m_audioOutput->volume(); }

void Playback::setVolume(float volume)
{
    m_audioOutput->setVolume(volume);
}

QAudioOutput *Playback::audioOutput() const { return m_audioOutput; }