import QtQuick
import QtQuick.Controls

Item {
    id: songInfo

    required property var theme

    readonly property color primaryText:  theme.primaryText
    readonly property color mutedText:    theme.mutedText
    readonly property color accentColor:  theme.accentColor

    property var track: null

    function open(path) {
        track = player.trackInfoByPath(path)
        popup.open()
    }

    function close() { popup.close() }

    function formatDuration(ms) {
        let totalSeconds = Math.floor(ms / 1000)
        let minutes = Math.floor(totalSeconds / 60)
        let seconds = totalSeconds % 60
        return minutes + ":" + (seconds < 10 ? "0" + seconds : seconds)
    }

    function formatDate(timestamp) {
        if (!timestamp || timestamp === 0) return "Never"
        let date = new Date(timestamp * 1000)
        return date.toLocaleDateString()
    }

    Popup {
        id: popup
        modal: true
        focus: true
        anchors.centerIn: Overlay.overlay
        width: 320
        height: Math.min(contentCol.implicitHeight + 32, 480)
        padding: 0

        background: Rectangle {
            radius: 14
            color: songInfo.theme.bgColor
            border.color: Qt.rgba(1, 1, 1, 0.08)
            border.width: 1
        }

        Overlay.modal: Rectangle {
            color: Qt.rgba(0, 0, 0, 0.6)
        }

        contentItem: Flickable {
            contentHeight: contentCol.implicitHeight
            clip: true

            Column {
                id: contentCol
                width: popup.width - 32
                x: 16
                y: 16
                spacing: 0

                Row {
                    width: parent.width
                    height: 24

                    Text {
                        text: "Song Info"
                        font.pixelSize: 14
                        font.weight: Font.Medium
                        color: songInfo.primaryText
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 32
                    }

                    Text {
                        text: "✕"
                        font.pixelSize: 14
                        color: songInfo.mutedText
                        anchors.verticalCenter: parent.verticalCenter

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: songInfo.close()
                        }
                    }
                }

                Item { width: 1; height: 16 }

                Rectangle {
                    width: Math.min(parent.width, 120)
                    height: width
                    radius: 10
                    color: Qt.rgba(1, 1, 1, 0.06)
                    anchors.horizontalCenter: parent.horizontalCenter

                    Image {
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        source: songInfo.track && songInfo.track.path
                                ? "image://trackcovers/"
                                  + encodeURIComponent(songInfo.track.path)
                                : ""
                        layer.enabled: true
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "♪"
                        font.pixelSize: 36
                        color: songInfo.mutedText
                        visible: !songInfo.track || !songInfo.track.path
                    }
                }

                Item { width: 1; height: 16 }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Qt.rgba(1, 1, 1, 0.06)
                }

                Item { width: 1; height: 12 }

                Repeater {
                    model: songInfo.track ? [
                        { label: "Title",        value: songInfo.track.title        },
                        { label: "Artist",       value: songInfo.track.artist       },
                        { label: "Album",        value: songInfo.track.album        },
                        { label: "Album Artist", value: songInfo.track.albumArtist  },
                        { label: "Composer",     value: songInfo.track.composer     },
                        { label: "Genre",        value: songInfo.track.genre        },
                        { label: "Year",         value: songInfo.track.year > 0
                                                        ? songInfo.track.year.toString()
                                                        : "—"                       },
                        { label: "Track",        value: songInfo.track.trackNumber > 0
                                                        ? (songInfo.track.discNumber > 1
                                                           ? songInfo.track.discNumber + "-"
                                                             + songInfo.track.trackNumber
                                                           : songInfo.track.trackNumber.toString())
                                                        : "—"                       },
                        { label: "Duration",     value: songInfo.formatDuration(
                                                        songInfo.track.duration)    },
                        { label: "Play count",   value: songInfo.track.playCount.toString() },
                        { label: "Date added",   value: songInfo.formatDate(
                                                        songInfo.track.dateAdded)   },
                        { label: "Last played",  value: songInfo.formatDate(
                                                        songInfo.track.dateLastPlayed) },
                        { label: "Path",         value: songInfo.track.path        }
                    ] : []

                    Item {
                        width: contentCol.width
                        height: valueText.implicitHeight + 16

                        Text {
                            id: labelText
                            text: modelData.label
                            font.pixelSize: 10
                            color: songInfo.mutedText
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.topMargin: 8
                            width: 90
                        }

                        Text {
                            id: valueText
                            text: modelData.value || "—"
                            font.pixelSize: 12
                            color: songInfo.primaryText
                            anchors.left: labelText.right
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.topMargin: 8
                            wrapMode: Text.WrapAnywhere
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: 1
                            color: Qt.rgba(1, 1, 1, 0.04)
                        }
                    }
                }

                Item { width: 1; height: 8 }
            }
        }
    }
}