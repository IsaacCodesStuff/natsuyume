import QtQuick
import QtQuick.Controls
import Qt.labs.folderlistmodel
import QtCore

// FilePicker — temporary file loading solution until Albums,
// Playlists, and Queues views can handle track loading themselves.
//
// Required property:
//   theme — reference to root Window for palette access
//
// Signals:
//   filesSelected(paths) — emitted when user confirms selection
//   cancelled            — emitted when user dismisses the picker

Rectangle {
    id: filePicker

    required property var theme

    signal filesSelected(var filePaths)
    signal cancelled()

    readonly property color bgColor:       theme.bgColor
    readonly property color surfaceColor:  theme.surfaceColor
    readonly property color elevatedColor: theme.elevatedColor
    readonly property color primaryText:   theme.primaryText
    readonly property color secondaryText: theme.secondaryText
    readonly property color mutedText:     theme.mutedText
    readonly property color accentColor:   theme.accentColor

    color: bgColor

    property var    selectedFiles: []
    property string currentPath:   StandardPaths.writableLocation(StandardPaths.MusicLocation)

    FolderListModel {
        id: folderModel
        folder: "file://" + filePicker.currentPath
        showDirs: true
        showFiles: true
        showDotAndDotDot: false
        nameFilters: ["*.mp3", "*.flac", "*.wav", "*.ogg", "*.opus", "*.m4a"]
        sortField: FolderListModel.Name
        showHidden: false
    }

    Column {
        anchors.fill: parent
        spacing: 0

        // ── Top bar ────────────────────────────────────────────
        Rectangle {
            width: parent.width
            height: 52
            color: surfaceColor

            Row {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 8

                // Back button
                Text {
                    text: "‹"
                    font.pixelSize: 28
                    color: primaryText
                    anchors.verticalCenter: parent.verticalCenter

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            let parts = filePicker.currentPath.split("/")
                            parts.pop()
                            let parentPath = parts.join("/")
                            if (parentPath.length > 0)
                                filePicker.currentPath = parentPath
                        }
                    }
                }

                // Current path
                Text {
                    text: filePicker.currentPath
                    font.pixelSize: 11
                    color: mutedText
                    elide: Text.ElideLeft
                    width: parent.width - 120
                    anchors.verticalCenter: parent.verticalCenter
                }

                // Cancel button
                Text {
                    text: "✕"
                    font.pixelSize: 16
                    color: mutedText
                    anchors.verticalCenter: parent.verticalCenter

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            filePicker.selectedFiles = []
                            filePicker.cancelled()
                        }
                    }
                }
            }
        }

        // ── Selection bar ──────────────────────────────────────
        Rectangle {
            width: parent.width
            height: 36
            color: elevatedColor
            visible: filePicker.selectedFiles.length > 0

            Row {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12

                Text {
                    text: filePicker.selectedFiles.length + " selected"
                    font.pixelSize: 12
                    color: accentColor
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 80
                }

                Text {
                    text: "Add to queue"
                    font.pixelSize: 12
                    color: primaryText
                    anchors.verticalCenter: parent.verticalCenter

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            filePicker.filesSelected(filePicker.selectedFiles)
                            filePicker.selectedFiles = []
                        }
                    }
                }
            }
        }

        // ── File list ──────────────────────────────────────────
        ListView {
            id: fileList
            width: parent.width
            height: filePicker.height
                    - 52
                    - (filePicker.selectedFiles.length > 0 ? 36 : 0)
            clip: true
            model: folderModel

            delegate: Rectangle {
                width: fileList.width
                height: 52
                color: {
                    if (!fileIsDir && filePicker.selectedFiles.indexOf(filePath) !== -1)
                        return Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.15)
                    return index % 2 === 0 ? bgColor : surfaceColor
                }

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 12

                    Text {
                        text: fileIsDir ? "📁" : "🎵"
                        font.pixelSize: 18
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: fileName
                        font.pixelSize: 13
                        color: fileIsDir ? secondaryText : primaryText
                        elide: Text.ElideRight
                        width: parent.width - 60
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                // Selection indicator
                Rectangle {
                    visible: !fileIsDir
                             && filePicker.selectedFiles.indexOf(filePath) !== -1
                    width: 4
                    height: parent.height
                    color: accentColor
                    anchors.left: parent.left
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (fileIsDir) {
                            filePicker.currentPath = filePath
                            filePicker.selectedFiles = []
                        } else {
                            let current = filePicker.selectedFiles.slice()
                            let idx = current.indexOf(filePath)
                            if (idx !== -1)
                                current.splice(idx, 1)
                            else
                                current.push(filePath)
                            filePicker.selectedFiles = current
                        }
                    }

                    // Long press to immediately queue single file
                    onPressAndHold: {
                        if (!fileIsDir) {
                            filePicker.filesSelected([filePath])
                            filePicker.selectedFiles = []
                        }
                    }
                }
            }
        }
    }
}