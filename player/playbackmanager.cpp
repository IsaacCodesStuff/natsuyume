#include "playbackmanager.h"
#include "queue.h"
#include "metadata.h"
#include <QDateTime>
#include <QSettings>
#include <QDebug>

PlaybackManager::PlaybackManager(QueueSession *session, QObject *parent)
    : QObject{parent},
    m_session{session}
{
}

void PlaybackManager::setLibrary(Library *library)
{
    m_library = library;
}

void PlaybackManager::setCoverImageProvider(CoverImageProvider *provider)
{
    m_coverImageProvider = provider;
}

// --- Settings ---

void PlaybackManager::loadSettings()
{
    QSettings s;
    m_volume             = s.value("playback/volume", 0.8f).toFloat();
    m_playCountThreshold = s.value("playback/playCountThreshold", 10).toInt();

    // Apply volume to all existing queues
    for (int i = 0; i < m_session->queueCount(); i++)
        m_session->queueAt(i)->setVolume(m_volume);

    emit volumeChanged();
    emit playingTrackChanged();
}

void PlaybackManager::saveSettings()
{
    QSettings s;
    s.setValue("playback/volume",            m_volume);
    s.setValue("playback/playCountThreshold", m_playCountThreshold);
}

// --- Volume ---

float PlaybackManager::volume() const { return m_volume; }

void PlaybackManager::setVolume(float volume)
{
    m_volume = volume;
    for (int i = 0; i < m_session->queueCount(); i++)
        m_session->queueAt(i)->setVolume(volume);
    emit volumeChanged();
    saveSettings();
}

// --- Transport ---

void PlaybackManager::play()
{
    if (Queue *q = m_session->playingQueue()) q->play();
}

void PlaybackManager::pause()
{
    if (Queue *q = m_session->playingQueue()) q->pause();
}

void PlaybackManager::seekTo(qint64 positionMs)
{
    m_isSeeking = true;
    if (Queue *q = m_session->playingQueue()) q->seekTo(positionMs);
    m_isSeeking = false;
}

void PlaybackManager::playNext()
{
    if (Queue *q = m_session->playingQueue()) q->playNext();
}

void PlaybackManager::playPrevious()
{
    if (Queue *q = m_session->playingQueue()) q->playPrevious();
}

void PlaybackManager::cycleRepeatMode()
{
    if (Queue *q = m_session->playingQueue()) q->cycleRepeatMode();
}

void PlaybackManager::toggleShuffle()
{
    if (Queue *q = m_session->playingQueue()) q->toggleShuffle();
}

void PlaybackManager::toggleStopAfterCurrent()
{
    Queue *q = m_session->playingQueue();
    if (!q) return;
    q->setStopAfterCurrent(!q->stopAfterCurrent());
}

// --- Playback state getters ---

bool PlaybackManager::isPlaying() const
{
    Queue *q = m_session->playingQueue();
    return q ? q->isPlaying() : false;
}

qint64 PlaybackManager::position() const
{
    Queue *q = m_session->playingQueue();
    return q ? q->position() : 0;
}

qint64 PlaybackManager::duration() const
{
    Queue *q = m_session->playingQueue();
    return q ? q->duration() : 0;
}

int PlaybackManager::repeatMode() const
{
    Queue *q = m_session->playingQueue();
    return q ? static_cast<int>(q->repeatMode()) : 0;
}

bool PlaybackManager::isShuffled() const
{
    Queue *q = m_session->playingQueue();
    return q ? q->isShuffled() : false;
}

bool PlaybackManager::stopAfterCurrent() const
{
    Queue *q = m_session->playingQueue();
    return q ? q->stopAfterCurrent() : false;
}

// --- Now-playing metadata ---

QString PlaybackManager::trackTitle() const
{
    Queue *q = m_session->playingQueue();
    return q && q->currentTrackIndex() >= 0
               ? q->trackAt(q->currentTrackIndex()).title : "";
}

QString PlaybackManager::trackArtist() const
{
    Queue *q = m_session->playingQueue();
    return q && q->currentTrackIndex() >= 0
               ? q->trackAt(q->currentTrackIndex()).artist : "";
}

QString PlaybackManager::trackAlbum() const
{
    Queue *q = m_session->playingQueue();
    return q && q->currentTrackIndex() >= 0
               ? q->trackAt(q->currentTrackIndex()).album : "";
}

QString PlaybackManager::trackPath() const
{
    Queue *q = m_session->playingQueue();
    return q && q->currentTrackIndex() >= 0
               ? q->trackAt(q->currentTrackIndex()).path : "";
}

bool PlaybackManager::hasCoverArt() const
{
    Queue *q = m_session->playingQueue();
    if (!q || q->currentTrackIndex() < 0) return false;
    return !q->trackAt(q->currentTrackIndex()).path.isEmpty();
}

QString PlaybackManager::rawLyrics() const { return m_rawLyrics; }

QVariantList PlaybackManager::lyricLines() const
{
    QVariantList result;
    for (const LrcLine &line : m_lyricLines) {
        QVariantMap map;
        map["timestamp"] = line.timestamp;
        map["text"]      = line.text;
        result << map;
    }
    return result;
}

bool PlaybackManager::lyricsAreSynced() const
{
    return !m_lyricLines.isEmpty();
}

// --- Playing-queue track navigation ---

int PlaybackManager::playingTrackIndex() const
{
    Queue *q = m_session->playingQueue();
    return q ? q->currentTrackIndex() : -1;
}

int PlaybackManager::playingTrackCount() const
{
    Queue *q = m_session->playingQueue();
    return q ? q->trackCount() : 0;
}

bool PlaybackManager::hasPrevious() const
{
    Queue *q = m_session->playingQueue();
    return q ? q->hasPrevious() : false;
}

bool PlaybackManager::hasNext() const
{
    Queue *q = m_session->playingQueue();
    return q ? q->hasNext() : false;
}

// --- Play count ---

int PlaybackManager::playCountThreshold() const { return m_playCountThreshold; }

void PlaybackManager::setPlayCountThreshold(int percent)
{
    m_playCountThreshold = percent;
    resetPlayCountState();
    saveSettings();
}

// --- Playback wiring ---

void PlaybackManager::initPlayback(int queueIndex)
{
    Queue *q = m_session->queueAt(queueIndex);
    if (!q) return;
    q->setVolume(m_volume);
    q->initPlayback();
    connectPlaybackSignals(q);
}

void PlaybackManager::destroyPlayback(int queueIndex)
{
    Queue *q = m_session->queueAt(queueIndex);
    if (!q) return;
    q->saveState();
    q->destroyPlayback();
}

void PlaybackManager::restorePlaybackState(int queueIndex)
{
    Queue *q = m_session->queueAt(queueIndex);
    if (!q) return;
    q->restoreState();
}

// --- Private helpers ---

void PlaybackManager::resetPlayCountState()
{
    m_playCountCredited = false;
    m_creditThresholdMs = 0;

    Queue *q = m_session->playingQueue();
    if (q && q->currentTrackIndex() >= 0) {
        qint64 dur = q->trackAt(q->currentTrackIndex()).duration;
        m_creditThresholdMs = qint64(dur * (m_playCountThreshold / 100.0));
        qDebug() << "resetPlayCountState: dur=" << dur
                 << "threshold=" << m_playCountThreshold
                 << "creditThreshold=" << m_creditThresholdMs;
    }
}

void PlaybackManager::rebuildLyricLines()
{
    m_lyricLines.clear();
    Queue *q = m_session->playingQueue();
    if (!q) return;

    Track current = q->trackAt(q->currentTrackIndex());
    if (current.path.isEmpty()) return;

    Track fresh   = Metadata::read(current.path, false);
    m_rawLyrics   = fresh.lyrics;

    if (LrcParser::isLrc(fresh.lyrics))
        m_lyricLines = LrcParser::parse(fresh.lyrics);
}

void PlaybackManager::pushCoverArt()
{
    if (!m_coverImageProvider) return;

    Queue *q = m_session->playingQueue();
    if (!q || q->currentTrackIndex() < 0) {
        m_coverImageProvider->updateCover(QImage());
        emit coverArtChanged();
        return;
    }

    const QString path = q->trackAt(q->currentTrackIndex()).path;
    Track t = Metadata::read(path, true);
    m_coverImageProvider->updateCover(t.coverArt);
    emit coverArtChanged();
}

void PlaybackManager::connectPlaybackSignals(Queue *queue)
{
    Playback *pb = queue->playback();
    if (!pb) return;

    connect(pb, &Playback::readyToPlay, this, [this]() {
        rebuildLyricLines();
        emit metadataChanged();
        emit isFavoriteChanged();
        pushCoverArt();
    });

    connect(pb, &Playback::playbackStateChanged, this, [this]() {
        emit isPlayingChanged();
    });

    connect(pb, &Playback::durationChanged, this, [this]() {
        emit durationChanged();
        if (m_creditThresholdMs == 0 && !m_playCountCredited) {
            Queue *q = m_session->playingQueue();
            if (q && q->currentTrackIndex() >= 0) {
                qint64 dur = q->duration();
                qDebug() << "durationChanged recalc: dur=" << dur;
                if (dur > 0)
                    m_creditThresholdMs = qint64(dur * (m_playCountThreshold / 100.0));
            }
        }
    });

    connect(pb, &Playback::positionChanged, this, [this]() {
        emit positionChanged();

        if (!m_playCountCredited && m_creditThresholdMs > 1000) {
            Queue *q = m_session->playingQueue();
            if (q && q->position() >= m_creditThresholdMs) {
                qDebug() << "crediting play: position=" << q->position()
                << "threshold=" << m_creditThresholdMs;
                m_playCountCredited = true;
                QString path = q->trackAt(q->currentTrackIndex()).path;
                qint64 now   = QDateTime::currentSecsSinceEpoch();

                if (m_library) {
                    m_library->incrementPlayCount(path);
                    for (int i = 0; i < m_session->queueCount(); i++)
                        m_session->queueAt(i)->updateTrackStats(
                            path, now,
                            q->trackAt(q->currentTrackIndex()).playCount + 1);
                }
                emit metadataChanged();
            }
        } else if (!m_playCountCredited) {
            qDebug() << "position check skipped: credited=" << m_playCountCredited
                     << "threshold=" << m_creditThresholdMs
                     << "position=" << (m_session->playingQueue() ? m_session->playingQueue()->position() : -1);
        }
    });

    connect(queue, &Queue::trackChanged, this, [this]() {
        resetPlayCountState();
        rebuildLyricLines();
        emit playingTrackChanged();
        emit metadataChanged();
        emit isFavoriteChanged();
        pushCoverArt();
        emit positionChanged();
        emit durationChanged();
        qDebug() << "trackChanged fired. position() =" << (m_session->playingQueue() ? m_session->playingQueue()->position() : -1);
    });

    connect(queue, &Queue::restoreCompleted, this, [this]() {
        // Reset play count state AFTER the restore seek completes
        // so the seek itself doesn't trigger a false credit
        resetPlayCountState();
    });

    connect(queue, &Queue::repeatModeChanged, this, [this]() {
        emit repeatModeChanged();
    });

    connect(queue, &Queue::shuffleChanged, this, [this]() {
        emit shuffleChanged();
    });

    connect(queue, &Queue::stopAfterCurrentChanged, this, [this]() {
        emit stopAfterCurrentChanged();
    });
}

Playback *PlaybackManager::activePlayback() const
{
    Queue *q = m_session->playingQueue();
    return q ? q->playback() : nullptr;
}