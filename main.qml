import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls.Basic 2.15
import QtQuick.Layouts 1.15

Window {
    id: mainWindow
    visible: true
    title: "Qt Hardware Monitor"
    color: "#E5E9F0" // Более глубокий серо-голубой для контраста на ярких мониторах

    width: Math.max(320, Math.min(Screen.width * 0.2, 450))
    height: Math.max(480, Math.min(Screen.height * 0.53, 700))

    property bool isTransparent: false
    property real transparencyValue: 0.5
    opacity: isTransparent ? (mouseInteraction.containsMouse ? 0.8 : transparencyValue) : 1.0

    Behavior on opacity {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }

    property var hardwareInfo: ({})
    property int connectionState: 0
    property string connectionStatusText: "Disconnected"
    property int gridSpacing: 10

    property bool isOverlay: false
    property int oldX: x
    property int oldY: y
    property int oldWidth: width
    property int oldHeight: height

    Timer {
        id: restoreTimer
        interval: 50
        repeat: false
        onTriggered: {
            mainWindow.x = mainWindow.oldX
            mainWindow.y = mainWindow.oldY
            mainWindow.width = mainWindow.oldWidth
            mainWindow.height = mainWindow.oldHeight
        }
    }

    MouseArea {
        id: mouseInteraction
        anchors.fill: parent
        hoverEnabled: true
        enabled: mainWindow.isOverlay
        property point lastMousePos: Qt.point(0, 0)
        onPressed: (mouse) => { lastMousePos = Qt.point(mouse.x, mouse.y) }
        onPositionChanged: (mouse) => {
            if (pressed) {
                var delta = Qt.point(mouse.x - lastMousePos.x, mouse.y - lastMousePos.y)
                mainWindow.x += delta.x
                mainWindow.y += delta.y
            }
        }
    }

    function reconnect() {
        console.log("Reconnecting...");
        reconnectClicked();
    }

    signal reconnectClicked()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        HardwareInfoCard {
            visible: connectionState === 2
            hardwareInfo: mainWindow.hardwareInfo
            Layout.fillWidth: true
            opacity: mainWindow.isTransparent ? 0.4 : 1.0
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            visible: connectionState === 2
            ScrollBar.vertical.policy: ScrollBar.AsNeeded

            GridView {
                id: sensorGrid
                anchors.fill: parent
                cellWidth: (sensorGrid.width - mainWindow.gridSpacing) / 2
                cellHeight: 85
                model: sensorModel
                cacheBuffer: 1000
                reuseItems: true
                delegate: SensorCard {
                    width: sensorGrid.cellWidth
                    height: sensorGrid.cellHeight
                    sensorData: model.sensorData
                    onClicked: sensorEditorPopup.openDialog(model.sensorData)
                }
            }
        }

        Text {
            Layout.alignment: Qt.AlignCenter
            Layout.fillWidth: true
            text: {
                if (connectionState === 3) return "Connection Error - hwmonitor may not be running";
                if (connectionState === 0) return "Disconnected - Click Reconnect to try again";
                if (connectionState === 1) return "Connecting...";
                return "";
            }
            color: connectionState === 3 ? "#F44336" : (connectionState === 0 ? "#9E9E9E" : "#FFA000")
            font.pixelSize: 13
            font.weight: Font.Medium
            visible: connectionState !== 2
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignBottom
            spacing: 8

            AbstractButton {
                id: overlayButton
                hoverEnabled: true
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34
                ToolTip.visible: hovered
                ToolTip.text: mainWindow.isOverlay ? "Restore" : "Always on top"

                contentItem: Item {
                    Rectangle {
                        anchors.centerIn: parent
                        width: 12; height: 12; radius: 2; color: "transparent"
                        border.color: mainWindow.isOverlay ? "#007AFF" : "#666666"
                        border.width: 2; rotation: mainWindow.isOverlay ? 0 : 45
                        Behavior on rotation { NumberAnimation { duration: 200 } }
                        Rectangle {
                            anchors.top: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter
                            width: 2; height: 5; color: parent.border.color
                        }
                    }
                }
                background: Rectangle {
                    radius: 6
                    color: parent.pressed ? "#E0E0E0" : (parent.hovered ? "#F0F0F0" : "transparent")
                    border.color: mainWindow.isOverlay ? "#007AFF" : "transparent"
                }
                onClicked: {
                    if (!mainWindow.isOverlay) {
                        mainWindow.oldX = mainWindow.x; mainWindow.oldY = mainWindow.y
                        mainWindow.oldWidth = mainWindow.width; mainWindow.oldHeight = mainWindow.height
                        mainWindow.isOverlay = true
                        mainWindow.flags = Qt.Window | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
                    } else {
                        mainWindow.isOverlay = false
                        mainWindow.flags = Qt.Window
                        restoreTimer.start()
                    }
                }
            }

            AbstractButton {
                id: transButton
                hoverEnabled: true
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34
                ToolTip.visible: hovered
                ToolTip.text: mainWindow.isTransparent ? "Make opaque" : "Make transparent"

                contentItem: Item {
                    Rectangle {
                        anchors.centerIn: parent
                        width: 14; height: 14; radius: 7
                        color: "transparent"
                        border.color: mainWindow.isTransparent ? "#007AFF" : "#666666"
                        border.width: 2

                        Rectangle {
                            anchors.centerIn: parent
                            width: 4; height: 4; radius: 2
                            color: parent.border.color
                            visible: mainWindow.isTransparent
                        }
                    }
                }
                background: Rectangle {
                    radius: 6
                    color: parent.pressed ? "#E0E0E0" : (parent.hovered ? "#F0F0F0" : "transparent")
                    border.color: mainWindow.isTransparent ? "#007AFF" : "transparent"
                }
                onClicked: mainWindow.isTransparent = !mainWindow.isTransparent
            }

            Item { Layout.fillWidth: true }

            RowLayout {
                spacing: 8
                visible: connectionState === 2
                opacity: (mainWindow.isOverlay || mainWindow.isTransparent) ? 0.5 : 1.0
                Rectangle { width: 8; height: 8; radius: 4; color: "#4CAF50" }
                Text {
                    text: connectionStatusText
                    font.pixelSize: 12; font.weight: Font.DemiBold; color: "#555555"
                    visible: !mainWindow.isOverlay
                }
            }

            Button {
                visible: (connectionState === 0 || connectionState === 3) && !mainWindow.isOverlay
                text: "Reconnect"
                font.pixelSize: 11
                contentItem: Text { text: parent.text; color: "white"; font.weight: Font.Bold; horizontalAlignment: Text.AlignHCenter }
                background: Rectangle { color: parent.pressed ? "#005BBF" : "#007AFF"; radius: 6; implicitWidth: 80; implicitHeight: 28 }
                onClicked: mainWindow.reconnect()
            }
        }

        Item { Layout.fillHeight: true; visible: connectionState === 2 }
    }

    SensorEditorPopup {
        id: sensorEditorPopup
        onSaveRequested: (name, color, isBold) => {
            if (sensorEditorPopup.currentSensor) {
                sensorNameManager.saveSensorConfig(sensorEditorPopup.currentSensor.id, name.trim(), color, isBold);
                sensorEditorPopup.close();
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                contextMenu.popup()
            }
        }
    }

    Menu {
        id: contextMenu
        
        background: Rectangle {
            implicitWidth: 180
            implicitHeight: 70
            color: "white"
            radius: 12
            border.color: "#B0B0B0"
            border.width: 1
        }

        contentItem: ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Transparency"
                    font.family: "Segoe UI"
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    color: "#666666"
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: Math.round(mainWindow.transparencyValue * 100) + "%"
                    font.family: "Consolas, Monaco, monospace"
                    font.pixelSize: 12
                    font.weight: Font.Bold
                    color: "#007AFF"
                }
            }

            Slider {
                Layout.fillWidth: true
                Layout.preferredHeight: 20
                from: 0.1
                to: 1.0
                value: mainWindow.transparencyValue
                onMoved: mainWindow.transparencyValue = value
                
                background: Rectangle {
                    x: parent.leftPadding
                    y: parent.topPadding + parent.availableHeight / 2 - height / 2
                    implicitWidth: 200
                    implicitHeight: 4
                    width: parent.availableWidth
                    height: implicitHeight
                    radius: 2
                    color: "#E0E0E0"

                    Rectangle {
                        width: parent.parent.visualPosition * parent.width
                        height: parent.height
                        color: "#007AFF"
                        radius: 2
                    }
                }

                handle: Rectangle {
                    x: parent.leftPadding + parent.visualPosition * (parent.availableWidth - width)
                    y: parent.topPadding + parent.availableHeight / 2 - height / 2
                    implicitWidth: 16
                    implicitHeight: 16
                    radius: 8
                    color: parent.pressed ? "#F0F0F0" : "#FFFFFF"
                    border.color: "#007AFF"
                    border.width: 2
                }
            }
        }
    }
    }