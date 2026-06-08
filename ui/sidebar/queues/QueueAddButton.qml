import QtQuick

Item {
    id: queueAddButton
    height: 36

    required property var theme

    readonly property color mutedText: theme.mutedText

    signal addRequested

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: Qt.rgba(1, 1, 1, 0.06)

        Text {
            anchors.centerIn: parent
            text: "+ Add Files"
            font.pixelSize: 12
            color: queueAddButton.mutedText
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: queueAddButton.addRequested()
        }
    }
}