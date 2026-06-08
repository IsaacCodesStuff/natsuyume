import QtQuick
import "queues"

Item {
    id: queuesView

    required property var theme

    property bool dropdownOpen: false

    // ── Top bar ────────────────────────────────────────────────
    QueueTopBar {
        id: topBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        theme: queuesView.theme
        dropdownOpen: queuesView.dropdownOpen
        onDropdownToggled: queuesView.dropdownOpen = !queuesView.dropdownOpen
    }

    // ── Track list ─────────────────────────────────────────────
    QueueTrackList {
        id: trackListArea
        anchors.top: topBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: addButton.top
        anchors.bottomMargin: 8
        theme: queuesView.theme
        dimmed: queuesView.dropdownOpen
        onDismissRequested: queuesView.dropdownOpen = false
    }

    // ── Add file button ────────────────────────────────────────
    QueueAddButton {
        id: addButton
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 8
        theme: queuesView.theme
        onAddRequested: { /* TODO */ }
    }

    // ── Queue dropdown ─────────────────────────────────────────
    QueueDropdown {
        id: dropdown
        visible: queuesView.dropdownOpen
        z: 10
        anchors.top: topBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: Math.min(
            player.queueCount * 52 + 52,
            parent.height - topBar.height - 16
        )
        theme: queuesView.theme
        onCloseRequested: queuesView.dropdownOpen = false
    }
}