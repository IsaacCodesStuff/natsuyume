import QtQuick
import QtQuick.Controls

// SortBar — unified sort button + dropdown.
// Owns its own dropdown internally to avoid binding loops.
//
// Usage:
//   SortBar {
//       sortOptions: [ { label: "Name", value: 0 }, ... ]
//       currentSort: player.albumSort
//       currentAscending: player.albumSortAscending
//       onSortChanged: function(value, label) { player.setAlbumSort(value) }
//       onAscendingChanged: function(ascending) { player.setAlbumSortAscending(ascending) }
//   }

Item {
    id: sortBar
    height: 32

    required property var   theme
    required property var   sortOptions
    required property int   currentSort
    required property bool  currentAscending

    property string currentLabel: sortOptions.length > 0 ? sortOptions[0].label : ""
    property bool   isOpen:       false

    signal sortChanged(int value, string label)
    signal ascendingChanged(bool ascending)

    readonly property color bgColor:     theme.bgColor
    readonly property color primaryText: theme.primaryText
    readonly property color mutedText:   theme.mutedText
    readonly property color accentColor: theme.accentColor

    // ── Sort button ────────────────────────────────────────────
    Rectangle {
        id: sortBtn
        anchors.fill: parent
        radius: 8
        color: sortBar.isOpen
               ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.15)
               : Qt.rgba(1, 1, 1, 0.04)

        Behavior on color {
            ColorAnimation { duration: 100 }
        }

        Row {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 6

            Text {
                text: "⇅"
                font.pixelSize: 13
                color: sortBar.isOpen
                       ? sortBar.accentColor
                       : sortBar.mutedText
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: sortBar.currentLabel
                font.pixelSize: 11
                color: sortBar.isOpen
                       ? sortBar.accentColor
                       : sortBar.mutedText
                anchors.verticalCenter: parent.verticalCenter
                elide: Text.ElideRight
                width: parent.width - 36
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: sortBar.isOpen = !sortBar.isOpen
        }
    }

    // ── Dropdown ───────────────────────────────────────────────
    Item {
        id: dropdown
        visible: sortBar.isOpen
        anchors.top: sortBtn.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 4
        height: sortBar.sortOptions.length * 40 + 52
        z: 100

        Rectangle {
            anchors.fill: parent
            radius: 10
            color: sortBar.bgColor
            border.color: Qt.rgba(1, 1, 1, 0.08)
            border.width: 1

            Column {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 4

                // Asc / Desc toggle
                Item {
                    width: parent.width
                    height: 36

                    Row {
                        anchors.centerIn: parent
                        spacing: 4

                        Repeater {
                            model: [
                                { label: "↑ Asc",  value: true  },
                                { label: "↓ Desc", value: false }
                            ]

                            Rectangle {
                                width:  72
                                height: 28
                                radius: 6
                                color: sortBar.currentAscending === modelData.value
                                       ? Qt.rgba(accentColor.r, accentColor.g,
                                                 accentColor.b, 0.2)
                                       : Qt.rgba(1, 1, 1, 0.06)

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    font.pixelSize: 11
                                    color: sortBar.currentAscending === modelData.value
                                           ? sortBar.accentColor
                                           : sortBar.mutedText
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        sortBar.ascendingChanged(modelData.value)
                                        sortBar.isOpen = false
                                    }
                                }
                            }
                        }
                    }
                }

                // Sort options
                ListView {
                    width: parent.width
                    height: parent.height - 44
                    clip: true
                    spacing: 2
                    model: sortBar.sortOptions

                    delegate: Rectangle {
                        width: parent.width
                        height: 36
                        radius: 6

                        property bool isActive: sortBar.currentSort === modelData.value
                        property bool hovered:  false

                        color: isActive
                               ? Qt.rgba(accentColor.r, accentColor.g,
                                         accentColor.b, 0.15)
                               : hovered
                                 ? Qt.rgba(1, 1, 1, 0.06)
                                 : Qt.rgba(1, 1, 1, 0.04)

                        Behavior on color {
                            ColorAnimation { duration: 100 }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            text: modelData.label
                            font.pixelSize: 12
                            color: isActive
                                   ? sortBar.accentColor
                                   : sortBar.primaryText
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            text: "✓"
                            font.pixelSize: 11
                            color: sortBar.accentColor
                            visible: isActive
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onEntered: parent.hovered = true
                            onExited:  parent.hovered = false
                            onClicked: {
                                sortBar.sortChanged(modelData.value, modelData.label)
                                sortBar.currentLabel = modelData.label
                                sortBar.isOpen = false
                            }
                        }
                    }
                }
            }
        }
    }
}