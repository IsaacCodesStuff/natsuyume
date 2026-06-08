import QtQuick
import QtQuick.Effects

Item {
    id: queueDropdown

    required property var theme

    readonly property color bgColor:     theme.bgColor
    readonly property color primaryText: theme.primaryText
    readonly property color mutedText:   theme.mutedText
    readonly property color accentColor: theme.accentColor

    property int    renamingIndex: -1
    property string renameBuffer:  ""

    signal closeRequested

    Rectangle {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        radius: 10
        color: queueDropdown.bgColor
        border.color: Qt.rgba(1, 1, 1, 0.08)
        border.width: 1

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, 0.4)
            shadowVerticalOffset: 4
            shadowBlur: 0.6
        }

        Column {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 4

            // ── Header ─────────────────────────────────────────
            Item {
                width: parent.width
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

            // ── Queue list ─────────────────────────────────────
            ListView {
                id: queueList
                width: parent.width
                height: parent.height - 40
                spacing: 4
                clip: true
                model: player.queueNames

                delegate: Rectangle {
                    id: queueItem
                    width: queueList.width
                    height: 44
                    radius: 8
                    color: index === player.activeQueueIndex
                           ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.15)
                           : Qt.rgba(1, 1, 1, 0.04)

                    property bool isRenaming: queueDropdown.renamingIndex === index

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 6

                        Item {
                            width: parent.width - 28
                            height: parent.height

                            // Normal label
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width
                                text: modelData
                                font.pixelSize: 12
                                color: index === player.activeQueueIndex
                                       ? queueDropdown.accentColor
                                       : queueDropdown.primaryText
                                elide: Text.ElideRight
                                visible: !queueItem.isRenaming

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        player.switchToQueue(index)
                                        queueDropdown.closeRequested()
                                    }
                                    onDoubleClicked: {
                                        queueDropdown.renamingIndex = index
                                        queueDropdown.renameBuffer = modelData
                                    }
                                }
                            }

                            // Inline rename field
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width
                                height: 28
                                radius: 6
                                color: Qt.rgba(1, 1, 1, 0.08)
                                visible: queueItem.isRenaming

                                TextInput {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    verticalAlignment: TextInput.AlignVCenter
                                    text: queueDropdown.renameBuffer
                                    font.pixelSize: 12
                                    color: queueDropdown.primaryText
                                    selectByMouse: true
                                    focus: queueItem.isRenaming

                                    onTextChanged: queueDropdown.renameBuffer = text

                                    onAccepted: {
                                        if (queueDropdown.renameBuffer.trim().length > 0)
                                            player.renameQueue(index, queueDropdown.renameBuffer.trim())
                                        queueDropdown.renamingIndex = -1
                                    }

                                    onActiveFocusChanged: {
                                        if (!activeFocus && queueItem.isRenaming) {
                                            if (queueDropdown.renameBuffer.trim().length > 0)
                                                player.renameQueue(index, queueDropdown.renameBuffer.trim())
                                            queueDropdown.renamingIndex = -1
                                        }
                                    }
                                }
                            }
                        }

                        // Remove button
                        Text {
                            text: "✕"
                            font.pixelSize: 11
                            color: queueDropdown.mutedText
                            anchors.verticalCenter: parent.verticalCenter
                            visible: !queueItem.isRenaming

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
}