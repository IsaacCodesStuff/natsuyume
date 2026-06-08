import QtQuick
import QtQuick.Controls

// ContextMenu — universal centered action dialog.
//
// Usage:
//   ContextMenu {
//       id: menu
//       theme: root
//       title: "Track Name"
//       actions: [
//           { label: "Play",   icon: "▶", onTriggered: function() { ... } },
//           { label: "Remove", icon: "✕", onTriggered: function() { ... } }
//       ]
//   }
//
//   menu.open()

Item {
    id: contextMenu

    required property var    theme
    property string          title:   ""
    property var             actions: []
    property bool            isOpen:  false

    readonly property color bgColor:      theme.bgColor
    readonly property color surfaceColor: theme.surfaceColor
    readonly property color primaryText:  theme.primaryText
    readonly property color secondaryText: theme.secondaryText
    readonly property color mutedText:    theme.mutedText
    readonly property color accentColor:  theme.accentColor

    function open()  { isOpen = true  }
    function close() { isOpen = false }

    anchors.fill: parent
    visible: isOpen
    z: 100

    // ── Dim background ─────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.6)
        opacity: contextMenu.isOpen ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation { duration: 180 }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: contextMenu.close()
        }
    }

    // ── Centered dialog ────────────────────────────────────────
    Rectangle {
        id: dialog
        anchors.centerIn: parent
        width: Math.min(parent.width - 48, 320)
        height: contentCol.implicitHeight + 24
        radius: 14
        color: contextMenu.bgColor
        border.color: Qt.rgba(1, 1, 1, 0.08)
        border.width: 1

        // Prevent clicks from falling through to dim background
        MouseArea {
            anchors.fill: parent
        }

        Column {
            id: contentCol
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 12
            anchors.topMargin: 16
            spacing: 4

            // ── Title ──────────────────────────────────────────
            Text {
                width: parent.width
                text: contextMenu.title
                font.pixelSize: 13
                font.weight: Font.Medium
                color: contextMenu.primaryText
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                bottomPadding: 8
            }

            // ── Divider ────────────────────────────────────────
            Item {
                width: parent.width
                height: 8
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Qt.rgba(1, 1, 1, 0.06)
            }

            Item {
                width: parent.width
                height: 4
            }

            // ── Action list ────────────────────────────────────
            Repeater {
                model: contextMenu.actions

                Rectangle {
                    width: parent.width
                    height: 44
                    radius: 8

                    property bool hovered: false

                    color: hovered
                           ? Qt.rgba(1, 1, 1, 0.06)
                           : "transparent"

                    Behavior on color {
                        ColorAnimation { duration: 100 }
                    }

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 12

                        Text {
                            text: modelData.icon || ""
                            font.pixelSize: 16
                            color: modelData.destructive
                                   ? "#e05c5c"
                                   : contextMenu.mutedText
                            anchors.verticalCenter: parent.verticalCenter
                            width: 20
                        }

                        Text {
                            text: modelData.label
                            font.pixelSize: 13
                            color: modelData.destructive
                                   ? "#e05c5c"
                                   : contextMenu.primaryText
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: "soon"
                            font.pixelSize: 9
                            color: contextMenu.mutedText
                            visible: modelData.disabled === true
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: modelData.disabled
                                     ? Qt.ArrowCursor
                                     : Qt.PointingHandCursor
                        hoverEnabled: true
                        enabled: !modelData.disabled
                        onEntered: parent.hovered = true
                        onExited:  parent.hovered = false
                        onClicked: {
                            contextMenu.close()
                            if (modelData.onTriggered)
                                modelData.onTriggered()
                        }
                    }
                }
            }

            // ── Divider ────────────────────────────────────────
            Item {
                width: parent.width
                height: 8
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Qt.rgba(1, 1, 1, 0.06)
            }

            Item {
                width: parent.width
                height: 4
            }

            // ── Cancel button ──────────────────────────────────
            Rectangle {
                width: parent.width
                height: 44
                radius: 8
                color: cancelArea.containsMouse
                       ? Qt.rgba(1, 1, 1, 0.06)
                       : "transparent"

                Behavior on color {
                    ColorAnimation { duration: 100 }
                }

                Text {
                    anchors.centerIn: parent
                    text: "Cancel"
                    font.pixelSize: 13
                    color: contextMenu.mutedText
                }

                MouseArea {
                    id: cancelArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: contextMenu.close()
                }
            }
        }
    }
}