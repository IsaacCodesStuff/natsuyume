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

        StackLayout {
            id: contentStack
            anchors.fill: parent
            currentIndex: sidebar.currentTab

            // ── Queues ─────────────────────────────────────────
            QueuesView {
                theme: sidebar.theme
            }

            // ── Albums ─────────────────────────────────────────
            AlbumsView {
                theme: sidebar.theme
            }

            // ── Artists ────────────────────────────────────────
            ArtistsView {
                theme: sidebar.theme
            }

            // ── Playlists ──────────────────────────────────────
            PlaylistsView {
                theme: sidebar.theme
            }

            // ── Settings ───────────────────────────────────────
            SettingsView {
                theme: sidebar.theme
            }
        }
    }
}