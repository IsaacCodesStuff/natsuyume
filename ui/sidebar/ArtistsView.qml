import QtQuick
import QtQuick.Controls
import "artists"
import "../"

Item {
    id: artistsView

    property var theme: null
    property string selectedArtist: ""
    property var    artistTracks:   []
    property string searchQuery:    ""

    property int sortRefreshTrigger: 0

    Connections {
        target: player
        function onArtistSortChanged() {
            artistsView.sortRefreshTrigger++
        }
    }

    readonly property var artistSortOptions: [
        { label: "Name",        value: 0 },
        { label: "Song Count",  value: 1 },
        { label: "Duration",    value: 2 },
        { label: "Date Added",  value: 3 }
    ]

    // ── Top bar: search + sort + settings ───────────────────────
    Item {
        id: topBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 8
        height: 36
        visible: artistsView.selectedArtist === ""

        Row {
            anchors.fill: parent
            spacing: 8

            Rectangle {
                width: parent.width - 36 - 36 - 16
                height: 36
                radius: 8
                color: Qt.rgba(1, 1, 1, 0.06)

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 6

                    Text {
                        text: "⌕"
                        font.pixelSize: 16
                        color: artistsView.theme.mutedText
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    TextField {
                        width: parent.width - 26
                        anchors.verticalCenter: parent.verticalCenter
                        font.pixelSize: 12
                        color: artistsView.theme.primaryText
                        placeholderText: "Search an artist..."
                        placeholderTextColor: artistsView.theme.mutedText
                        background: Item {}
                        onTextChanged: artistsView.searchQuery = text.toLowerCase()
                    }
                }
            }

            SortBar {
                width: 36
                height: 36
                iconOnly: true
                theme: artistsView.theme
                sortOptions: artistsView.artistSortOptions
                currentSort: player.artistSort()
                currentAscending: player.artistSortAscending()

                onSortChanged: function(value, label) {
                    player.setArtistSort(value)
                }
                onAscendingChanged: function(ascending) {
                    player.setArtistSortAscending(ascending)
                }
            }
        }
    }

    // ── Artist list ────────────────────────────────────────────
    ListView {
        id: artistList
        anchors.top: topBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.topMargin: 8
        anchors.margins: 8
        clip: true
        visible: artistsView.selectedArtist === ""

        model: {
            let trigger = artistsView.sortRefreshTrigger // force re-eval on sort change
            let all = player.allArtistsSorted()
            if (artistsView.searchQuery === "") return all
            return all.filter(a => a.toLowerCase().includes(artistsView.searchQuery))
        }

        delegate: Item {
            width: artistList.width
            height: 48

            Rectangle {
                anchors.fill: parent
                anchors.margins: 2
                radius: 8
                color: Qt.rgba(1, 1, 1, 0.0)

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    text: modelData
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    color: artistsView.theme.primaryText
                    elide: Text.ElideRight
                    width: parent.width - 24
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        artistsView.selectedArtist = modelData
                        artistsView.artistTracks   = player.tracksForArtist(modelData)
                    }
                }
            }
        }
    }

    // ── Artist detail ──────────────────────────────────────────
    Item {
        anchors.fill: parent
        visible: artistsView.selectedArtist !== ""

        // Header
        Rectangle {
            id: artistHeader
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 44
            color: Qt.rgba(0, 0, 0, 0.15)

            Row {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 8

                Text {
                    text: "‹"
                    font.pixelSize: 24
                    color: artistsView.theme.primaryText
                    anchors.verticalCenter: parent.verticalCenter

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            artistsView.selectedArtist = ""
                            artistsView.artistTracks   = []
                        }
                    }
                }

                Text {
                    text: artistsView.selectedArtist
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    color: artistsView.theme.primaryText
                    elide: Text.ElideRight
                    width: parent.width - 36
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        // Track list
        ArtistTrackList {
            id: trackList
            anchors.top: artistHeader.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            theme:      artistsView.theme
            artistName: artistsView.selectedArtist
            tracks:     artistsView.artistTracks

            onBackRequested: {
                artistsView.selectedArtist = ""
                artistsView.artistTracks   = []
            }
        }
    }
}