import QtQuick
import natsuyume_player

Item {
    id: queueTopBar
    height: 84

    required property var theme
    readonly property color primaryText: theme.primaryText
    readonly property color mutedText:   theme.mutedText
    readonly property color accentColor: theme.accentColor

    signal dropdownToggled

    property bool dropdownOpen: false

    function formatDuration(ms) {
        let totalSeconds = Math.floor(ms / 1000)
        let hours = Math.floor(totalSeconds / 3600)
        let minutes = Math.floor((totalSeconds % 3600) / 60)
        let seconds = totalSeconds % 60
        let mm = (hours > 0 && minutes < 10) ? "0" + minutes : minutes
        let ss = seconds < 10 ? "0" + seconds : seconds
        return hours > 0 ? (hours + ":" + mm + ":" + ss) : (minutes + ":" + ss)
    }

    QueueSortMenu {
        id: sortMenu
        theme: queueTopBar.theme
    }

    SaveAsPlaylistDialog {
        id: saveDialog
        theme: queueTopBar.theme
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.15)

        Column {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 4

            // ── Row 1: queue name + dropdown ────────────────────
            Item {
                width: parent.width
                height: 40

                Row {
                    anchors.fill: parent
                    spacing: 8

                    Rectangle {
                        width: 28
                        height: 28
                        radius: 6
                        anchors.verticalCenter: parent.verticalCenter
                        color: queueTopBar.dropdownOpen
                               ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.2)
                               : Qt.rgba(1, 1, 1, 0.08)

                        Text {
                            anchors.centerIn: parent
                            text: "☰"
                            font.pixelSize: 14
                            color: queueTopBar.dropdownOpen
                                   ? queueTopBar.accentColor
                                   : queueTopBar.primaryText
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: queueTopBar.dropdownToggled()
                        }
                    }

                    Text {
                        text: player.queueCount > 0
                              ? player.queueNames[player.activeQueueIndex]
                              : "No Queue"
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        color: queueTopBar.primaryText
                        elide: Text.ElideRight
                        width: parent.width - 36 - 36
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Rectangle {
                        width: 28
                        height: 28
                        radius: 6
                        anchors.verticalCenter: parent.verticalCenter
                        visible: player.queueCount > 0
                        color: Qt.rgba(1, 1, 1, 0.08)

                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            font.pixelSize: 12
                            color: queueTopBar.mutedText
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: player.closeQueue(player.activeQueueIndex)
                        }
                    }
                }
            }

            // ── Row 2: controls ─────────────────────────────────
            Item {
                width: parent.width
                height: 36
                visible: player.queueCount > 0

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    // Play/pause
                    Rectangle {
                        width: 32
                        height: 32
                        radius: 8
                        color: Qt.rgba(1, 1, 1, 0.06)

                        Text {
                            anchors.centerIn: parent
                            text: player.isPlaying ? "⏸" : "▶"
                            font.pixelSize: 14
                            color: queueTopBar.accentColor
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: player.isPlaying ? player.pause() : player.play()
                        }
                    }

                    // Sort
                    Rectangle {
                        width: 32
                        height: 32
                        radius: 8
                        color: Qt.rgba(1, 1, 1, 0.06)

                        Text {
                            anchors.centerIn: parent
                            text: "⇅"
                            font.pixelSize: 14
                            color: queueTopBar.mutedText
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: sortMenu.open()
                        }
                    }
                }

                // Track count + duration — centered
                Column {
                    anchors.centerIn: parent
                    spacing: 1

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: (player.trackIndex + 1) + " / " + player.trackCount
                        font.pixelSize: 11
                        color: queueTopBar.mutedText
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "⏱ " + queueTopBar.formatDuration(player.queueTotalDuration)
                        font.pixelSize: 10
                        color: queueTopBar.mutedText
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                // Save + overflow — right aligned
                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Rectangle {
                        width: 32
                        height: 32
                        radius: 8
                        color: Qt.rgba(1, 1, 1, 0.06)

                        Text {
                            anchors.centerIn: parent
                            text: "💾"
                            font.pixelSize: 13
                            color: queueTopBar.mutedText
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: saveDialog.open()
                        }
                    }

                    Rectangle {
                        id: overflowBtn
                        width: 32
                        height: 32
                        radius: 8
                        color: Qt.rgba(1, 1, 1, 0.06)

                        Text {
                            anchors.centerIn: parent
                            text: "⋯"
                            font.pixelSize: 14
                            color: queueTopBar.mutedText
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: overflowMenu.open()
                        }
                    }
                }
            }
        }
    }

    ContextMenu {
        id: overflowMenu
        theme: queueTopBar.theme
        title: "Queue options"
        actions: [
            { label: "Share songs",        icon: "🔗", disabled: true },
            { label: "Export as .M3U",     icon: "⬇",  disabled: true },
            { label: "Select multiple",    icon: "☑",  disabled: true }
        ]
    }
}