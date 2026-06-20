import QtQuick
import QtQuick.Controls

Item {
    id: queueSortMenu

    required property var theme

    readonly property color bgColor:     theme.bgColor
    readonly property color primaryText: theme.primaryText
    readonly property color mutedText:   theme.mutedText
    readonly property color accentColor: theme.accentColor

    readonly property var sortOptions: [
        { label: "Track Number",     value: 0  },
        { label: "Title",            value: 1  },
        { label: "Artist",           value: 2  },
        { label: "Album Artist",     value: 3  },
        { label: "Year",             value: 4  },
        { label: "Duration",         value: 5  },
        { label: "Genre",            value: 6  },
        { label: "Composer",         value: 7  },
        { label: "Filename",         value: 8  },
        { label: "Date Added",       value: 9  },
        { label: "Date Last Played", value: 10 },
        { label: "Play Count",       value: 11 }
    ]

    function open() { popup.open() }

    Popup {
        id: popup
        modal: true
        focus: true
        anchors.centerIn: Overlay.overlay
        width: 280
        height: Math.min(440, 44 + 36 + 1 + (queueSortMenu.sortOptions.length * 38) + 24)
        padding: 0

        background: Rectangle {
            radius: 10
            color: queueSortMenu.bgColor
            border.color: Qt.rgba(1, 1, 1, 0.08)
            border.width: 1
        }

        Overlay.modal: Rectangle {
            color: Qt.rgba(0, 0, 0, 0.6)
        }

        contentItem: Column {
            width: popup.width
            spacing: 4
            topPadding: 8
            leftPadding: 8
            rightPadding: 8
            bottomPadding: 8

            // Reverse action — pinned at top
            Rectangle {
                width: popup.width - 16
                height: 36
                radius: 6
                property bool hovered: false
                color: hovered ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(1, 1, 1, 0.04)
                Behavior on color { ColorAnimation { duration: 100 } }

                Row {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: "⇵"
                        font.pixelSize: 13
                        color: queueSortMenu.accentColor
                    }
                    Text {
                        text: "Reverse current order"
                        font.pixelSize: 12
                        color: queueSortMenu.primaryText
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onEntered: parent.hovered = true
                    onExited:  parent.hovered = false
                    onClicked: {
                        player.reverseActiveQueue()
                        popup.close()
                    }
                }
            }

            // Asc / Desc toggle
            Item {
                width: popup.width - 16
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
                            property bool selected: queueSortMenu.pendingAscending === modelData.value
                            color: selected
                                   ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.2)
                                   : Qt.rgba(1, 1, 1, 0.06)

                            Text {
                                anchors.centerIn: parent
                                text: modelData.label
                                font.pixelSize: 11
                                color: parent.selected
                                       ? queueSortMenu.accentColor
                                       : queueSortMenu.mutedText
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: queueSortMenu.pendingAscending = modelData.value
                            }
                        }
                    }
                }
            }

            Rectangle {
                width: popup.width - 16
                height: 1
                color: Qt.rgba(1, 1, 1, 0.06)
            }

            // Sort key options — scrollable
            Flickable {
                width: popup.width - 16
                height: popup.height - 44 - 36 - 1 - 24
                contentHeight: optionsColumn.implicitHeight
                clip: true

                Column {
                    id: optionsColumn
                    width: parent.width
                    spacing: 2

                    Repeater {
                        model: queueSortMenu.sortOptions

                        Rectangle {
                            width: optionsColumn.width
                            height: 36
                            radius: 6
                            property bool hovered: false

                            color: hovered ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(1, 1, 1, 0.04)
                            Behavior on color { ColorAnimation { duration: 100 } }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                text: modelData.label
                                font.pixelSize: 12
                                color: queueSortMenu.primaryText
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onEntered: parent.hovered = true
                                onExited:  parent.hovered = false
                                onClicked: {
                                    player.sortActiveQueue(modelData.value, queueSortMenu.pendingAscending)
                                    popup.close()
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    property bool pendingAscending: true
}