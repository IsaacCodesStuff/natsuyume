import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs

Item {
    id: settingsView

    required property var theme

    readonly property color primaryText: theme.primaryText
    readonly property color mutedText:   theme.mutedText
    readonly property color accentColor: theme.accentColor
    readonly property color bgColor:     theme.bgColor
    readonly property color surfaceColor: theme.surfaceColor

    Flickable {
        anchors.fill: parent
        contentHeight: mainColumn.implicitHeight + 32
        clip: true

        Column {
            id: mainColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 16
            spacing: 24

            // ── Library section ────────────────────────────────
            Column {
                width: parent.width
                spacing: 8

                Text {
                    text: "Library"
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    color: settingsView.mutedText
                    leftPadding: 4
                }

                // Scan progress
                Column {
                    width: parent.width
                    spacing: 6
                    visible: player.isScanning

                    Text {
                        text: "Scanning... " + player.scanProgress + " / " + player.scanTotal
                        font.pixelSize: 11
                        color: settingsView.mutedText
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Rectangle {
                        width: parent.width
                        height: 4
                        radius: 2
                        color: Qt.rgba(1, 1, 1, 0.08)

                        Rectangle {
                            width: player.scanTotal > 0
                                   ? parent.width * (player.scanProgress / player.scanTotal)
                                   : 0
                            height: parent.height
                            radius: 2
                            color: settingsView.accentColor
                            Behavior on width { NumberAnimation { duration: 80 } }
                        }
                    }

                    Text {
                        width: parent.width
                        text: player.scanningFile !== "" ? "↳ " + player.scanningFile : ""
                        font.pixelSize: 10
                        color: settingsView.mutedText
                        elide: Text.ElideMiddle
                    }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: cancelLabel.implicitWidth + 24
                        height: 32
                        radius: 8
                        color: Qt.rgba(1, 1, 1, 0.06)

                        Text {
                            id: cancelLabel
                            anchors.centerIn: parent
                            text: "Cancel"
                            font.pixelSize: 12
                            color: settingsView.mutedText
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: player.cancelScan()
                        }
                    }
                }

                // Folder list
                Column {
                    width: parent.width
                    spacing: 4
                    visible: !player.isScanning

                    Repeater {
                        model: player.scanFolders

                        Rectangle {
                            width: parent.width
                            height: 44
                            radius: 8
                            color: Qt.rgba(1, 1, 1, 0.04)

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 8
                                spacing: 8

                                Text {
                                    text: "📁"
                                    font.pixelSize: 14
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: modelData
                                    font.pixelSize: 11
                                    color: settingsView.primaryText
                                    elide: Text.ElideLeft
                                    width: parent.width - 60
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                // Remove button
                                Item {
                                    width: 32
                                    height: parent.height
                                    anchors.verticalCenter: parent.verticalCenter

                                    Text {
                                        text: "✕"
                                        font.pixelSize: 11
                                        color: settingsView.mutedText
                                        anchors.centerIn: parent
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: player.removeScanFolder(modelData)
                                    }
                                }
                            }
                        }
                    }

                    // Add folder button
                    FolderDialog {
                        id: folderDialog
                        title: "Select Music Folder"
                        onAccepted: {
                            let path = selectedFolder.toString()
                            player.addScanFolder(decodeURIComponent(
                                path.replace(/^file:\/\//, "")))
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 44
                        radius: 8
                        color: Qt.rgba(
                            settingsView.accentColor.r,
                            settingsView.accentColor.g,
                            settingsView.accentColor.b, 0.10)

                        Row {
                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                text: "+"
                                font.pixelSize: 18
                                color: settingsView.accentColor
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: "Add Music Folder"
                                font.pixelSize: 12
                                color: settingsView.accentColor
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: folderDialog.open()
                        }
                    }

                    // Rescan all button
                    Rectangle {
                        width: parent.width
                        height: 44
                        radius: 8
                        visible: player.scanFolders.length > 0
                        color: Qt.rgba(1, 1, 1, 0.04)

                        Text {
                            anchors.centerIn: parent
                            text: "↺  Rescan All Folders"
                            font.pixelSize: 12
                            color: settingsView.mutedText
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: player.rescanAllFolders()
                        }
                    }
                }
            }

            // ── Divider ────────────────────────────────────────
            Rectangle {
                width: parent.width
                height: 1
                color: Qt.rgba(1, 1, 1, 0.06)
            }

            // ── Playback section ───────────────────────────────
            Column {
                width: parent.width
                spacing: 8

                Text {
                    text: "Playback"
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    color: settingsView.mutedText
                    leftPadding: 4
                }

                // Play count threshold
                Column {
                    width: parent.width
                    spacing: 6

                    Text {
                        text: "Count a play after..."
                        font.pixelSize: 12
                        color: settingsView.primaryText
                        leftPadding: 4
                    }

                    Row {
                        width: parent.width
                        spacing: 6

                        Repeater {
                            model: [10, 30, 50, 90]

                            Rectangle {
                                width: (parent.width - 18) / 4
                                height: 36
                                radius: 8
                                color: player.playCountThreshold === modelData
                                       ? Qt.rgba(
                                             settingsView.accentColor.r,
                                             settingsView.accentColor.g,
                                             settingsView.accentColor.b, 0.20)
                                       : Qt.rgba(1, 1, 1, 0.06)

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData + "%"
                                    font.pixelSize: 12
                                    color: player.playCountThreshold === modelData
                                           ? settingsView.accentColor
                                           : settingsView.mutedText
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        player.setPlayCountThreshold(modelData)
                                        player.saveSettings()
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ── Divider ────────────────────────────────────────
            Rectangle {
                width: parent.width
                height: 1
                color: Qt.rgba(1, 1, 1, 0.06)
            }

            // ── About section ──────────────────────────────────
            Column {
                width: parent.width
                spacing: 8

                Text {
                    text: "About"
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    color: settingsView.mutedText
                    leftPadding: 4
                }

                Rectangle {
                    width: parent.width
                    height: 60
                    radius: 8
                    color: Qt.rgba(1, 1, 1, 0.04)

                    Column {
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Natsuyume"
                            font.pixelSize: 14
                            font.weight: Font.Medium
                            color: settingsView.primaryText
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Early development build"
                            font.pixelSize: 10
                            color: settingsView.mutedText
                        }
                    }
                }
            }
        }
    }
}