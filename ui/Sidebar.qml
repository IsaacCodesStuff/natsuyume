import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import QtCore
import QtQuick.Dialogs
import "sidebar"

Item {
    id: sidebar

    required property var theme
    required property int currentTab

    readonly property color bgColor:       theme.bgColor
    readonly property color surfaceColor:  theme.surfaceColor
    readonly property color elevatedColor: theme.elevatedColor
    readonly property color primaryText:   theme.primaryText
    readonly property color secondaryText: theme.secondaryText
    readonly property color mutedText:     theme.mutedText
    readonly property color accentColor:   theme.accentColor

    // ── Queue dropdown state ───────────────────────────────────
    property bool   queueDropdownOpen: false
    property int    renamingIndex:     -1
    property string renameBuffer:      ""

    Rectangle {
        anchors.fill: parent
        color: surfaceColor

        // Right-side separator
        Rectangle {
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            width: 1
            color: Qt.rgba(1, 1, 1, 0.05)
        }

        Item {
            anchors.fill: parent

            Loader {
                active: sidebar.currentTab === 0
                anchors.fill: parent
                source: "sidebar/QueuesView.qml"
                onLoaded: item.theme = Qt.binding(function() { return sidebar.theme })
            }
            Loader {
                active: sidebar.currentTab === 1
                anchors.fill: parent
                source: "sidebar/AlbumsView.qml"
                onLoaded: item.theme = Qt.binding(function() { return sidebar.theme })
            }
            Loader {
                active: sidebar.currentTab === 2
                anchors.fill: parent
                source: "sidebar/ArtistsView.qml"
                onLoaded: item.theme = Qt.binding(function() { return sidebar.theme })
            }
            Loader {
                active: sidebar.currentTab === 3
                anchors.fill: parent
                source: "sidebar/PlaylistsView.qml"
                onLoaded: item.theme = Qt.binding(function() { return sidebar.theme })
            }
            Loader {
                active: sidebar.currentTab === 4
                anchors.fill: parent
                source: "sidebar/SettingsView.qml"
                onLoaded: item.theme = Qt.binding(function() { return sidebar.theme })
            }
        }
    }
}