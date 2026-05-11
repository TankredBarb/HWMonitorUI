import QtQuick 2.15
import QtQuick.Controls.Basic 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15

Window {
    id: root

    width: 650
    height: 550
    flags: Qt.Window | Qt.FramelessWindowHint | Qt.Dialog
    color: "transparent"
    visible: false

    property int colSpacing: 12
    property int pidColWidth: 70
    property int cpuColWidth: 75
    property int wsColWidth: 90
    property int pmColWidth: 90

    property real totalCpu: {
        let total = 0;
        for (let i = 0; i < appController.cpuProcesses.length; i++) {
            total += appController.cpuProcesses[i].cpu;
        }
        return total;
    }

    function open() {
        // Center relative to main window on screen
        root.x = mainWindow.x + (mainWindow.width - root.width) / 2
        root.y = mainWindow.y + (mainWindow.height - root.height) / 2
        root.show()
        root.requestActivate()
    }

    function close() {
        root.hide()
    }

    Shortcut {
        sequence: "Escape"
        onActivated: root.close()
    }

    // Background and Drag Handling
    Rectangle {
        anchors.fill: parent
        color: "#E5E9F0"
        radius: 8
        border.color: "#D9DEE7"
        border.width: 1

        MouseArea {
            anchors.fill: parent
            property point lastMousePos: Qt.point(0, 0)
            acceptedButtons: Qt.LeftButton
            
            onPressed: (mouse) => {
                lastMousePos = Qt.point(mouse.x, mouse.y)
            }
            
            onPositionChanged: (mouse) => {
                if (pressed) {
                    let delta = Qt.point(mouse.x - lastMousePos.x, mouse.y - lastMousePos.y)
                    root.x += delta.x
                    root.y += delta.y
                }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    Layout.preferredWidth: 38
                    Layout.preferredHeight: 38
                    radius: 8
                    color: "#EFF8FF"
                    border.color: "#2F80ED"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "CPU"
                        font.family: "Segoe UI"
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        color: "#2F80ED"
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "Windows Processes"
                            font.family: "Segoe UI"
                            font.pixelSize: 15
                            font.weight: Font.Bold
                            color: "#1F2937"
                        }
                        Item { Layout.fillWidth: true }
                        Rectangle {
                            Layout.preferredHeight: 22
                            Layout.preferredWidth: 80
                            color: "#E0F2FE"
                            radius: 11
                            Text {
                                anchors.centerIn: parent
                                text: root.totalCpu.toFixed(1) + "% Total"
                                font.pixelSize: 11
                                font.weight: Font.Bold
                                color: "#0369A1"
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "Sorted by CPU usage (descending)"
                        font.family: "Segoe UI"
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: "#667085"
                        elide: Text.ElideRight
                    }
                }

                Button {
                    id: refreshButton
                    text: "Refresh"
                    Layout.preferredWidth: 92
                    implicitHeight: 32
                    onClicked: appController.refreshCpuProcesses()

                    contentItem: Text {
                        text: refreshButton.text
                        color: "#FFFFFF"
                        font.family: "Segoe UI"
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        radius: 8
                        color: refreshButton.pressed ? "#005BBF" : (refreshButton.hovered ? "#1677FF" : "#007AFF")
                        Behavior on color { ColorAnimation { duration: 140 } }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: "#EEF2F6"
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 8
                color: "#FFFFFF"
                border.color: "#D9DEE7"
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 6

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 26
                        radius: 6
                        color: "#F8FAFC"
                        border.color: "#D9DEE7"
                        border.width: 1

                        Row {
                            id: headerRow
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: root.colSpacing

                            property int processColWidth: Math.max(
                                100,
                                width - root.pidColWidth - root.cpuColWidth - root.wsColWidth - root.pmColWidth - root.colSpacing * 4
                            )

                            Text {
                                width: headerRow.processColWidth
                                text: "Process"
                                font.family: "Segoe UI"
                                font.pixelSize: 11
                                font.weight: Font.Bold
                                color: "#344054"
                                elide: Text.ElideRight
                            }
                            Text { width: root.pidColWidth; text: "PID"; font.family: "Segoe UI"; font.pixelSize: 11; font.weight: Font.Bold; color: "#344054" }
                            Text { width: root.cpuColWidth; text: "CPU"; font.family: "Consolas"; font.pixelSize: 11; font.weight: Font.Bold; color: "#344054" }
                            Text { width: root.wsColWidth; text: "WS MB"; font.family: "Consolas"; font.pixelSize: 11; font.weight: Font.Bold; color: "#344054" }
                            Text { width: root.pmColWidth; text: "PM MB"; font.family: "Consolas"; font.pixelSize: 11; font.weight: Font.Bold; color: "#344054" }
                        }
                    }

                    ListView {
                        id: processList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 4
                        model: appController.cpuProcesses

                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AsNeeded
                            width: 6
                            background: Rectangle { color: "transparent" }
                            contentItem: Rectangle { radius: 2; color: "#CBD5E1" }
                        }

                        delegate: Rectangle {
                            width: processList.width
                            height: 28
                            radius: 6
                            color: index % 2 === 0 ? "#FCFDFF" : "#F8FAFC"
                            border.color: "#EEF2F6"
                            border.width: 1

                            Row {
                                id: dataRow
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: root.colSpacing

                                property int processColWidth: Math.max(
                                    100,
                                    width - root.pidColWidth - root.cpuColWidth - root.wsColWidth - root.pmColWidth - root.colSpacing * 4
                                )

                                Text {
                                    text: modelData.name || "-"
                                    width: dataRow.processColWidth
                                    font.family: "Segoe UI"
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    color: "#1F2937"
                                    elide: Text.ElideRight
                                }
                                Text {
                                    text: modelData.id || "-"
                                    width: root.pidColWidth
                                    font.family: "Consolas"
                                    font.pixelSize: 11
                                    color: "#344054"
                                }
                                Text {
                                    text: Number(modelData.cpu || 0).toFixed(1)
                                    width: root.cpuColWidth
                                    font.family: "Consolas"
                                    font.pixelSize: 11
                                    color: "#2F80ED"
                                    font.weight: Font.Bold
                                }
                                Text {
                                    text: Number(modelData.wsMb || 0).toFixed(1)
                                    width: root.wsColWidth
                                    font.family: "Consolas"
                                    font.pixelSize: 11
                                    color: "#344054"
                                }
                                Text {
                                    text: Number(modelData.pmMb || 0).toFixed(1)
                                    width: root.pmColWidth
                                    font.family: "Consolas"
                                    font.pixelSize: 11
                                    color: "#344054"
                                }
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Item { Layout.fillWidth: true }

                Button {
                    id: closeButton
                    text: "Close"
                    Layout.preferredWidth: 96
                    implicitHeight: 32
                    onClicked: root.close()

                    contentItem: Text {
                        text: closeButton.text
                        color: closeButton.pressed ? "#D92D20" : (closeButton.hovered ? "#D92D20" : "#475467")
                        font.family: "Segoe UI"
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        color: closeButton.pressed ? "#FEF3F2" : (closeButton.hovered ? "#FEF3F2" : "#FFFFFF")
                        radius: 8
                        border.color: closeButton.hovered ? "#D92D20" : "#D9DEE7"
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 140 } }
                        Behavior on border.color { ColorAnimation { duration: 140 } }
                    }
                }
            }
        }
    }
}
