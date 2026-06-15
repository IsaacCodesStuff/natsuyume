import QtQuick
import QtQuick.Controls

Item {
    id: contextMenu

    required property var    theme
    property string          title:   ""
    property var             actions: []

    readonly property color bgColor:      theme.bgColor
    readonly property color primaryText:  theme.primaryText
    readonly property color mutedText:    theme.mutedText
    readonly property color accentColor:  theme.accentColor

    function open()  { popup.open()  }
    function close() { popup.close() }

    Popup {
        id: popup
        modal: true
        focus: true
        anchors.centerIn: Overlay.overlay
        width: 280
        padding: 0

        background: Rectangle {
            radius: 14
            color: contextMenu.bgColor
            border.color: Qt.rgba(1, 1, 1, 0.08)
            border.width: 1
        }

        Overlay.modal: Rectangle {
            color: Qt.rgba(0, 0, 0, 0.6)
        }

        contentItem: Column {
            id: contentCol
            width: popup.width
            spacing: 4
            topPadding: 16
            bottomPadding: 8
            leftPadding: 12
            rightPadding: 12

            // ── Title ──────────────────────────────────────────
            Text {
                width: popup.width - 24
                height: 24
                text: contextMenu.title
                font.pixelSize: 13
                font.weight: Font.Medium
                color: contextMenu.primaryText
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            Item { width: popup.width; height: 4 }

            Rectangle {
                width: popup.width - 24
                height: 1
                color: Qt.rgba(1, 1, 1, 0.06)
            }

            Item { width: popup.width; height: 4 }

            // ── Action list ────────────────────────────────────
            Repeater {
                model: contextMenu.actions

                Rectangle {
                    width: popup.width - 24
                    height: 44
                    radius: 8

                    property bool hovered: false

                    color: hovered
                           ? Qt.rgba(1, 1, 1, 0.06)
                           : "transparent"

                    Behavior on color {
                        ColorAnimation { duration: 100 }
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.icon || ""
                        font.pixelSize: 16
                        color: modelData.destructive
                               ? "#e05c5c"
                               : contextMenu.mutedText
                        width: 20
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 40
                        anchors.right: parent.right
                        anchors.rightMargin: 40
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.label
                        font.pixelSize: 13
                        color: modelData.destructive
                               ? "#e05c5c"
                               : contextMenu.primaryText
                        elide: Text.ElideRight
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: "soon"
                        font.pixelSize: 9
                        color: contextMenu.mutedText
                        visible: modelData.disabled === true
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
                            popup.close()
                            if (modelData.onTriggered)
                                modelData.onTriggered()
                        }
                    }
                }
            }

            Item { width: popup.width; height: 4 }

            Rectangle {
                width: popup.width - 24
                height: 1
                color: Qt.rgba(1, 1, 1, 0.06)
            }

            Item { width: parent.width; height: 4 }

            // ── Cancel button ──────────────────────────────────
            Rectangle {
                width: popup.width - 24
                height: 44
                radius: 8

                property bool hovered: false

                color: hovered
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
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onEntered: parent.hovered = true
                    onExited:  parent.hovered = false
                    onClicked: popup.close()
                }
            }
        }
    }
}