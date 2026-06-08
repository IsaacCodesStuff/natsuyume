import QtQuick
import QtQuick.Controls

Item {
    id: albumSortBar
    height: 32

    required property var theme

    readonly property color mutedText:   theme.mutedText
    readonly property color accentColor: theme.accentColor

    property bool   sortOpen:  false
    property string sortLabel: "Name"

    readonly property var sortOptions: [
        { label: "Name",         value: 0 },
        { label: "Artist",       value: 1 },
        { label: "Album Artist", value: 2 },
        { label: "Year",         value: 3 },
        { label: "Song Count",   value: 4 },
        { label: "Duration",     value: 5 },
        { label: "Composer",     value: 6 },
        { label: "Date Added",   value: 7 }
    ]

    signal sortRequested(int value, string label)
    signal ascendingToggled(bool ascending)

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: Qt.rgba(1, 1, 1, 0.04)

        Row {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 6

            Text {
                text: "⇅"
                font.pixelSize: 13
                color: albumSortBar.sortOpen
                       ? albumSortBar.accentColor
                       : albumSortBar.mutedText
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: albumSortBar.sortLabel
                font.pixelSize: 11
                color: albumSortBar.sortOpen
                       ? albumSortBar.accentColor
                       : albumSortBar.mutedText
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: albumSortBar.sortOpen = !albumSortBar.sortOpen
        }
    }
}