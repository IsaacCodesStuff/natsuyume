import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs

Item {
    id: settingsView

    required property var theme

    readonly property color primaryText: theme.primaryText
    readonly property color mutedText:   theme.mutedText
    readonly property color accentColor: theme.accentColor

    Column {
        anchors.centerIn: parent
        spacing: 16
        width: parent.width - 32

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Library"
            font.pixelSize: 13
            font.weight: Font.Medium
            color: settingsView.primaryText
        }

        // ── Scan progress ──────────────────────────────────────
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

                    Behavior on width {
                        NumberAnimation { duration: 80 }
                    }
                }
            }

            Text {
                width: parent.width
                text: player.scanningFile !== "" ? "↳ " + player.scanningFile : ""
                font.pixelSize: 10
                color: settingsView.mutedText
                elide: Text.ElideMiddle
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: cancelBtn.implicitWidth + 24
                height: 32
                radius: 8
                color: Qt.rgba(1, 1, 1, 0.06)

                Text {
                    id: cancelBtn
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

        // ── Scan folder button ─────────────────────────────────
        Rectangle {
            width: parent.width
            height: 36
            radius: 8
            color: Qt.rgba(1, 1, 1, 0.06)
            visible: !player.isScanning

            FolderDialog {
                id: folderDialog
                title: "Select Music Folder"
                onAccepted: {
                    let path = selectedFolder.toString().replace("file://", "")
                    player.scanFolder(path)
                }
            }

            Text {
                anchors.centerIn: parent
                text: "Scan Music Folder"
                font.pixelSize: 12
                color: settingsView.accentColor
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: folderDialog.open()
            }
        }
    }
}