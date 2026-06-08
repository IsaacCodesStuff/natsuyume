import QtQuick
import QtQuick.Controls

Item {
    id: trackSortBar
    height: 36

    required property var theme

    readonly property color mutedText:   theme.mutedText
    readonly property color accentColor: theme.accentColor

    property bool   sortOpen:  false
    property string sortLabel: "Track №"

    readonly property var sortOptions: [
        { label: "Track №",      value: 0  },
        { label: "Title",        value: 1  },
        { label: "Artist",       value: 2  },
        { label: "Album Artist", value: 3  },
        { label: "Year",         value: 4  },
        { label: "Duration",     value: 5  },
        { label: "Genre",        value: 6  },
        { label: "Composer",     value: 7  },
        { label: "Filename",     value: 8  },
        { label: "Date Added",   value: 9  },
        { label: "Last Played",  value: 10 },
        { label: "Play Count",   value: 11 }
    ]

    signal sortRequested(int value, string label)
    signal ascendingToggled(bool ascending)
    signal tracksRefreshNeeded

    Rectangle {
        id: sortBtn
        anchors.fill: parent
        radius: 8
        color: trackSortBar.sortOpen
               ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.15)
               : Qt.rgba(1, 1, 1, 0.06)

        Row {
            anchors.centerIn: parent
            spacing: 6

            Text {
                text: "⇅"
                font.pixelSize: 14
                color: trackSortBar.sortOpen
                       ? trackSortBar.accentColor
                       : trackSortBar.mutedText
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: trackSortBar.sortLabel
                font.pixelSize: 11
                color: trackSortBar.sortOpen
                       ? trackSortBar.accentColor
                       : trackSortBar.mutedText
                anchors.verticalCenter: parent.verticalCenter
                elide: Text.ElideRight
                width: sortBtn.width - 40
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: trackSortBar.sortOpen = !trackSortBar.sortOpen
        }
    }
}