import QtQuick
import QtQuick.Controls
import natsuyume_player

Item {
    id: trackRow
    height: 56

    required property var    theme
    required property string title
    required property string artist
    required property string path

    property string album:          ""
    property int    duration:       0
    property bool   showAlbum:      false
    property bool   showDragHandle: false
    property bool   isCurrentTrack: false
    property bool   isPlaying:      false
    property var    actions:        []

    signal dragHandlePressed(real globalY)
    signal dragHandleMoved(real globalY)
    signal dragHandleReleased()
    signal tapped()

    readonly property color primaryText: theme.primaryText
    readonly property color mutedText:   theme.mutedText
    readonly property color accentColor: theme.accentColor

    function formatDuration(ms) {
        if (!ms || ms <= 0) return ""
        let totalSeconds = Math.floor(ms / 1000)
        let minutes = Math.floor(totalSeconds / 60)
        let seconds = totalSeconds % 60
        return minutes + ":" + (seconds < 10 ? "0" + seconds : seconds)
    }

    // Context menu
    ContextMenu {
        id: rowContextMenu
        theme: trackRow.theme
    }

    // ── Background ─────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        radius: 8
        color: trackRow.isCurrentTrack
               ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.18)
               : Qt.rgba(1, 1, 1, 0.04)
    }

    // ── Drag handle ────────────────────────────────────────────
    Item {
        id: dragHandleArea
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: trackRow.showDragHandle ? 28 : 0
        visible: trackRow.showDragHandle

        Text {
            text: "⠿"
            font.pixelSize: 16
            color: trackRow.mutedText
            anchors.centerIn: parent
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.SizeVerCursor
            preventStealing: true

            onPressed: function(mouse) {
                mouse.accepted = true
                let mapped = mapToItem(null, mouse.x, mouse.y)
                trackRow.dragHandlePressed(mapped.y)
            }

            onPositionChanged: function(mouse) {
                let mapped = mapToItem(null, mouse.x, mouse.y)
                trackRow.dragHandleMoved(mapped.y)
            }

            onReleased: function(mouse) {
                trackRow.dragHandleReleased()
            }
        }
    }

    // ── Thumbnail ──────────────────────────────────────────────
    Rectangle {
        id: thumbRect
        anchors.left: dragHandleArea.right
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        width: 44
        height: 44
        radius: 6
        color: Qt.rgba(1, 1, 1, 0.06)

        Image {
            id: thumb
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            source: trackRow.path
                    ? "image://trackcovers/" + encodeURIComponent(trackRow.path)
                    : ""
            layer.enabled: true
            layer.effect: null
        }

        Text {
            anchors.centerIn: parent
            text: "♪"
            font.pixelSize: 18
            color: trackRow.mutedText
            visible: thumb.status !== Image.Ready
        }
    }

    // ── Options button ─────────────────────────────────────────
    Item {
        id: optionsBtn
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 36

        Text {
            text: "⋮"
            font.pixelSize: 16
            color: trackRow.isCurrentTrack
                   ? trackRow.accentColor
                   : trackRow.mutedText
            anchors.centerIn: parent
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (trackRow.actions.length > 0) {
                    rowContextMenu.title   = trackRow.title
                    rowContextMenu.actions = trackRow.actions
                    rowContextMenu.open()
                }
            }
        }
    }

    // ── Duration ───────────────────────────────────────────────
    Text {
        id: durationText
        anchors.right: optionsBtn.left
        anchors.rightMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        text: trackRow.formatDuration(trackRow.duration)
        font.pixelSize: 11
        color: trackRow.mutedText
        width: 44
        horizontalAlignment: Text.AlignRight
        visible: trackRow.duration > 0
    }

    // ── Track info ─────────────────────────────────────────────
    Column {
        anchors.left: thumbRect.right
        anchors.leftMargin: 10
        anchors.right: durationText.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1

        Text {
            text: trackRow.title
            font.pixelSize: 13
            font.weight: trackRow.isCurrentTrack ? Font.Medium : Font.Normal
            color: trackRow.isCurrentTrack
                   ? trackRow.accentColor
                   : trackRow.primaryText
            elide: Text.ElideRight
            width: parent.width
        }

        Text {
            text: trackRow.artist
            font.pixelSize: 11
            color: trackRow.isCurrentTrack
                   ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.8)
                   : trackRow.mutedText
            elide: Text.ElideRight
            width: parent.width
        }

        Text {
            text: trackRow.album
            font.pixelSize: 10
            color: Qt.rgba(1, 1, 1, 0.35)
            elide: Text.ElideRight
            width: parent.width
            visible: trackRow.showAlbum && trackRow.album !== ""
        }
    }

    // ── Tap area ───────────────────────────────────────────────
    MouseArea {
        anchors.left: dragHandleArea.right
        anchors.right: optionsBtn.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) {
                if (trackRow.actions.length > 0) {
                    rowContextMenu.title   = trackRow.title
                    rowContextMenu.actions = trackRow.actions
                    rowContextMenu.open()
                }
            } else {
                trackRow.tapped()
            }
        }

        onPressAndHold: {
            if (trackRow.actions.length > 0) {
                rowContextMenu.title   = trackRow.title
                rowContextMenu.actions = trackRow.actions
                rowContextMenu.open()
            }
        }
    }
}