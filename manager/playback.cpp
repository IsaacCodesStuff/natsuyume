#include "playback.h"

Playback::Playback(QObject *parent)
    : QObject{parent}
{
    m_player = new QMediaPlayer(this);
    m_audioOutput = new QAudioOutput(this);
    m_player->setAudioOutput(m_audioOutput);

    connect(m_player, &QMediaPlayer::playbackStateChanged, this, [this]() {
        emit playbackStateChanged();
    });

    connect(m_player, &QMediaPlayer::positionChanged, this, [this]() {
        emit positionChanged();
    });

    connect(m_player, &QMediaPlayer::durationChanged, this, [this]() {
        emit durationChanged();
    });

    connect(m_player, &QMediaPlayer::mediaStatusChanged, this,
            [this](QMediaPlayer::MediaStatus status) {
                if (status == QMediaPlayer::LoadedMedia)
                    m_player->play();
                    emit readyToPlay();
                if (status == QMediaPlayer::EndOfMedia)
                    emit trackEnded();
            });
}

Playback::~Playback() {}

void Playback::play()
{
    m_player->play();
}

void Playback::pause()
{
    m_player->pause();
}

void Playback::seekTo(qint64 positionMs)
{
    m_player->setPosition(positionMs);
}

void Playback::loadTrack(const Track &track)
{
    if (!track.isValid())
        return;
    m_player->setSource(QUrl::fromLocalFile(track.path));
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