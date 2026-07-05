#include "queue.h"
#include <QRandomGenerator>
#include <QDateTime>
#include <QTimer>
#include <algorithm>

Queue::Queue(const QString &name, QObject *parent)
    : QObject{parent},
    m_name(name),
    m_currentTrackIndex(-1),
    m_savedPosition(0),
    m_wasPlaying(false),
    m_repeatMode(NoRepeat),
    m_shuffled(false)
// no m_playback creation here
{}

void Queue::initPlayback()
{
    if (m_playback) return;
    m_playback = new Playback(this);
    connectPlaybackSignals();
    setVolume(m_volume); // apply stored volume
}

void Queue::destroyPlayback()
{
    if (!m_playback) return;
    m_playback->pause();
    delete m_playback;
    m_playback = nullptr;
}

Queue::~Queue() {}

// --- Internal helpers ---

void Queue::connectPlaybackSignals()
{
    connect(m_playback, &Playback::trackEnded, this, [this]() {
        // Stop after this song
        if (m_stopAfterCurrent) {
            m_stopAfterCurrent = false;
            emit stopAfterCurrentChanged();
            return;  // don't advance
        }

        // RepeatTrack — restart immediately
        if (m_repeatMode == RepeatTrack) {
            m_playback->seekTo(0);
            m_playback->play();
            emit trackChanged(); // ← triggers resetPlayCountState in PlaybackManager
            return;
        }

        // Has a literal next track
        if (hasNext()) {
            if (m_shuffled) {
                int next = nextShuffleIndex();
                if (next >= 0)
                    loadTrackAt(next);
            } else {
                loadTrackAt(m_currentTrackIndex + 1);
            }
            return;
        }

        // No next track, but RepeatQueue — wrap around
        if (m_repeatMode == RepeatQueue && !m_tracks.isEmpty()) {
            if (m_shuffled) {
                generateShuffleOrder();
                loadTrackAt(m_shuffleOrder.first());
            } else {
                loadTrackAt(0);
            }
            return;
        }

        // NoRepeat + no next = natural stop, do nothing
    });
}

void Queue::generateShuffleOrder()
{
    m_shuffleOrder.clear();
    for (int i = 0; i < m_tracks.size(); i++)
        m_shuffleOrder.append(i);

    for (int i = m_shuffleOrder.size() - 1; i > 0; i--) {
        int j = QRandomGenerator::global()->bounded(i + 1);
        m_shuffleOrder.swapItemsAt(i, j);
    }

    // Keep current track at front so playback continues uninterrupted
    int pos = m_shuffleOrder.indexOf(m_currentTrackIndex);
    if (pos > 0)
        m_shuffleOrder.move(pos, 0);
}

int Queue::nextShuffleIndex() const
{
    if (m_shuffleOrder.isEmpty()) return -1;
    int pos = m_shuffleOrder.indexOf(m_currentTrackIndex);
    if (pos < 0 || pos >= m_shuffleOrder.size() - 1) return -1;
    return m_shuffleOrder.at(pos + 1);
}

int Queue::previousShuffleIndex() const
{
    if (m_shuffleOrder.isEmpty()) return -1;
    int pos = m_shuffleOrder.indexOf(m_currentTrackIndex);
    if (pos <= 0) return -1;
    return m_shuffleOrder.at(pos - 1);
}

// --- Track management ---

void Queue::addTrack(const QString &filePath, bool autoPlayFirst)
{
    Track track = Metadata::read(filePath, false);
    m_tracks.append(track);

    if (m_shuffled)
        generateShuffleOrder();

    if (m_currentTrackIndex < 0) {
        m_currentTrackIndex = 0;
        if (m_playback)
            m_playback->loadTrack(m_tracks.at(0), autoPlayFirst);
    }

    emit queueChanged();
}

void Queue::removeTrack(int index)
{
    if (index < 0 || index >= m_tracks.size())
        return;

    m_tracks.removeAt(index);

    if (m_shuffled)
        generateShuffleOrder();

    if (m_tracks.isEmpty()) {
        m_currentTrackIndex = -1;
        if (m_playback) m_playback->pause();
    } else if (index == m_currentTrackIndex) {
        // Was playing this track — play the next one, or the previous if it was the last
        m_currentTrackIndex = qMin(index, m_tracks.size() - 1);
        m_playback->loadTrack(m_tracks.at(m_currentTrackIndex));
    } else if (index < m_currentTrackIndex) {
        // Removed a track before current — adjust index
        m_currentTrackIndex--;
    }

    if (m_currentTrackIndex >= m_tracks.size())
        m_currentTrackIndex = m_tracks.size() - 1;

    emit queueChanged();
    emit trackChanged();
}

void Queue::clearTracks()
{
    if (m_playback) m_playback->pause();
    m_tracks.clear();
    m_shuffleOrder.clear();
    m_currentTrackIndex = -1;
    emit queueChanged();
}

int Queue::trackCount() const { return m_tracks.size(); }
Track Queue::trackAt(int index) const { return m_tracks.at(index); }
QList<Track> Queue::tracks() const { return m_tracks; }

// --- Playback control ---

void Queue::play()  { if (m_playback) m_playback->play(); }
void Queue::pause() { if (m_playback) m_playback->pause(); }

void Queue::seekTo(qint64 positionMs)
{
    if (m_playback) m_playback->seekTo(positionMs);
}

void Queue::loadTrackAt(int index, bool autoPlay)
{
    if (index < 0 || index >= m_tracks.size())
        return;
    m_currentTrackIndex = index;
    if (m_playback)
        m_playback->loadTrack(m_tracks.at(index), autoPlay);
    emit trackChanged();
}

void Queue::playNext()
{
    if (m_shuffled) {
        int next = nextShuffleIndex();
        if (next >= 0) {
            loadTrackAt(next);
        } else if (m_repeatMode == RepeatQueue) {
            generateShuffleOrder();
            loadTrackAt(m_shuffleOrder.first());
        }
        return;
    }

    if (hasNext()) {
        loadTrackAt(m_currentTrackIndex + 1);
    } else if (m_repeatMode == RepeatQueue) {
        loadTrackAt(0);
    }
}

void Queue::playPrevious()
{
    // 3 second rule — restart current track if more than 3s in
    if (m_playback && m_playback->position() > 3000) {
        m_playback->seekTo(0);
        return;
    }

    if (m_shuffled) {
        int prev = previousShuffleIndex();
        if (prev >= 0) {
            loadTrackAt(prev);
        } else if (m_repeatMode == RepeatQueue) {
            loadTrackAt(m_shuffleOrder.last());
        }
        return;
    }

    if (hasPrevious()) {
        loadTrackAt(m_currentTrackIndex - 1);
    } else if (m_repeatMode == RepeatQueue) {
        loadTrackAt(m_tracks.size() - 1);
    }
}

// --- State save / restore ---

void Queue::saveState()
{
    if (!m_playback) return;
    m_savedPosition = m_playback->position();
    m_wasPlaying = m_playback->isPlaying();
    m_playback->pause();
}

void Queue::restoreState()
{
    if (!m_playback) return;
    if (m_currentTrackIndex < 0 || m_currentTrackIndex >= m_tracks.size())
        return;

    connect(m_playback, &Playback::readyToPlay, this, [this]() {
        QTimer::singleShot(200, this, [this]() {
            m_playback->seekTo(m_savedPosition);
            if (m_wasPlaying)
                m_playback->play();
            else
                m_playback->pause();
            emit trackChanged();
            emit restoreCompleted(); // ← add this
        });
    }, Qt::SingleShotConnection);

    m_playback->loadTrack(m_tracks.at(m_currentTrackIndex));
}

// --- Getters ---

QString Queue::name() const { return m_name; }
void Queue::setName(const QString &name) { m_name = name; }

int Queue::currentTrackIndex() const { return m_currentTrackIndex; }

bool Queue::hasNext() const
{
    if (m_shuffled)
        return nextShuffleIndex() >= 0;
    return m_currentTrackIndex < m_tracks.size() - 1;
}

bool Queue::hasPrevious() const
{
    if (m_shuffled)
        return previousShuffleIndex() >= 0;
    return m_currentTrackIndex > 0;
}

bool Queue::isPlaying() const { return m_playback ? m_playback->isPlaying() : false; }
qint64 Queue::position() const { return m_playback ? m_playback->position() : 0; }
qint64 Queue::duration() const { return m_playback ? m_playback->duration() : 0; }

// --- Repeat ---

Queue::RepeatMode Queue::repeatMode() const { return m_repeatMode; }

void Queue::cycleRepeatMode()
{
    switch (m_repeatMode) {
    case NoRepeat:    m_repeatMode = RepeatQueue; break;
    case RepeatQueue: m_repeatMode = RepeatTrack; break;
    case RepeatTrack: m_repeatMode = NoRepeat;    break;
    }
    emit repeatModeChanged();
}

// --- Shuffle ---

bool Queue::isShuffled() const { return m_shuffled; }

void Queue::toggleShuffle()
{
    m_shuffled = !m_shuffled;
    if (m_shuffled)
        generateShuffleOrder();
    else
        m_shuffleOrder.clear();
    emit shuffleChanged();
}

// --- Audio ---

void Queue::setVolume(float volume)
{
    m_volume = volume;
    if (m_playback) m_playback->setVolume(volume);
}

Playback *Queue::playback() const { return m_playback; }

void Queue::moveTrack(int from, int to)
{
    if (from < 0 || from >= m_tracks.size()) return;
    if (to < 0   || to   >= m_tracks.size()) return;
    if (from == to) return;

    m_tracks.move(from, to);

    if (m_shuffled)
        generateShuffleOrder();

    // Keep current track index tracking the same track
    if (m_currentTrackIndex == from) {
        m_currentTrackIndex = to;
    } else if (from < to) {
        if (m_currentTrackIndex > from && m_currentTrackIndex <= to)
            m_currentTrackIndex--;
    } else {
        if (m_currentTrackIndex >= to && m_currentTrackIndex < from)
            m_currentTrackIndex++;
    }

    emit queueChanged();
    emit trackChanged();
}

void Queue::updateTrackStats(const QString &path, qint64 lastPlayed, int playCount)
{
    for (Track &t : m_tracks) {
        if (t.path == path) {
            t.dateLastPlayed = lastPlayed;
            t.playCount      = playCount;
            break;
        }
    }
}

void Queue::addTrackSilent(const Track &track)
{
    m_tracks.append(track);
    if (m_shuffled)
        generateShuffleOrder();
    // deliberately no auto-load, no emit
}

bool Queue::stopAfterCurrent() const { return m_stopAfterCurrent; }

void Queue::setStopAfterCurrent(bool stop)
{
    m_stopAfterCurrent = stop;
    emit stopAfterCurrentChanged();
}

void Queue::sortTracks(Library::TrackSort sort, bool ascending)
{
    if (m_tracks.isEmpty()) return;

    QString currentPath = (m_currentTrackIndex >= 0 && m_currentTrackIndex < m_tracks.size())
                              ? m_tracks.at(m_currentTrackIndex).path
                              : QString();

    auto cmp = [sort, ascending](const Track &a, const Track &b) -> bool {
        bool result = false;
        switch (sort) {
        case Library::TrackSort::Title:
            result = a.title.localeAwareCompare(b.title) < 0; break;
        case Library::TrackSort::Artist:
            result = a.artist.localeAwareCompare(b.artist) < 0; break;
        case Library::TrackSort::AlbumArtist:
            result = a.albumArtist.localeAwareCompare(b.albumArtist) < 0; break;
        case Library::TrackSort::Year:
            result = a.year < b.year; break;
        case Library::TrackSort::Duration:
            result = a.duration < b.duration; break;
        case Library::TrackSort::Genre:
            result = a.genre.localeAwareCompare(b.genre) < 0; break;
        case Library::TrackSort::Composer:
            result = a.composer.localeAwareCompare(b.composer) < 0; break;
        case Library::TrackSort::Filename:
            result = a.path.localeAwareCompare(b.path) < 0; break;
        case Library::TrackSort::DateAdded:
            result = a.dateAdded < b.dateAdded; break;
        case Library::TrackSort::DateLastPlayed:
            result = a.dateLastPlayed < b.dateLastPlayed; break;
        case Library::TrackSort::PlayCount:
            result = a.playCount < b.playCount; break;
        case Library::TrackSort::TrackNumber:
        default:
            if (a.discNumber != b.discNumber)
                result = a.discNumber < b.discNumber;
            else
                result = a.trackNumber < b.trackNumber;
            break;
        }
        return ascending ? result : !result;
    };

    std::sort(m_tracks.begin(), m_tracks.end(), cmp);

    // Re-find current track's new index so playback isn't disrupted
    if (!currentPath.isEmpty()) {
        for (int i = 0; i < m_tracks.size(); ++i) {
            if (m_tracks.at(i).path == currentPath) {
                m_currentTrackIndex = i;
                break;
            }
        }
    }

    if (m_shuffled)
        generateShuffleOrder();

    emit queueChanged();
}

void Queue::reverseTracks()
{
    if (m_tracks.isEmpty()) return;

    QString currentPath = (m_currentTrackIndex >= 0 && m_currentTrackIndex < m_tracks.size())
                              ? m_tracks.at(m_currentTrackIndex).path
                              : QString();

    std::reverse(m_tracks.begin(), m_tracks.end());

    if (!currentPath.isEmpty()) {
        for (int i = 0; i < m_tracks.size(); ++i) {
            if (m_tracks.at(i).path == currentPath) {
                m_currentTrackIndex = i;
                break;
            }
        }
    }

    if (m_shuffled)
        generateShuffleOrder();

    emit queueChanged();
}

void Queue::addTracksBatch(const QStringList &filePaths, bool autoPlayFirst)
{
    for (const QString &path : filePaths) {
        Track track = Metadata::read(path, false);
        m_tracks.append(track);
    }

    if (m_tracks.isEmpty()) return;

    if (m_shuffled)
        generateShuffleOrder();

    if (m_currentTrackIndex < 0) {
        int startIndex = (m_shuffled && !m_shuffleOrder.isEmpty())
        ? m_shuffleOrder.first()
        : 0;
        m_currentTrackIndex = startIndex;
        if (m_playback)
            m_playback->loadTrack(m_tracks.at(startIndex), autoPlayFirst);
    }

    emit queueChanged();
}

void Queue::setSavedPosition(qint64 position)
{
    m_savedPosition = position;
}

void Queue::setWasPlaying(bool wasPlaying)
{
    m_wasPlaying = wasPlaying;
}

void Queue::setCurrentTrackIndex(int index)
{
    m_currentTrackIndex = index;
}