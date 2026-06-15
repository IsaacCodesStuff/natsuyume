import QtQuick
import QtQuick.Controls
import "artists"

Item {
    id: artistsView

    required property var theme

    property string selectedArtist: ""
    property var    artistTracks:   []
    property string searchQuery:    ""

    // ── Search bar ─────────────────────────────────────────────
    Rectangle {
        id: searchBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 8
        height: 36
        radius: 8
        color: Qt.rgba(1, 1, 1, 0.06)
        visible: artistsView.selectedArtist === ""

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
                placeholderText: "Search artists..."
                placeholderTextColor: artistsView.theme.mutedText
                background: Item {}
                onTextChanged: artistsView.searchQuery = text.toLowerCase()
            }
        }
    }

    // ── Artist list ────────────────────────────────────────────
    ListView {
        id: artistList
        anchors.top: searchBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.topMargin: 8
        anchors.margins: 8
        clip: true
        visible: artistsView.selectedArtist === ""

        model: {
            let all = player.allArtists
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