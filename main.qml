import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls.Basic 2.15
import QtQuick.Layouts 1.15

Window {
    id: mainWindow
    visible: true
    title: "Qt Hardware Monitor"
    color: "#E5E9F0"

    width: Math.max(320, Math.min(Screen.width * 0.2, 1200))
    height: Math.max(480, Math.min(Screen.height * 0.53, 800))

    // --- State Properties ---
    property bool isTransparent: false
    property real transparencyValue: 0.5
    property bool isOverlay: false
    property bool showUpdateFlash: true
    property var hardwareInfo: ({})
    property int connectionState: 0
    property string connectionStatusText: "Disconnected"
    property int gridSpacing: 10

    // --- Window State Helpers ---
    property var normalGeometry: ({ "x": x, "y": y, "width": width, "height": height })

    opacity: isTransparent ? transparencyValue : 1.0

    Behavior on opacity {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }

    // --- Timers & Signals ---
    Timer {
        id: restoreTimer
        interval: 120
        repeat: false
        onTriggered: mainWindow.restoreNormalGeometry()
    }

    signal reconnectClicked()

    function saveNormalGeometry() {
        normalGeometry = {
            "x": mainWindow.x,
            "y": mainWindow.y,
            "width": mainWindow.width,
            "height": mainWindow.height
        }
    }

    function restoreNormalGeometry() {
        mainWindow.x = normalGeometry.x
        mainWindow.y = normalGeometry.y
        mainWindow.width = normalGeometry.width
        mainWindow.height = normalGeometry.height
    }

    // --- Mouse Handling ---
    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: contextMenu.popup()
    }

    DragHandler {
        id: overlayMoveHandler
        enabled: mainWindow.isOverlay
        target: null
        acceptedButtons: Qt.LeftButton

        onActiveChanged: {
            if (active) {
                mainWindow.startSystemMove()
            }
        }
    }

    // --- UI Layout ---
    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16
        opacity: 0
        
        Component.onCompleted: fadeInAnimation.start()
        
        NumberAnimation {
            id: fadeInAnimation
            target: mainLayout
            property: "opacity"
            from: 0
            to: 1
            duration: 800
            easing.type: Easing.OutCubic
        }

        HardwareInfoCard {
            visible: connectionState === 2
            hardwareInfo: mainWindow.hardwareInfo
            Layout.fillWidth: true
            opacity: mainWindow.isTransparent ? 0.4 : 1.0
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }

        GridView {
            id: sensorGrid
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            visible: connectionState === 2
            ScrollBar.vertical: ScrollBar {
                id: sensorScrollBar
                policy: ScrollBar.AsNeeded
                width: 6
                padding: 1

                background: Rectangle {
                    color: "transparent"
                }

                contentItem: Rectangle {
                    implicitWidth: 4
                    radius: 2
                    color: sensorScrollBar.hovered || sensorScrollBar.pressed ? "#94A3B8" : "#CBD5E1"
                    opacity: sensorScrollBar.size < 1.0 ? 1.0 : 0.0
                    Behavior on color { ColorAnimation { duration: 140 } }
                    Behavior on opacity { NumberAnimation { duration: 140 } }
                }
            }
            property int columnCount: 2
            property int rowCount: Math.max(1, Math.ceil(count / columnCount))
            property real dynamicCellHeight: (height - mainWindow.gridSpacing * (rowCount - 1)) / rowCount
            cellWidth: (sensorGrid.width - mainWindow.gridSpacing) / columnCount
            cellHeight: Math.max(85, Math.min(135, dynamicCellHeight))
            model: sensorModel
            cacheBuffer: 1000
            reuseItems: true
            delegate: SensorCard {
                width: sensorGrid.cellWidth
                height: sensorGrid.cellHeight
                sensorData: model.sensorData
                showUpdateFlash: mainWindow.showUpdateFlash
                onClicked: sensorEditorPopup.openDialog(model.sensorData)
                onMiddleClicked: {
                    console.log("Middle clicked sensor: " + model.name + " (ID: " + model.deviceId + ", Type: " + model.type + ")");
                    
                    let nameLC = model.name.toLowerCase();
                    let deviceLC = model.deviceId.toLowerCase();
                    let typeLC = model.type ? model.type.toLowerCase() : "";

                    let isCpu = nameLC.indexOf("cpu") !== -1 || 
                                deviceLC.indexOf("cpu") !== -1 ||
                                (typeLC === "load" && nameLC.indexOf("total") !== -1 && nameLC.indexOf("cpu") !== -1);
                                
                    let isMem = nameLC.indexOf("memory") !== -1 || 
                                deviceLC.indexOf("ram") !== -1 ||
                                deviceLC.indexOf("memory") !== -1 ||
                                (typeLC === "load" && nameLC.indexOf("memory") !== -1);
                    
                    if (isCpu) {
                        cpuProcessesPopup.open()
                    } else if (isMem) {
                        memoryProcessesPopup.open()
                    }
                }
                onDoubleClicked: {
                    // Reserved for future use or kept empty to avoid conflict
                }
            }
        }

        // Connection Status Message
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 72
            visible: connectionState !== 2
            radius: 8
            color: connectionState === 3 ? "#FEF3F2" : (connectionState === 1 ? "#FFFAEB" : "#F8FAFC")
            border.color: connectionState === 3 ? "#D92D20" : (connectionState === 1 ? "#F79009" : "#D9DEE7")
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                Rectangle {
                    Layout.preferredWidth: 8
                    Layout.preferredHeight: 8
                    radius: 4
                    color: connectionState === 3 ? "#D92D20" : (connectionState === 1 ? "#F79009" : "#667085")
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3

                    Text {
                        Layout.fillWidth: true
                        text: connectionState === 3 ? "Connection Error" : (connectionState === 1 ? "Connecting" : "Disconnected")
                        color: connectionState === 3 ? "#D92D20" : (connectionState === 1 ? "#F79009" : "#344054")
                        font.family: "Segoe UI"
                        font.pixelSize: 13
                        font.weight: Font.Bold
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: {
                            if (connectionState === 3) return "hwmonitor may not be running";
                            if (connectionState === 0) return "Use Reconnect to try again";
                            if (connectionState === 1) return "Waiting for sensor data";
                            return "";
                        }
                        color: "#667085"
                        font.family: "Segoe UI"
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                    }
                }
            }
        }

        // Footer Section
        StatusFooter {
            isOverlay: mainWindow.isOverlay
            isTransparent: mainWindow.isTransparent
            showUpdateFlash: mainWindow.showUpdateFlash
            connectionState: mainWindow.connectionState
            connectionStatusText: mainWindow.connectionStatusText
            
            onOverlayToggled: {
                if (!mainWindow.isOverlay) {
                    mainWindow.saveNormalGeometry()
                    mainWindow.isOverlay = true
                    mainWindow.flags = Qt.Window | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
                } else {
                    mainWindow.isOverlay = false
                    mainWindow.flags = Qt.Window
                    restoreTimer.start()
                }
            }
            onTransparencyToggled: mainWindow.isTransparent = !mainWindow.isTransparent
            onUpdateFlashToggled: mainWindow.showUpdateFlash = !mainWindow.showUpdateFlash
            onReconnectClicked: mainWindow.reconnectClicked()
        }

    }

    // --- Sub-components & Popups ---
    SensorEditorPopup {
        id: sensorEditorPopup
        onSaveRequested: (name, color, isBold) => {
            if (sensorEditorPopup.currentSensor) {
                sensorNameManager.saveSensorConfig(sensorEditorPopup.currentSensor.id, name.trim(), color, isBold);
                sensorEditorPopup.close();
            }
        }
    }

    TransparencyMenu {
        id: contextMenu
        transparencyValue: mainWindow.transparencyValue
        onTransparencyValueChanged: mainWindow.transparencyValue = transparencyValue
    }

    ExpertJsonView {
        id: expertJsonView
    }

    Shortcut {
        sequences: ["Ctrl+Shift+J"]
        onActivated: expertJsonView.open()
    }

    CpuProcessesPopup {
        id: cpuProcessesPopup
    }

    MemoryProcessesPopup {
        id: memoryProcessesPopup
    }
}
