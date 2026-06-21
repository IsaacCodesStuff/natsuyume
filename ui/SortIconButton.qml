import QtQuick
import QtQuick.Controls

Item {
    id: sortIconButton
    width: 36
    height: 36

    required property var   theme
    required property var   sortOptions
    required property int   currentSort
    required property bool  currentAscending

    signal sortChanged(int value, string label)
    signal ascendingChanged(bool ascending)

    readonly property color bgColor:     theme.bgColor
    readonly property color primaryText: theme.primaryText
    readonly property color mutedText:   theme.mutedText
    readonly property color accentColor: theme.accentColor

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: dropdown.opened
               ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.15)
               : Qt.rgba(1, 1, 1, 0.06)

        Behavior on color { ColorAnimation { duration: 100 } }

        Text {
            anchors.centerIn: parent
            text: "≡"
            font.pixelSize: 16
            color: dropdown.opened ? sortIconButton.accentColor : sortIconButton.mutedText
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: dropdown.open()
        }
    }

    Popup {
        id: dropdown
        modal: true
        focus: true
        anchors.centerIn: Overlay.overlay
        width: 280
        height: Math.min(400, 36 + 1 + (sortIconButton.sortOptions.length * 38) + 24)
        padding: 0

        background: Rectangle {
            radius: 10
            color: sortIconButton.bgColor
            border.color: Qt.rgba(1, 1, 1, 0.08)
            border.width: 1
        }

        Overlay.modal: Rectangle {
            color: Qt.rgba(0, 0, 0, 0.6)
        }

        contentItem: Column {
            width: dropdown.width
            spacing: 4
            topPadding: 8
            leftPadding: 8
            rightPadding: 8
            bottomPadding: 8

            Item {
                width: dropdown.width - 16
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
                            color: sortIconButton.currentAscending === modelData.value
                                   ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.2)
                                   : Qt.rgba(1, 1, 1, 0.06)

                            Text {
                                anchors.centerIn: parent
                                text: modelData.label
                                font.pixelSize: 11
                                color: sortIconButton.currentAscending === modelData.value
                                       ? sortIconButton.accentColor
                                       : sortIconButton.mutedText
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    sortIconButton.ascendingChanged(modelData.value)
                                    dropdown.close()
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                width: dropdown.width - 16
                height: 1
                color: Qt.rgba(1, 1, 1, 0.06)
            }

            Flickable {
                width: dropdown.width - 16
                height: dropdown.height - 36 - 1 - 24
                contentHeight: optionsColumn.implicitHeight
                clip: true

                Column {
                    id: optionsColumn
                    width: parent.width
                    spacing: 2

                    Repeater {
                        model: sortIconButton.sortOptions

                        Rectangle {
                            width: optionsColumn.width
                            height: 36
                            radius: 6

                            property bool isActive: sortIconButton.currentSort === modelData.value
                            property bool hovered:  false

                            color: isActive
                                   ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.15)
                                   : hovered
                                     ? Qt.rgba(1, 1, 1, 0.06)
                                     : Qt.rgba(1, 1, 1, 0.04)

                            Behavior on color { ColorAnimation { duration: 100 } }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                text: modelData.label
                                font.pixelSize: 12
                                color: isActive ? sortIconButton.accentColor : sortIconButton.primaryText
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.right: parent.right
                                anchors.rightMargin: 10
                                text: "✓"
                                font.pixelSize: 11
                                color: sortIconButton.accentColor
                                visible: isActive
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onEntered: parent.hovered = true
                                onExited:  parent.hovered = false
                                onClicked: {
                                    sortIconButton.sortChanged(modelData.value, modelData.label)
                                    dropdown.close()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}