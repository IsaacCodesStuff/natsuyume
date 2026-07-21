#include "queue.h"
#include <algorithm>
#include <random>
#include <chrono>
#include <cstring>


// ---------------------------------------------------------------------------
// ICU locale-aware string comparison
// ---------------------------------------------------------------------------
static int localeCompare(const std::string &a, const std::string &b)
{
    return strcoll(a.c_str(), b.c_str());
}

// ---------------------------------------------------------------------------
// Lifecycle
// ---------------------------------------------------------------------------

Queue::Queue(const std::string &name)
    : m_name(name)
{}

Queue::~Queue() {}

void Queue::initPlayback()
{
    if (m_currentPlayback) return;
    m_currentPlayback = new Playback();
    m_currentPlayback->setVolume(m_volume);
    connectPlaybackCallbacks();
}

void Queue::destroyPlayback()
{
    if (m_currentPlayback) {
        m_currentPlayback->pause();
        delete m_currentPlayback;
        m_currentPlayback = nullptr;
    }
}

// ---------------------------------------------------------------------------
// Playback callbacks
// ---------------------------------------------------------------------------

void Queue::connectPlaybackCallbacks()
{
    m_currentPlayback->onTrackAdvancedGapless = [this]() {
        advancePlayback();
    };

    m_currentPlayback->onTrackEnded = [this]() {
        if (m_stopAfterCurrent) {
            m_stopAfterCurrent = false;
            if (onStopAfterCurrentChanged) onStopAfterCurrentChanged();
            return;
        }

        if (m_repeatMode == RepeatTrack) {
            m_currentPlayback->loadTrack(m_tracks.at(m_currentTrackIndex), true);
            if (onTrackChanged) onTrackChanged();
            return;
        }

        if (hasNext()) {
            if (m_shuffled) {
                int next = nextShuffleIndex();
                if (next >= 0) loadTrackAt(next);
            } else {
                loadTrackAt(m_currentTrackIndex + 1);
            }
            return;
        }

        if (m_repeatMode == RepeatQueue && !m_tracks.empty()) {
            if (m_shuffled) {
                generateShuffleOrder();
                loadTrackAt(m_shuffleOrder.front());
            } else {
                loadTrackAt(0);
            }
            return;
        }
        // NoRepeat + no next = natural stop
    };
}

// ---------------------------------------------------------------------------
// Shuffle
// ---------------------------------------------------------------------------

void Queue::generateShuffleOrder()
{
    m_shuffleOrder.clear();
    for (int i = 0; i < (int)m_tracks.size(); ++i)
        m_shuffleOrder.push_back(i);

    auto seed = std::chrono::steady_clock::now().time_since_epoch().count();
    std::mt19937 rng(static_cast<unsigned>(seed));

    for (int i = (int)m_shuffleOrder.size() - 1; i > 0; --i) {
        std::uniform_int_distribution<int> dist(0, i);
        int j = dist(rng);
        std::swap(m_shuffleOrder[i], m_shuffleOrder[j]);
    }

    // Move current track to front of shuffle order
    auto it = std::find(m_shuffleOrder.begin(), m_shuffleOrder.end(),
                        m_currentTrackIndex);
    if (it != m_shuffleOrder.end() && it != m_shuffleOrder.begin())
        std::rotate(m_shuffleOrder.begin(), it, it + 1);
}

int Queue::nextShuffleIndex() const
{
    if (m_shuffleOrder.empty()) return -1;
    auto it = std::find(m_shuffleOrder.begin(), m_shuffleOrder.end(),
                        m_currentTrackIndex);
    if (it == m_shuffleOrder.end()) return -1;
    ++it;
    return (it == m_shuffleOrder.end()) ? -1 : *it;
}

int Queue::previousShuffleIndex() const
{
    if (m_shuffleOrder.empty()) return -1;
    auto it = std::find(m_shuffleOrder.begin(), m_shuffleOrder.end(),
                        m_currentTrackIndex);
    if (it == m_shuffleOrder.end() || it == m_shuffleOrder.begin()) return -1;
    return *std::prev(it);
}

// ---------------------------------------------------------------------------
// Gapless
// ---------------------------------------------------------------------------

Track Queue::peekNextTrack() const
{
    if (m_tracks.empty()) return Track();

    if (m_repeatMode == RepeatTrack)
        return m_currentTrackIndex >= 0
                   ? m_tracks.at(m_currentTrackIndex) : Track();

    if (m_shuffled) {
        int next = nextShuffleIndex();
        if (next >= 0) return m_tracks.at(next);
        if (m_repeatMode == RepeatQueue && !m_shuffleOrder.empty())
            return m_tracks.at(m_shuffleOrder.front());
        return Track();
    }

    if (m_currentTrackIndex < (int)m_tracks.size() - 1)
        return m_tracks.at(m_currentTrackIndex + 1);

    if (m_repeatMode == RepeatQueue && !m_tracks.empty())
        return m_tracks.at(0);

    return Track();
}

void Queue::advancePlayback()
{
    if (m_shuffled) {
        int next = nextShuffleIndex();
        if (next >= 0) {
            m_currentTrackIndex = next;
        } else if (m_repeatMode == RepeatQueue && !m_shuffleOrder.empty()) {
            generateShuffleOrder();
            m_currentTrackIndex = m_shuffleOrder.front();
        }
    } else {
        if (m_currentTrackIndex < (int)m_tracks.size() - 1) {
            m_currentTrackIndex++;
        } else if (m_repeatMode == RepeatQueue) {
            m_currentTrackIndex = 0;
        }
    }

    if (onTrackChanged) onTrackChanged();
}

// ---------------------------------------------------------------------------
// Track management
// ---------------------------------------------------------------------------

void Queue::addTrack(const std::string &filePath, bool autoPlayFirst)
{
    Track track = Metadata::read(filePath, false);
    m_tracks.push_back(track);

    if (m_shuffled) generateShuffleOrder();

    if (m_currentTrackIndex < 0) {
        m_currentTrackIndex = 0;
        if (m_currentPlayback)
            m_currentPlayback->loadTrack(m_tracks.at(0), autoPlayFirst);
    }

    if (onQueueChanged) onQueueChanged();
}

void Queue::addTracksBatch(const std::vector<std::string> &filePaths,
                           bool autoPlayFirst)
{
    for (const auto &path : filePaths) {
        Track track = Metadata::read(path, false);
        m_tracks.push_back(track);
    }

    if (m_tracks.empty()) return;
    if (m_shuffled) generateShuffleOrder();

    if (m_currentTrackIndex < 0) {
        int startIndex = (m_shuffled && !m_shuffleOrder.empty())
                             ? m_shuffleOrder.front() : 0;
        m_currentTrackIndex = startIndex;
        if (m_currentPlayback)
            m_currentPlayback->loadTrack(m_tracks.at(startIndex), autoPlayFirst);
    }

    if (onQueueChanged) onQueueChanged();
}

void Queue::addTrackSilent(const Track &track)
{
    m_tracks.push_back(track);
    if (m_shuffled) generateShuffleOrder();
}

void Queue::removeTrack(int index)
{
    if (index < 0 || index >= (int)m_tracks.size()) return;

    m_tracks.erase(m_tracks.begin() + index);
    if (m_shuffled) generateShuffleOrder();

    if (m_tracks.empty()) {
        m_currentTrackIndex = -1;
        if (m_currentPlayback) m_currentPlayback->pause();
    } else if (index == m_currentTrackIndex) {
        m_currentTrackIndex = std::min(index, (int)m_tracks.size() - 1);
        if (m_currentPlayback)
            m_currentPlayback->loadTrack(m_tracks.at(m_currentTrackIndex));
    } else if (index < m_currentTrackIndex) {
        m_currentTrackIndex--;
    }

    if (m_currentTrackIndex >= (int)m_tracks.size())
        m_currentTrackIndex = (int)m_tracks.size() - 1;

    if (onQueueChanged)  onQueueChanged();
    if (onTrackChanged)  onTrackChanged();
}

void Queue::clearTracks()
{
    if (m_currentPlayback) m_currentPlayback->pause();
    m_tracks.clear();
    m_shuffleOrder.clear();
    m_currentTrackIndex = -1;
    if (onQueueChanged) onQueueChanged();
}

int              Queue::trackCount() const { return (int)m_tracks.size(); }
Track            Queue::trackAt(int index) const { return m_tracks.at(index); }
std::vector<Track> Queue::tracks()   const { return m_tracks; }

// ---------------------------------------------------------------------------
// Playback control
// ---------------------------------------------------------------------------

void Queue::play()  { if (m_currentPlayback) m_currentPlayback->play(); }
void Queue::pause() { if (m_currentPlayback) m_currentPlayback->pause(); }

void Queue::seekTo(int64_t positionMs)
{
    if (m_currentPlayback) m_currentPlayback->seekTo(positionMs);
}

void Queue::loadTrackAt(int index, bool autoPlay)
{
    if (index < 0 || index >= (int)m_tracks.size()) return;
    m_currentTrackIndex = index;
    if (m_currentPlayback)
        m_currentPlayback->loadTrack(m_tracks.at(index), autoPlay);
    if (onTrackChanged) onTrackChanged();
}

void Queue::playNext()
{
    if (m_shuffled) {
        int next = nextShuffleIndex();
        if (next >= 0) {
            loadTrackAt(next);
        } else if (m_repeatMode == RepeatQueue) {
            generateShuffleOrder();
            loadTrackAt(m_shuffleOrder.front());
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
    if (m_currentPlayback && m_currentPlayback->position() > 3000) {
        m_currentPlayback->seekTo(0);
        return;
    }

    if (m_shuffled) {
        int prev = previousShuffleIndex();
        if (prev >= 0) {
            loadTrackAt(prev);
        } else if (m_repeatMode == RepeatQueue && !m_shuffleOrder.empty()) {
            loadTrackAt(m_shuffleOrder.back());
        }
        return;
    }

    if (hasPrevious()) {
        loadTrackAt(m_currentTrackIndex - 1);
    } else if (m_repeatMode == RepeatQueue) {
        loadTrackAt((int)m_tracks.size() - 1);
    }
}

// ---------------------------------------------------------------------------
// State save / restore
// ---------------------------------------------------------------------------

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
    if (m_currentTrackIndex < 0 ||
        m_currentTrackIndex >= (int)m_tracks.size()) return;

    int64_t savedPos = m_savedPosition;

    // One-shot: fire once on readyToPlay then restore original callback
    auto prevCallback = m_currentPlayback->onReadyToPlay;
    m_currentPlayback->onReadyToPlay = [this, savedPos, prevCallback]() {
        m_currentPlayback->seekTo(savedPos);
        m_currentPlayback->pause();
        m_currentPlayback->onReadyToPlay = prevCallback;
        if (onTrackChanged)    onTrackChanged();
        if (onRestoreCompleted) onRestoreCompleted();
    };

    m_currentPlayback->loadTrack(m_tracks.at(m_currentTrackIndex), false);
}

// ---------------------------------------------------------------------------
// Getters
// ---------------------------------------------------------------------------

std::string Queue::name() const { return m_name; }
void        Queue::setName(const std::string &name) { m_name = name; }
int         Queue::currentTrackIndex() const { return m_currentTrackIndex; }

bool Queue::hasNext() const
{
    if (m_shuffled) return nextShuffleIndex() >= 0;
    return m_currentTrackIndex < (int)m_tracks.size() - 1;
}

bool Queue::hasPrevious() const
{
    if (m_shuffled) return previousShuffleIndex() >= 0;
    return m_currentTrackIndex > 0;
}

bool    Queue::isPlaying() const { return m_currentPlayback ? m_currentPlayback->isPlaying() : false; }
int64_t Queue::position()  const { return m_currentPlayback ? m_currentPlayback->position()  : 0; }
int64_t Queue::duration()  const { return m_currentPlayback ? m_currentPlayback->duration()  : 0; }

// ---------------------------------------------------------------------------
// Repeat
// ---------------------------------------------------------------------------

Queue::RepeatMode Queue::repeatMode() const { return m_repeatMode; }

void Queue::cycleRepeatMode()
{
    switch (m_repeatMode) {
    case NoRepeat:    m_repeatMode = RepeatQueue; break;
    case RepeatQueue: m_repeatMode = RepeatTrack; break;
    case RepeatTrack: m_repeatMode = NoRepeat;    break;
    }

    if (m_repeatMode == RepeatTrack && m_currentPlayback) {
        m_currentPlayback->clearAppendedTrack();
        m_currentPlayback->setRepeatTrackPending(true);
    }

    if (onRepeatModeChanged) onRepeatModeChanged();
}

// ---------------------------------------------------------------------------
// Shuffle
// ---------------------------------------------------------------------------

bool Queue::isShuffled() const { return m_shuffled; }

void Queue::toggleShuffle()
{
    m_shuffled = !m_shuffled;
    if (m_shuffled)
        generateShuffleOrder();
    else
        m_shuffleOrder.clear();

    if (onShuffleChanged) onShuffleChanged();
}

// ---------------------------------------------------------------------------
// Audio
// ---------------------------------------------------------------------------

void Queue::setVolume(float volume)
{
    m_volume = volume;
    if (m_currentPlayback) m_currentPlayback->setVolume(volume);
}

Playback *Queue::currentPlayback() const { return m_currentPlayback; }
bool      Queue::hasPlayback()     const { return m_currentPlayback != nullptr; }

// ---------------------------------------------------------------------------
// Track ops
// ---------------------------------------------------------------------------

void Queue::moveTrack(int from, int to)
{
    if (from < 0 || from >= (int)m_tracks.size()) return;
    if (to   < 0 || to   >= (int)m_tracks.size()) return;
    if (from == to) return;

    Track t = std::move(m_tracks[from]);
    m_tracks.erase(m_tracks.begin() + from);
    m_tracks.insert(m_tracks.begin() + to, std::move(t));

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

    if (onQueueChanged) onQueueChanged();
    if (onTrackChanged) onTrackChanged();
}

void Queue::updateTrackStats(const std::string &path,
                             int64_t lastPlayed, int playCount)
{
    for (Track &t : m_tracks) {
        if (t.path == path) {
            t.dateLastPlayed = lastPlayed;
            t.playCount      = playCount;
            break;
        }
    }
}

void Queue::sortTracks(Library::TrackSort sort, bool ascending)
{
    if (m_tracks.empty()) return;

    std::string currentPath =
        (m_currentTrackIndex >= 0 &&
         m_currentTrackIndex < (int)m_tracks.size())
            ? m_tracks.at(m_currentTrackIndex).path : "";

    auto cmp = [&](const Track &a, const Track &b) -> bool {
        bool result = false;
        switch (sort) {
        case Library::TrackSort::Title:
            result = localeCompare(a.title, b.title) < 0; break;
        case Library::TrackSort::Artist:
            result = localeCompare(a.artist, b.artist) < 0; break;
        case Library::TrackSort::AlbumArtist:
            result = localeCompare(a.albumArtist, b.albumArtist) < 0; break;
        case Library::TrackSort::Year:
            result = a.year < b.year; break;
        case Library::TrackSort::Duration:
            result = a.duration < b.duration; break;
        case Library::TrackSort::Genre:
            result = localeCompare(a.genre, b.genre) < 0; break;
        case Library::TrackSort::Composer:
            result = localeCompare(a.composer, b.composer) < 0; break;
        case Library::TrackSort::Filename:
            result = localeCompare(a.path, b.path) < 0; break;
        case Library::TrackSort::DateAdded:
            result = a.dateAdded < b.dateAdded; break;
        case Library::TrackSort::DateLastPlayed:
            result = a.dateLastPlayed < b.dateLastPlayed; break;
        case Library::TrackSort::PlayCount:
            result = a.playCount < b.playCount; break;
        case Library::TrackSort::TrackNumber:
        default:
            result = (a.discNumber != b.discNumber)
                         ? a.discNumber < b.discNumber
                         : a.trackNumber < b.trackNumber;
            break;
        }
        return ascending ? result : !result;
    };

    std::sort(m_tracks.begin(), m_tracks.end(), cmp);

    if (!currentPath.empty()) {
        for (int i = 0; i < (int)m_tracks.size(); ++i) {
            if (m_tracks.at(i).path == currentPath) {
                m_currentTrackIndex = i;
                break;
            }
        }
    }

    if (m_shuffled) generateShuffleOrder();
    if (onQueueChanged) onQueueChanged();
}

void Queue::reverseTracks()
{
    if (m_tracks.empty()) return;

    std::string currentPath =
        (m_currentTrackIndex >= 0 &&
         m_currentTrackIndex < (int)m_tracks.size())
            ? m_tracks.at(m_currentTrackIndex).path : "";

    std::reverse(m_tracks.begin(), m_tracks.end());

    if (!currentPath.empty()) {
        for (int i = 0; i < (int)m_tracks.size(); ++i) {
            if (m_tracks.at(i).path == currentPath) {
                m_currentTrackIndex = i;
                break;
            }
        }
    }

    if (m_shuffled) generateShuffleOrder();
    if (onQueueChanged) onQueueChanged();
}

// ---------------------------------------------------------------------------
// Stop after current
// ---------------------------------------------------------------------------

bool Queue::stopAfterCurrent() const { return m_stopAfterCurrent; }

void Queue::setStopAfterCurrent(bool stop)
{
    m_stopAfterCurrent = stop;
    if (onStopAfterCurrentChanged) onStopAfterCurrentChanged();
}

// ---------------------------------------------------------------------------
// State setters
// ---------------------------------------------------------------------------

void Queue::setSavedPosition(int64_t position) { m_savedPosition = position; }
void Queue::setWasPlaying(bool wasPlaying)      { m_wasPlaying = wasPlaying; }
void Queue::setCurrentTrackIndex(int index)     { m_currentTrackIndex = index; }