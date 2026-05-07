import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls.Basic 2.15
import QtQuick.Layouts 1.15

Window {
    id: mainWindow
    visible: true
    title: "Qt Hardware Monitor"
    color: "#E5E9F0"

    width: Math.max(320, Math.min(Screen.width * 0.2, 450))
    height: Math.max(480, Math.min(Screen.height * 0.53, 700))

    // --- State Properties ---
    property bool isTransparent: false
    property real transparencyValue: 0.5
    property bool isOverlay: false
    property var hardwareInfo: ({})
    property int connectionState: 0
    property string connectionStatusText: "Disconnected"
    property int gridSpacing: 10

    // --- Window State Helpers ---
    property int oldX: x
    property int oldY: y
    property int oldWidth: width
    property int oldHeight: height

    opacity: isTransparent ? (mouseInteraction.containsMouse ? 0.8 : transparencyValue) : 1.0

    Behavior on opacity {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }

    // --- Timers & Signals ---
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

    signal reconnectClicked()

    // --- Mouse Handling ---
    MouseArea {
        id: mouseInteraction
        anchors.fill: parent
        hoverEnabled: true
        enabled: mainWindow.isOverlay
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        
        property point lastMousePos: Qt.point(0, 0)
        
        onPressed: (mouse) => { 
            if (mouse.button === Qt.LeftButton) lastMousePos = Qt.point(mouse.x, mouse.y) 
        }
        
        onPositionChanged: (mouse) => {
            if (pressed && mouse.button === Qt.LeftButton) {
                var delta = Qt.point(mouse.x - lastMousePos.x, mouse.y - lastMousePos.y)
                mainWindow.x += delta.x
                mainWindow.y += delta.y
            }
        }

        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                contextMenu.popup()
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

        // Connection Status Message
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

        // Footer Section
        StatusFooter {
            isOverlay: mainWindow.isOverlay
            isTransparent: mainWindow.isTransparent
            connectionState: mainWindow.connectionState
            connectionStatusText: mainWindow.connectionStatusText
            
            onOverlayToggled: {
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
            onTransparencyToggled: mainWindow.isTransparent = !mainWindow.isTransparent
            onReconnectClicked: mainWindow.reconnectClicked()
        }

        Item { Layout.fillHeight: true; visible: connectionState === 2 }
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
}
