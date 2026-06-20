import QtQuick
import QtQuick.Controls

Item {
    id: queuePicker

    required property var theme

    property var m_paths: []

    function open(paths) {
        m_paths = paths
        popup.open()
    }

    readonly property color bgColor:     theme.bgColor
    readonly property color primaryText: theme.primaryText
    readonly property color mutedText:   theme.mutedText
    readonly property color accentColor: theme.accentColor

    Popup {
        id: popup
        modal: true
        focus: true
        anchors.centerIn: Overlay.overlay
        width: 280
        padding: 0

        background: Rectangle {
            radius: 14
            color: queuePicker.bgColor
            border.color: Qt.rgba(1, 1, 1, 0.08)
            border.width: 1
        }

        Overlay.modal: Rectangle {
            color: Qt.rgba(0, 0, 0, 0.6)
        }

        contentItem: Column {
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
                text: "Add to queue"
                font.pixelSize: 13
                font.weight: Font.Medium
                color: queuePicker.primaryText
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

            // ── New queue button ────────────────────────────────
            Rectangle {
                width: popup.width - 24
                height: 44
                radius: 8
                property bool hovered: false
                color: hovered ? Qt.rgba(1, 1, 1, 0.06) : "transparent"

                Behavior on color { ColorAnimation { duration: 100 } }

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    spacing: 12

                    Text {
                        text: "+"
                        font.pixelSize: 20
                        color: queuePicker.accentColor
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "New Queue"
                        font.pixelSize: 13
                        color: queuePicker.accentColor
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onEntered: parent.hovered = true
                    onExited:  parent.hovered = false
                    onClicked: {
                        player.addPathsToNewQueue(queuePicker.m_paths)
                        popup.close()
                    }
                }
            }

            // ── Existing queues ─────────────────────────────────
            Repeater {
                model: player.queueNames

                Rectangle {
                    width: popup.width - 24
                    height: 44
                    radius: 8
                    property bool hovered: false
                    color: hovered ? Qt.rgba(1, 1, 1, 0.06) : "transparent"

                    Behavior on color { ColorAnimation { duration: 100 } }

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 8

                        Text {
                            text: index === player.activeQueueIndex ? "▶" : (index + 1) + "."
                            font.pixelSize: 12
                            color: index === player.activeQueueIndex
                                   ? queuePicker.accentColor
                                   : queuePicker.mutedText
                            anchors.verticalCenter: parent.verticalCenter
                            width: 18
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 26
                            text: modelData
                            font.pixelSize: 13
                            color: index === player.activeQueueIndex
                                   ? queuePicker.accentColor
                                   : queuePicker.primaryText
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onEntered: parent.hovered = true
                        onExited:  parent.hovered = false
                        onClicked: {
                            player.addPathsToQueue(index, queuePicker.m_paths)
                            popup.close()
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

            Item { width: popup.width; height: 4 }

            // ── Cancel ───────────────────────────────────────────
            Rectangle {
                width: popup.width - 24
                height: 44
                radius: 8
                property bool hovered: false
                color: hovered ? Qt.rgba(1, 1, 1, 0.06) : "transparent"

                Behavior on color { ColorAnimation { duration: 100 } }

                Text {
                    anchors.centerIn: parent
                    text: "Cancel"
                    font.pixelSize: 13
                    color: queuePicker.mutedText
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