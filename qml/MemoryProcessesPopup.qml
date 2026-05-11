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

    property int colSpacing: 6
    property int pidColWidth: 90
    property int memoryColWidth: 110

    property string totalPercentage: {
        if (appController.totalRamMb > 0) {
            return "(" + (appController.usedRamMb / appController.totalRamMb * 100).toFixed(1) + "%)";
        }
        return "";
    }

    opacity: 0

    Behavior on opacity {
        NumberAnimation { duration: 350; easing.type: Easing.OutCubic }
    }

    Timer {
        id: showTimer
        interval: 20
        onTriggered: root.opacity = 1
    }

    Timer {
        id: closeTimer
        interval: 370
        onTriggered: root.hide()
    }

    function open() {
        root.x = mainWindow.x + (mainWindow.width - root.width) / 2
        root.y = mainWindow.y + (mainWindow.height - root.height) / 2
        root.show()
        root.requestActivate()
        if (root.opacity === 0)
            showTimer.start()
        else
            root.opacity = 1
    }

    function close() {
        showTimer.stop()
        closeTimer.stop()
        for (var i = 0; i < processList.count; i++) {
            var item = processList.itemAtIndex(i)
            if (item && item.expanded)
                item.expanded = false
        }
        root.opacity = 0
        closeTimer.start()
    }

    property string lastUpdateTime: ""

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

        DragHandler {
            target: null
            acceptedButtons: Qt.LeftButton
            onActiveChanged: {
                if (active) root.startSystemMove()
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
                    color: "#F4F3FF"
                    border.color: "#7C3AED"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "RAM"
                        font.family: "Segoe UI"
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        color: "#7C3AED"
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "Memory Usage"
                            font.family: "Segoe UI"
                            font.pixelSize: 15
                            font.weight: Font.Bold
                            color: "#1F2937"
                        }
                        Item { Layout.fillWidth: true }
                        Rectangle {
                            Layout.preferredHeight: 22
                            Layout.preferredWidth: 140
                            color: "#e3d3ea"
                            radius: 11
                            Text {
                                anchors.centerIn: parent
                                text: (appController.usedRamMb / 1024).toFixed(1) + " GB " + root.totalPercentage
                                font.pixelSize: 11
                                font.weight: Font.Bold
                                color: "#6D28D9"

                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            Layout.fillWidth: true
                            text: "Sorted by Working Set (descending)"
                            font.family: "Segoe UI"
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            color: "#667085"
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Total WS (private + shared); Task Manager shows private only"
                            font.family: "Segoe UI"
                            font.pixelSize: 10
                            font.weight: Font.Normal
                            color: "#98A2B3"
                            elide: Text.ElideRight
                        }
                    }
                }

                Button {
                    id: refreshButton
                    text: "Refresh"
                    Layout.preferredWidth: 92
                    implicitHeight: 32
                    Layout.alignment: Qt.AlignTop
                    Layout.topMargin: 2
                    onClicked: {
                        root.lastUpdateTime = new Date().toLocaleTimeString(Qt.locale(), "HH:mm:ss")
                        for (var i = 0; i < processList.count; i++) {
                            var item = processList.itemAtIndex(i)
                            if (item && item.expanded)
                                item.expanded = false
                        }
                        appController.refreshMemoryProcesses()
                    }

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
                        color: refreshButton.pressed ? "#5B21B6" : (refreshButton.hovered ? "#6D28D9" : "#7C3AED")
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
                            anchors.leftMargin: 12
                            anchors.rightMargin: 10
                            spacing: root.colSpacing

                            property int processColWidth: Math.max(
                                60,
                                width - root.pidColWidth - root.memoryColWidth - root.colSpacing * 2
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
                            Text { width: root.memoryColWidth; text: "Memory"; font.family: "Consolas"; font.pixelSize: 11; font.weight: Font.Bold; color: "#7C3AED" }
                        }
                    }

                    ListView {
                        id: processList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 2
                        focus: true
                        model: appController.memoryProcesses

                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AsNeeded
                            width: 6
                            background: Rectangle { color: "transparent" }
                            contentItem: Rectangle { radius: 2; color: "#CBD5E1" }
                        }

                        delegate: Item {
                            width: processList.width
                            height: headerRect.height + (expanded ? contentArea.height + 2 : 0)

                            property bool expanded: false
                            property bool hasMultiPids: modelData.pids && modelData.pids.length > 1

                            onExpandedChanged: appController.notifyExpandedChanged(expanded ? 1 : -1)
                            Component.onDestruction: { if (expanded) appController.notifyExpandedChanged(-1) }

                            Rectangle {
                                id: headerRect
                                width: parent.width
                                height: 28
                                radius: 6
                                property bool hovered: false
                                    color: expanded ? "#F4F0F9" : (hovered ? "#DDD6FE" : (index % 2 === 0 ? "#FCFDFF" : "#F8FAFC"))
                                border.color: expanded ? "#7C3AED" : "#EEF2F6"
                                border.width: 1

                                Row {
                                    id: dataRow
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 10
                                    spacing: root.colSpacing

                                    property int processColWidth: Math.max(
                                        60,
                                        width - 16 - root.pidColWidth - root.memoryColWidth - root.colSpacing * 3
                                    )
                                    Image {
                                        width: 16
                                        height: 16
                                        source: "image://processicon/" + modelData.name
                                        fillMode: Image.PreserveAspectFit
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Text {
                                        text: modelData.name || "-"
                                        width: dataRow.processColWidth
                                        font.family: "Segoe UI"
                                        font.pixelSize: 11
                                        font.weight: hasMultiPids ? Font.DemiBold : Font.Medium
                                        color: "#1F2937"
                                        elide: Text.ElideRight
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Text {
                                        text: modelData.id || "-"
                                        width: root.pidColWidth
                                        font.family: "Consolas"
                                        font.pixelSize: 11
                                        color: "#344054"
                                        anchors.verticalCenter: parent.verticalCenter
                                        elide: Text.ElideRight
                                    }
                                    Column {
                                        width: root.memoryColWidth
                                        height: parent.height
                                        spacing: 0
                                        clip: true

                                        Text {
                                            width: parent.width
                                            text: Number(modelData.wsMb || 0).toFixed(1)
                                            font.family: "Consolas"
                                            font.pixelSize: 11
                                            color: "#7C3AED"
                                            font.weight: Font.Bold
                                            topPadding: 4
                                            elide: Text.ElideRight
                                        }

                                        Item { height: 2; width: parent.width }

                                        Rectangle {
                                            anchors.left: parent.left
                                            width: parent.width * 0.85
                                            height: 3
                                            radius: 1.5
                                            color: "#EEF2F6"

                                            Rectangle {
                                                width: parent.width * Math.min(1, (modelData.wsMb || 0) / (appController.totalRamMb || 1))
                                                height: parent.height
                                                radius: parent.radius
                                                color: "#7C3AED"
                                                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                                            }
                                        }
                                    }
                                }

                                Text {
                                    visible: hasMultiPids
                                    anchors.left: parent.left
                                    anchors.leftMargin: 4
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: expanded ? "▼" : "▶"
                                    font.family: "Segoe UI"
                                    font.pixelSize: 9
                                    color: "#667085"
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    acceptedButtons: Qt.LeftButton
                                    cursorShape: hasMultiPids ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    onClicked: {
                                        if (hasMultiPids)
                                            expanded = !expanded
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.NoButton
                                    onEntered: headerRect.hovered = true
                                    onExited: headerRect.hovered = false
                                }
                            }

                            Rectangle {
                                id: contentArea
                                anchors.top: headerRect.bottom
                                anchors.topMargin: 1
                                anchors.left: parent.left
                                anchors.right: parent.right
                                height: expanded ? contentColumn.height + 6 : 0
                                clip: true
                                radius: 4
                                color: "#FAFBFC"
                                border.color: "#E5E9F0"
                                border.width: 1
                                visible: hasMultiPids && (expanded || height > 0)

                                Behavior on height {
                                    NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                                }

                                Column {
                                    id: contentColumn
                                    x: 24
                                    y: 3
                                    width: parent.width - 30
                                    spacing: 1
                                    Repeater {
                                        model: modelData.pids
                                        Row {
                                            width: parent.width
                                            spacing: root.colSpacing

                                            property int pidWidth: 90
                                            property int memoryWidth: 85

                                            Text {
                                                width: parent.pidWidth
                                                text: Number(modelData.pid)
                                                font.family: "Consolas"
                                                font.pixelSize: 10
                                                color: "#475467"
                                                elide: Text.ElideRight
                                            }
                                            Text {
                                                width: parent.memoryWidth
                                                text: Number(modelData.wsMb).toFixed(1)
                                                font.family: "Consolas"
                                                font.pixelSize: 10
                                                font.weight: Font.Bold
                                                color: "#7C3AED"
                                                elide: Text.ElideRight
                                            }
                                        }
                                    }
                                    }
                                }
                            }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                Layout.topMargin: 2

                Text {
                    text: processList.count + " processes"
                    font.family: "Segoe UI"
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    color: "#667085"
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: root.lastUpdateTime ? "Updated " + root.lastUpdateTime : ""
                    font.family: "Segoe UI"
                    font.pixelSize: 11
                    color: "#98A2B3"
                    visible: root.lastUpdateTime !== ""
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
