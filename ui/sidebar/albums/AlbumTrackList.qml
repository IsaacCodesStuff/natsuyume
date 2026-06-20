import QtQuick
import QtQuick.Controls
import "../.."

Item {
    id: albumTrackList

    required property var    theme
    required property string albumName
    required property var    tracks

    signal backRequested
    signal trackListUpdated(var tracks)

    SongInfo {
        id: songInfoDialog
        theme: albumTrackList.theme
    }

    function trackActions(path, title) {
        return [
            {
                label: "Play",
                icon: "▶",
                onTriggered: function() {
                    if (player.isAlbumActiveQueue(albumTrackList.albumName)) {
                        player.jumpToTrackByPath(path)
                    } else {
                        let paths = albumTrackList.tracks.map(t => t.path)
                        player.openFilesInNewQueue(paths, albumTrackList.albumName)
                        player.jumpToTrackByPath(path)
                    }
                }
            },
            {
                label: "Add to queue",
                icon: "+",
                onTriggered: function() { player.requestAddToQueue(path) }
            },
            {
                label: "Add to currently playing queue",
                icon: "⏵+",
                onTriggered: function() { player.addTrackToQueue(path) }
            },
            {
                label: "Add to playlist",
                icon: "🎵",
                onTriggered: function() { player.requestAddToPlaylist(path) }
            },
            {
                label: "Song info",
                icon: "ℹ",
                onTriggered: function() { songInfoDialog.open(path) }
            }
        ]
    }

    ListView {
        id: listView
        anchors.fill: parent
        spacing: 4
        clip: true
        model: albumTrackList.tracks

        delegate: Item {
            width: listView.width
            height: 56

            TrackRow {
                anchors.fill: parent
                theme:          albumTrackList.theme
                title:          modelData.title
                artist:         modelData.artist
                album:          modelData.album
                path:           modelData.path
                duration:       modelData.duration
                showAlbum:      false
                showDragHandle: false
                isCurrentTrack: false
                isPlaying:      false
                actions:        albumTrackList.trackActions(modelData.path, modelData.title)

                onTapped: {
                    if (player.isAlbumActiveQueue(albumTrackList.albumName)) {
                        player.jumpToTrackByPath(modelData.path)
                    } else {
                        let paths = albumTrackList.tracks.map(t => t.path)
                        player.openFilesInNewQueue(paths, albumTrackList.albumName)
                        player.jumpToTrackByPath(modelData.path)
                    }
                }
            }
        }
    }
}