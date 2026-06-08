import QtQuick

Item {
    id: queueTopBar
    height: 44

    required property var theme

    readonly property color primaryText: theme.primaryText
    readonly property color accentColor: theme.accentColor

    property bool dropdownOpen: false

    signal dropdownToggled

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.15)

        Row {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 8

            // Queue list button
            Rectangle {
                width: 28
                height: 28
                radius: 6
                color: queueTopBar.dropdownOpen
                       ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.2)
                       : Qt.rgba(1, 1, 1, 0.08)
                anchors.verticalCenter: parent.verticalCenter

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

            // Active queue name
            Text {
                text: player.queueCount > 0
                      ? player.queueNames[player.activeQueueIndex]
                      : "No Queue"
                font.pixelSize: 13
                font.weight: Font.Medium
                color: queueTopBar.primaryText
                elide: Text.ElideRight
                width: parent.width - 36
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}