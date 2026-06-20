import QtQuick
import QtQuick.Controls

Item {
    id: queueDropdown

    required property var theme

    readonly property color primaryText: theme.primaryText
    readonly property color mutedText:   theme.mutedText
    readonly property color accentColor: theme.accentColor

    property int    renamingIndex: -1
    property string renameBuffer:  ""

    property int  dragFromIndex:    -1
    property int  dragToIndex:      -1
    property bool dragProxyVisible: false
    property real dragProxyY:       0

    function open()  { popup.open()  }
    function close() { popup.close() }

    Popup {
        id: popup
        modal: true
        focus: true
        anchors.centerIn: Overlay.overlay
        width: 280
        height: Math.min(player.queueCount * 56 + 64, 420)
        padding: 0

        background: Rectangle {
            radius: 12
            color: queueDropdown.theme.bgColor
            border.color: Qt.rgba(1, 1, 1, 0.1)
            border.width: 1
        }

        Overlay.modal: Rectangle {
            color: Qt.rgba(0, 0, 0, 0.6)
        }

        contentItem: Column {
            width: popup.width
            spacing: 4
            topPadding: 8
            bottomPadding: 8
            leftPadding: 8
            rightPadding: 8

            // Header
            Item {
                width: popup.width - 16
                height: 32

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Queues"
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    color: queueDropdown.mutedText
                    leftPadding: 4
                }
            }

            Rectangle {
                width: popup.width - 16
                height: 1
                color: Qt.rgba(1, 1, 1, 0.06)
            }

            // Queue list
            ListView {
                id: queueList
                width: popup.width - 16
                height: popup.height - 64
                spacing: 4
                clip: false
                model: player.queueCount
                interactive: queueDropdown.dragFromIndex < 0

                delegate: Item {
                    id: queueItemRoot
                    width: queueList.width
                    height: 52

                    property var dropdown: queueDropdown
                    property bool isRenaming: dropdown.renamingIndex === index
                    property bool isDragging: dropdown.dragFromIndex === index

                    opacity: isDragging ? 0.5 : 1.0
                    scale:   isDragging ? 1.02 : 1.0

                    Behavior on opacity { NumberAnimation { duration: 100 } }
                    Behavior on scale   { NumberAnimation { duration: 100 } }

                    Rectangle {
                        anchors.fill: parent
                        radius: 8
                        color: index === player.activeQueueIndex
                               ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.15)
                               : Qt.rgba(1, 1, 1, 0.04)
                    }

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 6
                        anchors.rightMargin: 10
                        spacing: 0

                        // Drag handle
                        Item {
                            width: 28
                            height: parent.height

                            Text {
                                text: "⠿"
                                font.pixelSize: 16
                                color: queueItemRoot.dropdown.mutedText
                                anchors.centerIn: parent
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.SizeVerCursor
                                preventStealing: true

                                onPressed: function(mouse) {
                                    mouse.accepted = true
                                    let mapped = mapToItem(null, mouse.x, mouse.y)
                                    queueItemRoot.dropdown.dragFromIndex    = index
                                    queueItemRoot.dropdown.dragToIndex      = index
                                    queueItemRoot.dropdown.dragProxyY       = mapped.y - queueList.y - 26
                                    queueItemRoot.dropdown.dragProxyVisible = true
                                }

                                onPositionChanged: function(mouse) {
                                    let mapped = mapToItem(null, mouse.x, mouse.y)
                                    let localY = mapped.y - queueList.y
                                    queueItemRoot.dropdown.dragProxyY = localY - 26

                                    let newIndex = Math.floor((localY + queueList.contentY) / 56)
                                    newIndex = Math.max(0, Math.min(newIndex, player.queueCount - 1))
                                    queueItemRoot.dropdown.dragToIndex = newIndex
                                }

                                onReleased: {
                                    if (queueItemRoot.dropdown.dragFromIndex >= 0 &&
                                        queueItemRoot.dropdown.dragToIndex >= 0 &&
                                        queueItemRoot.dropdown.dragFromIndex !== queueItemRoot.dropdown.dragToIndex) {
                                        player.moveQueue(
                                            queueItemRoot.dropdown.dragFromIndex,
                                            queueItemRoot.dropdown.dragToIndex)
                                    }
                                    queueItemRoot.dropdown.dragProxyVisible = false
                                    queueItemRoot.dropdown.dragFromIndex    = -1
                                    queueItemRoot.dropdown.dragToIndex      = -1
                                }
                            }
                        }

                        // Radio button
                        Item {
                            width: 28
                            height: parent.height

                            Rectangle {
                                anchors.centerIn: parent
                                width: 18
                                height: 18
                                radius: 9
                                color: "transparent"
                                border.color: index === player.activeQueueIndex
                                              ? queueItemRoot.dropdown.accentColor
                                              : queueItemRoot.dropdown.mutedText
                                border.width: 2

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 10
                                    height: 10
                                    radius: 5
                                    color: queueItemRoot.dropdown.accentColor
                                    visible: index === player.activeQueueIndex
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    player.switchToQueue(index)
                                    queueDropdown.close()
                                }
                            }
                        }

                        // Name / rename field
                        Item {
                            width: parent.width - 28 - 28 - 24 - 24
                            height: parent.height

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width
                                text: player.queueNames[index]
                                font.pixelSize: 12
                                color: index === player.activeQueueIndex
                                       ? queueItemRoot.dropdown.accentColor
                                       : queueItemRoot.dropdown.primaryText
                                elide: Text.ElideRight
                                visible: !queueItemRoot.isRenaming
                            }

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width
                                height: 28
                                radius: 6
                                color: Qt.rgba(1, 1, 1, 0.08)
                                visible: queueItemRoot.isRenaming

                                TextInput {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    verticalAlignment: TextInput.AlignVCenter
                                    text: queueItemRoot.dropdown.renameBuffer
                                    font.pixelSize: 12
                                    color: queueItemRoot.dropdown.primaryText
                                    selectByMouse: true
                                    focus: queueItemRoot.isRenaming

                                    onTextChanged: queueItemRoot.dropdown.renameBuffer = text

                                    onAccepted: {
                                        if (queueItemRoot.dropdown.renameBuffer.trim().length > 0)
                                            player.renameQueue(index, queueItemRoot.dropdown.renameBuffer.trim())
                                        queueItemRoot.dropdown.renamingIndex = -1
                                    }

                                    onActiveFocusChanged: {
                                        if (!activeFocus && queueItemRoot.isRenaming) {
                                            if (queueItemRoot.dropdown.renameBuffer.trim().length > 0)
                                                player.renameQueue(index, queueItemRoot.dropdown.renameBuffer.trim())
                                            queueItemRoot.dropdown.renamingIndex = -1
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                enabled: !queueItemRoot.isRenaming
                                onClicked: {
                                    player.switchToQueue(index)
                                    queueDropdown.close()
                                }
                            }
                        }

                        // Pencil button
                        Item {
                            width: 24
                            height: parent.height

                            Text {
                                text: "✎"
                                font.pixelSize: 13
                                color: queueItemRoot.dropdown.mutedText
                                anchors.centerIn: parent
                                visible: !queueItemRoot.isRenaming
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    queueItemRoot.dropdown.renamingIndex = index
                                    queueItemRoot.dropdown.renameBuffer = player.queueNames[index]
                                }
                            }
                        }

                        // Remove button
                        Item {
                            width: 24
                            height: parent.height

                            Text {
                                text: "✕"
                                font.pixelSize: 11
                                color: queueItemRoot.dropdown.mutedText
                                anchors.centerIn: parent
                                visible: !queueItemRoot.isRenaming
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: player.closeQueue(index)
                            }
                        }
                    }
                }
            }
        }
    }

    // Drag proxy
    Rectangle {
        x: 8
        y: queueDropdown.dragProxyY
        width: 264
        height: 52
        radius: 8
        visible: queueDropdown.dragProxyVisible
        opacity: 0.85
        z: 20
        parent: popup.contentItem

        color: Qt.rgba(queueDropdown.accentColor.r, queueDropdown.accentColor.g,
                       queueDropdown.accentColor.b, 0.25)
        border.color: Qt.rgba(queueDropdown.accentColor.r, queueDropdown.accentColor.g,
                              queueDropdown.accentColor.b, 0.5)
        border.width: 1

        Text {
            anchors.centerIn: parent
            text: {
                let idx = queueDropdown.dragFromIndex
                let names = player.queueNames
                if (idx >= 0 && names && idx < names.length)
                    return names[idx]
                return ""
            }
            font.pixelSize: 12
            color: queueDropdown.primaryText
            elide: Text.ElideRight
            width: parent.width - 24
            horizontalAlignment: Text.AlignHCenter
        }
    }
}