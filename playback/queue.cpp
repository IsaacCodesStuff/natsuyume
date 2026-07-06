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
{}

void Queue::initPlayback()
{
    if (m_currentPlayback) return;
    m_currentPlayback = new Playback(this);
    connectCurrentPlaybackSignals();
    setVolume(m_volume);
}

void Queue::destroyPlayback()
{
    // Destroy preload first so it doesn't interfere
    if (m_preloadPlayback) {
        m_preloadPlayback->pause();
        delete m_preloadPlayback;
        m_preloadPlayback = nullptr;
        m_preloadTrackIndex = -1;
    }

    if (m_currentPlayback) {
        m_currentPlayback->pause();
        delete m_currentPlayback;
        m_currentPlayback = nullptr;
    }
}

Queue::~Queue() {}

// --- Internal helpers ---

void Queue::connectCurrentPlaybackSignals()
{
    connect(m_currentPlayback, &Playback::trackEnded, this, [this]() {
        // Stop after this song
        if (m_stopAfterCurrent) {
            m_stopAfterCurrent = false;
            emit stopAfterCurrentChanged();
            return;
        }

        // RepeatTrack — restart immediately, no gapless needed
        if (m_repeatMode == RepeatTrack) {
            m_currentPlayback->seekTo(0);
            m_currentPlayback->play();
            emit trackChanged();
            return;
        }

        // If preload is ready and points to a valid next track, trigger gapless swap
        if (m_preloadPlayback && m_preloadTrackIndex >= 0) {
            emit readyToSwap();
            return;
        }

        // No preload ready — fall back to direct load (non-gapless)
        // This handles edge cases: single track queue, preload not yet complete, etc.
        if (hasNext()) {
            if (m_shuffled) {
                int next = nextShuffleIndex();
                if (next >= 0) loadTrackAt(next);
            } else {
                loadTrackAt(m_currentTrackIndex + 1);
            }
            return;
        }

        if (m_repeatMode == RepeatQueue && !m_tracks.isEmpty()) {
            if (m_shuffled) {
                generateShuffleOrder();
                loadTrackAt(m_shuffleOrder.first());
            } else {
                loadTrackAt(0);
            }
            return;
        }

        // NoRepeat + no next = natural stop
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

// --- Gapless playback ---

Track Queue::peekNextTrack() const
{
    if (m_tracks.isEmpty()) return Track();

    // RepeatTrack — next is the same track
    if (m_repeatMode == RepeatTrack)
        return m_currentTrackIndex >= 0 ? m_tracks.at(m_currentTrackIndex) : Track();

    // Shuffle mode
    if (m_shuffled) {
        int next = nextShuffleIndex();
        if (next >= 0) return m_tracks.at(next);

        // Shuffle + RepeatQueue — would wrap to beginning of new shuffle order
        if (m_repeatMode == RepeatQueue && !m_shuffleOrder.isEmpty())
            return m_tracks.at(m_shuffleOrder.first());

        return Track(); // no next
    }

    // Normal sequential
    if (m_currentTrackIndex < m_tracks.size() - 1)
        return m_tracks.at(m_currentTrackIndex + 1);

    // RepeatQueue wrap
    if (m_repeatMode == RepeatQueue && !m_tracks.isEmpty())
        return m_tracks.at(0);

    return Track(); // no next
}

void Queue::preloadNextTrack()
{
    Track next = peekNextTrack();
    if (!next.isValid()) return;

    int nextIndex = -1;
    if (m_repeatMode == RepeatTrack) {
        nextIndex = m_currentTrackIndex;
    } else if (m_shuffled) {
        nextIndex = nextShuffleIndex();
        if (nextIndex < 0 && m_repeatMode == RepeatQueue && !m_shuffleOrder.isEmpty())
            nextIndex = m_shuffleOrder.first();
    } else {
        if (m_currentTrackIndex < m_tracks.size() - 1)
            nextIndex = m_currentTrackIndex + 1;
        else if (m_repeatMode == RepeatQueue)
            nextIndex = 0;
    }

    if (nextIndex < 0 || !m_preloadPlayback) return;

    m_preloadTrackIndex = nextIndex;
    m_preloadPlayback->loadTrack(m_tracks.at(nextIndex), false);

    // Prime the audio pipeline after load completes so play() during
    // gapless swap doesn't incur cold-start latency.
    // play() + immediate pause() warms the decoder without producing
    // audible output, leaving the pipeline in a hot paused state.
    connect(m_preloadPlayback, &Playback::readyToPlay, this, [this]() {
        if (m_preloadPlayback) {
            m_preloadPlayback->play();
            m_preloadPlayback->pause();
        }
    }, Qt::SingleShotConnection);
}

void Queue::swapPlayback()
{
    if (!m_preloadPlayback || m_preloadTrackIndex < 0) return;

    Playback *outgoing = m_currentPlayback;

    // Promote preload to current
    m_currentPlayback   = m_preloadPlayback;
    m_preloadPlayback   = nullptr;
    m_preloadTrackIndex = -1;

    // Restore real volume — it was playing silently at 0
    m_currentPlayback->setVolume(m_volume);

    connectCurrentPlaybackSignals();

    if (outgoing) {
        outgoing->pause();
        outgoing->deleteLater();
    }
}

void Queue::advancePlayback()
{
    // Called by PlaybackManager after swapPlayback()
    // Advances m_currentTrackIndex to match what was just swapped in
    // PlaybackManager knows the target index because it drove preloadNextTrack()
    // We recalculate it here from the current state to stay self-contained

    if (m_shuffled) {
        int next = nextShuffleIndex();
        if (next >= 0) {
            m_currentTrackIndex = next;
        } else if (m_repeatMode == RepeatQueue && !m_shuffleOrder.isEmpty()) {
            generateShuffleOrder();
            m_currentTrackIndex = m_shuffleOrder.first();
        }
    } else {
        if (m_currentTrackIndex < m_tracks.size() - 1) {
            m_currentTrackIndex++;
        } else if (m_repeatMode == RepeatQueue) {
            m_currentTrackIndex = 0;
        }
    }

    emit trackChanged();
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
        if (m_currentPlayback)
            m_currentPlayback->loadTrack(m_tracks.at(0), autoPlayFirst);
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
        if (m_currentPlayback) m_currentPlayback->pause();
    } else if (index == m_currentTrackIndex) {
        m_currentTrackIndex = qMin(index, m_tracks.size() - 1);
        m_currentPlayback->loadTrack(m_tracks.at(m_currentTrackIndex));
    } else if (index < m_currentTrackIndex) {
        m_currentTrackIndex--;
    }

    if (m_currentTrackIndex >= m_tracks.size())
        m_currentTrackIndex = m_tracks.size() - 1;

    // Invalidate preload since track list changed
    if (m_preloadPlayback) {
        delete m_preloadPlayback;
        m_preloadPlayback   = nullptr;
        m_preloadTrackIndex = -1;
    }

    emit queueChanged();
    emit trackChanged();
}

void Queue::clearTracks()
{
    if (m_currentPlayback) m_currentPlayback->pause();
    m_tracks.clear();
    m_shuffleOrder.clear();
    m_currentTrackIndex = -1;

    if (m_preloadPlayback) {
        delete m_preloadPlayback;
        m_preloadPlayback   = nullptr;
        m_preloadTrackIndex = -1;
    }

    emit queueChanged();
}

int Queue::trackCount() const { return m_tracks.size(); }
Track Queue::trackAt(int index) const { return m_tracks.at(index); }
QList<Track> Queue::tracks() const { return m_tracks; }

// --- Playback control ---

void Queue::play()  { if (m_currentPlayback) m_currentPlayback->play(); }
void Queue::pause() { if (m_currentPlayback) m_currentPlayback->pause(); }

void Queue::seekTo(qint64 positionMs)
{
    if (m_currentPlayback) m_currentPlayback->seekTo(positionMs);
}

void Queue::loadTrackAt(int index, bool autoPlay)
{
    if (index < 0 || index >= m_tracks.size()) return;
    m_currentTrackIndex = index;

    // Discard preload — manual track selection always does a fresh load
    if (m_preloadPlayback) {
        delete m_preloadPlayback;
        m_preloadPlayback   = nullptr;
        m_preloadTrackIndex = -1;
    }

    if (m_currentPlayback)
        m_currentPlayback->loadTrack(m_tracks.at(index), autoPlay);

    emit trackChanged();
}

void Queue::playNext()
{
    // Manual skip — always fresh load, no gapless
    // Discard any existing preload first
    if (m_preloadPlayback) {
        delete m_preloadPlayback;
        m_preloadPlayback   = nullptr;
        m_preloadTrackIndex = -1;
    }

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
    // Discard preload on any manual navigation
    if (m_preloadPlayback) {
        delete m_preloadPlayback;
        m_preloadPlayback   = nullptr;
        m_preloadTrackIndex = -1;
    }

    if (m_currentPlayback && m_currentPlayback->position() > 3000) {
        m_currentPlayback->seekTo(0);
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
    if (!m_currentPlayback) return;
    m_savedPosition = m_currentPlayback->position();
    m_wasPlaying    = m_currentPlayback->isPlaying();
    m_currentPlayback->pause();
}

void Queue::restoreState()
{
    if (!m_currentPlayback) return;
    if (m_currentTrackIndex < 0 || m_currentTrackIndex >= m_tracks.size()) return;

    connect(m_currentPlayback, &Playback::readyToPlay, this, [this]() {
        QTimer::singleShot(200, this, [this]() {
            m_currentPlayback->seekTo(m_savedPosition);
            if (m_wasPlaying)
                m_currentPlayback->play();
            else
                m_currentPlayback->pause();
            emit trackChanged();
            emit restoreCompleted();
        });
    }, Qt::SingleShotConnection);

    m_currentPlayback->loadTrack(m_tracks.at(m_currentTrackIndex));
}

// --- Getters ---

QString Queue::name() const { return m_name; }
void    Queue::setName(const QString &name) { m_name = name; }

int Queue::currentTrackIndex() const { return m_currentTrackIndex; }

bool Queue::hasNext() const
{
    if (m_shuffled) return nextShuffleIndex() >= 0;
    return m_currentTrackIndex < m_tracks.size() - 1;
}

bool Queue::hasPrevious() const
{
    if (m_shuffled) return previousShuffleIndex() >= 0;
    return m_currentTrackIndex > 0;
}

bool   Queue::isPlaying() const { return m_currentPlayback ? m_currentPlayback->isPlaying() : false; }
qint64 Queue::position()  const { return m_currentPlayback ? m_currentPlayback->position()  : 0; }
qint64 Queue::duration()  const { return m_currentPlayback ? m_currentPlayback->duration()  : 0; }

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

    // Discard preload since shuffle order changed
    if (m_preloadPlayback) {
        delete m_preloadPlayback;
        m_preloadPlayback   = nullptr;
        m_preloadTrackIndex = -1;
    }

    emit shuffleChanged();
}

// --- Audio ---

void Queue::setVolume(float volume)
{
    m_volume = volume;
    if (m_currentPlayback) m_currentPlayback->setVolume(volume);
    if (m_preloadPlayback)  m_preloadPlayback->setVolume(volume);
}

Playback *Queue::currentPlayback()  const { return m_currentPlayback; }
Playback *Queue::preloadPlayback()  const { return m_preloadPlayback; }
bool      Queue::hasPlayback()      const { return m_currentPlayback != nullptr; }

void Queue::moveTrack(int from, int to)
{
    if (from < 0 || from >= m_tracks.size()) return;
    if (to   < 0 || to   >= m_tracks.size()) return;
    if (from == to) return;

    m_tracks.move(from, to);

    if (m_shuffled) generateShuffleOrder();

    if (m_currentTrackIndex == from) {
        m_currentTrackIndex = to;
    } else if (from < to) {
        if (m_currentTrackIndex > from && m_currentTrackIndex <= to)
            m_currentTrackIndex--;
    } else {
        if (m_currentTrackIndex >= to && m_currentTrackIndex < from)
            m_currentTrackIndex++;
    }

    // Discard preload — track order changed
    if (m_preloadPlayback) {
        delete m_preloadPlayback;
        m_preloadPlayback   = nullptr;
        m_preloadTrackIndex = -1;
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
    if (m_shuffled) generateShuffleOrder();
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

    if (!currentPath.isEmpty()) {
        for (int i = 0; i < m_tracks.size(); ++i) {
            if (m_tracks.at(i).path == currentPath) {
                m_currentTrackIndex = i;
                break;
            }
        }
    }

    if (m_shuffled) generateShuffleOrder();

    // Discard preload — track order changed
    if (m_preloadPlayback) {
        delete m_preloadPlayback;
        m_preloadPlayback   = nullptr;
        m_preloadTrackIndex = -1;
    }

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

    if (m_shuffled) generateShuffleOrder();

    // Discard preload — track order changed
    if (m_preloadPlayback) {
        delete m_preloadPlayback;
        m_preloadPlayback   = nullptr;
        m_preloadTrackIndex = -1;
    }

    emit queueChanged();
}

void Queue::addTracksBatch(const QStringList &filePaths, bool autoPlayFirst)
{
    for (const QString &path : filePaths) {
        Track track = Metadata::read(path, false);
        m_tracks.append(track);
    }

    if (m_tracks.isEmpty()) return;

    if (m_shuffled) generateShuffleOrder();

    if (m_currentTrackIndex < 0) {
        int startIndex = (m_shuffled && !m_shuffleOrder.isEmpty())
        ? m_shuffleOrder.first() : 0;
        m_currentTrackIndex = startIndex;
        if (m_currentPlayback)
            m_currentPlayback->loadTrack(m_tracks.at(startIndex), autoPlayFirst);
    }

    emit queueChanged();
}

void Queue::setSavedPosition(qint64 position)  { m_savedPosition = position; }
void Queue::setWasPlaying(bool wasPlaying)      { m_wasPlaying = wasPlaying; }
void Queue::setCurrentTrackIndex(int index)     { m_currentTrackIndex = index; }