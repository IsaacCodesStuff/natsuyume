import QtQuick

Item {
    id: albumCover

    required property string albumName
    required property var    theme

    readonly property color mutedText:    theme.mutedText
    readonly property color surfaceColor: theme.surfaceColor

    // Cache buster — increments when library updates
    property int revision: 0

    Connections {
        target: player
        function onScanningChanged() {
            if (!player.isScanning)
                albumCover.revision++
        }
    }

    Image {
        id: coverImage
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        visible: status === Image.Ready && !isTransparent
        asynchronous: true
        cache: false

        property bool isTransparent: false

        onStatusChanged: {
            if (status === Image.Ready) {
                // A transparent fallback image means no cover art
                isTransparent = (sourceSize.width === 0 || sourceSize.height === 0)
            }
        }

        source: albumName !== "" && !player.isScanning
                ? "image://albumcovers/" + albumName + "?r=" + albumCover.revision
                : ""
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(1, 1, 1, 0.06)
        visible: coverImage.status !== Image.Ready || coverImage.isTransparent

        Text {
            anchors.centerIn: parent
            text: "♪"
            font.pixelSize: parent.width * 0.3
            color: albumCover.mutedText
        }
    }
}