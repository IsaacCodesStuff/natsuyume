import QtQuick
import "queues"

Item {
    id: queuesView

    required property var theme

    // ── Top bar ────────────────────────────────────────────────
    QueueTopBar {
        id: topBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        theme: queuesView.theme
        onDropdownToggled: dropdown.open()
    }

    // ── Track list ─────────────────────────────────────────────
    QueueTrackList {
        id: trackListArea
        anchors.top: topBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        theme: queuesView.theme
    }

    // ── Queue dropdown (Popup-based) ────────────────────────────
    QueueDropdown {
        id: dropdown
        theme: queuesView.theme
    }
}