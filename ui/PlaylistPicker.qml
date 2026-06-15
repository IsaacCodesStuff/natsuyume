import QtQuick
import QtQuick.Controls

Item {
    id: playlistPicker

    required property var theme

    // Call this to open the picker for a specific track path

    property string m_trackPath: ""
    property string m_albumName: ""  // set when adding whole album

    function open(trackPath) {
        m_trackPath = trackPath
        m_albumName = ""
        popup.open()
    }

    function openForAlbum(albumName) {
        m_albumName = albumName
        m_trackPath = ""
        popup.open()
    }

    readonly property color bgColor:      theme.bgColor
    readonly property color primaryText:  theme.primaryText
    readonly property color mutedText:    theme.mutedText
    readonly property color accentColor:  theme.accentColor

    Popup {
        id: popup
        modal: true
        focus: true
        anchors.centerIn: Overlay.overlay
        width: 280
        padding: 0

        background: Rectangle {
            radius: 14
            color: playlistPicker.bgColor
            border.color: Qt.rgba(1, 1, 1, 0.08)
            border.width: 1
        }

        Overlay.modal: Rectangle {
            color: Qt.rgba(0, 0, 0, 0.6)
        }

        contentItem: Column {
            width: popup.width
            spacing: 4
            topPadding: 16
            bottomPadding: 8
            leftPadding: 12
            rightPadding: 12

            // ── Title ──────────────────────────────────────────
            Text {
                width: popup.width - 24
                height: 24
                text: "Add to playlist"
                font.pixelSize: 13
                font.weight: Font.Medium
                color: playlistPicker.primaryText
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            Item { width: popup.width; height: 4 }

            Rectangle {
                width: popup.width - 24
                height: 1
                color: Qt.rgba(1, 1, 1, 0.06)
            }

            Item { width: popup.width; height: 4 }

            // ── New playlist button ────────────────────────────
            Rectangle {
                width: popup.width - 24
                height: 44
                radius: 8
                property bool hovered: false
                color: hovered ? Qt.rgba(1, 1, 1, 0.06) : "transparent"

                Behavior on color { ColorAnimation { duration: 100 } }

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    spacing: 12

                    Text {
                        text: "+"
                        font.pixelSize: 20
                        color: playlistPicker.accentColor
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "New playlist..."
                        font.pixelSize: 13
                        color: playlistPicker.accentColor
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onEntered: parent.hovered = true
                    onExited:  parent.hovered = false
                    onClicked: {
                        popup.close()
                        nameDialog.open()
                    }
                }
            }

            // ── Existing playlists ─────────────────────────────
            Repeater {
                model: player.allPlaylists

                Rectangle {
                    width: popup.width - 24
                    height: 44
                    radius: 8
                    property bool hovered: false
                    color: hovered ? Qt.rgba(1, 1, 1, 0.06) : "transparent"

                    Behavior on color { ColorAnimation { duration: 100 } }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.name
                        font.pixelSize: 13
                        color: playlistPicker.primaryText
                        elide: Text.ElideRight
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onEntered: parent.hovered = true
                        onExited:  parent.hovered = false
                        onClicked: {
                            if (playlistPicker.m_albumName !== "") {
                            let tracks = player.tracksForAlbum(playlistPicker.m_albumName)
                            for (let i = 0; i < tracks.length; i++)
                                player.addTrackToPlaylist(modelData.id, tracks[i].path)
                            } else {
                                player.addTrackToPlaylist(modelData.id, playlistPicker.m_trackPath)
                                }
                            popup.close()
                        }
                    }
                }
            }

            Item { width: popup.width; height: 4 }

            Rectangle {
                width: popup.width - 24
                height: 1
                color: Qt.rgba(1, 1, 1, 0.06)
            }

            Item { width: popup.width; height: 4 }

            // ── Cancel ─────────────────────────────────────────
            Rectangle {
                width: popup.width - 24
                height: 44
                radius: 8
                property bool hovered: false
                color: hovered ? Qt.rgba(1, 1, 1, 0.06) : "transparent"

                Behavior on color { ColorAnimation { duration: 100 } }

                Text {
                    anchors.centerIn: parent
                    text: "Cancel"
                    font.pixelSize: 13
                    color: playlistPicker.mutedText
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onEntered: parent.hovered = true
                    onExited:  parent.hovered = false
                    onClicked: popup.close()
                }
            }
        }
    }

    // ── New playlist name dialog ───────────────────────────────
    Popup {
        id: nameDialog
        modal: true
        focus: true
        anchors.centerIn: Overlay.overlay
        width: 280
        padding: 0

        background: Rectangle {
            radius: 14
            color: playlistPicker.bgColor
            border.color: Qt.rgba(1, 1, 1, 0.08)
            border.width: 1
        }

        Overlay.modal: Rectangle {
            color: Qt.rgba(0, 0, 0, 0.6)
        }

        onOpened: {
            nameField.text = ""
            nameField.forceActiveFocus()
        }

        contentItem: Column {
            width: popup.width
            spacing: 4
            topPadding: 16
            bottomPadding: 12
            leftPadding: 12
            rightPadding: 12

            Text {
                width: nameDialog.width - 24
                height: 24
                text: "New playlist"
                font.pixelSize: 13
                font.weight: Font.Medium
                color: playlistPicker.primaryText
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            Item { width: nameDialog.width; height: 8 }

            Rectangle {
                width: nameDialog.width - 24
                height: 40
                radius: 8
                color: Qt.rgba(1, 1, 1, 0.06)

                TextField {
                    id: nameField
                    anchors.fill: parent
                    anchors.margins: 4
                    font.pixelSize: 13
                    color: playlistPicker.primaryText
                    placeholderText: "Playlist name"
                    placeholderTextColor: playlistPicker.mutedText
                    background: Item {}

                    onAccepted: createAndAdd()
                }
            }

            Item { width: nameDialog.width; height: 8 }

            // Confirm button
            Rectangle {
                width: nameDialog.width - 24
                height: 44
                radius: 8
                color: Qt.rgba(
                    playlistPicker.accentColor.r,
                    playlistPicker.accentColor.g,
                    playlistPicker.accentColor.b, 0.18)

                Text {
                    anchors.centerIn: parent
                    text: "Create & add"
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    color: playlistPicker.accentColor
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: createAndAdd()
                }
            }

            Item { width: nameDialog.width; height: 4 }

            // Cancel button
            Rectangle {
                width: nameDialog.width - 24
                height: 44
                radius: 8
                property bool hovered: false
                color: hovered ? Qt.rgba(1, 1, 1, 0.06) : "transparent"

                Behavior on color { ColorAnimation { duration: 100 } }

                Text {
                    anchors.centerIn: parent
                    text: "Cancel"
                    font.pixelSize: 13
                    color: playlistPicker.mutedText
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onEntered: parent.hovered = true
                    onExited:  parent.hovered = false
                    onClicked: nameDialog.close()
                }
            }
        }
    }

    function createAndAdd() {
        let name = nameField.text.trim()
        if (name.length === 0) return
        let id = player.createPlaylist(name)
        if (id >= 0) {
            if (playlistPicker.m_albumName !== "") {
                let tracks = player.tracksForAlbum(playlistPicker.m_albumName)
                for (let i = 0; i < tracks.length; i++)
                    player.addTrackToPlaylist(id, tracks[i].path)
            } else if (playlistPicker.m_trackPath !== "") {
                player.addTrackToPlaylist(id, playlistPicker.m_trackPath)
            }
        }
        nameDialog.close()
    }
}