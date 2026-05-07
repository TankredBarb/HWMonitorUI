import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls.Basic 2.15
import QtQuick.Layouts 1.15

Window {
    id: mainWindow
    visible: true
    title: "Qt Hardware Monitor"
    color: "#E8E8E8"

    width: 385
    height: 530

    property var hardwareInfo: ({})
    property var sensors: []
    property int connectionState: 0
    property string connectionStatusText: "Disconnected"

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
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            visible: connectionState === 2
            ScrollBar.vertical.policy: ScrollBar.AsNeeded

            GridLayout {
                width: parent.width
                columns: 2
                rowSpacing: 10
                columnSpacing: 10
                Layout.fillWidth: true

                Repeater {
                    model: sensors

                    delegate: SensorCard {
                        sensorData: modelData
                        onClicked: {
                            sensorEditorPopup.openDialog(modelData)
                        }
                    }
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
            font.pixelSize: 14
            font.weight: Font.Medium
            visible: connectionState !== 2
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignBottom
            spacing: 8

            Item { Layout.fillWidth: true }

            Rectangle {
                id: connectionIndicator
                implicitWidth: 10
                implicitHeight: 10
                radius: 5
                color: {
                    if (connectionState === 0) return "#9E9E9E";
                    if (connectionState === 1) return "#FFA000";
                    if (connectionState === 2) return "#4CAF50";
                    return "#F44336";
                }
                visible: connectionState === 2
            }

            Text {
                text: connectionStatusText
                font.family: "Segoe UI"
                font.pixelSize: 14
                color: {
                    if (connectionState === 0) return "#9E9E9E";
                    if (connectionState === 1) return "#FFA000";
                    if (connectionState === 2) return "#4CAF50";
                    return "#F44336";
                }
                font.weight: Font.Bold
                Layout.alignment: Qt.AlignVCenter
                visible: connectionState === 2
            }

            Button {
                visible: connectionState === 0 || connectionState === 3
                text: "Reconnect"
                font.family: "Segoe UI"
                font.pixelSize: 11
                Layout.alignment: Qt.AlignVCenter
                background: Rectangle {
                    color: parent.pressed ? "#1565C0" : "#1976D2"
                    radius: 4
                    implicitWidth: 70
                    implicitHeight: 24
                }
                contentItem: Text {
                    text: parent.text
                    color: "#FFFFFF"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: {
                    mainWindow.reconnect();
                }
            }
        }

        Item {
            Layout.fillHeight: true
            visible: connectionState === 2
        }
    }

    SensorEditorPopup {
        id: sensorEditorPopup
        onSaveRequested: {
            if (sensorEditorPopup.currentSensor) {
                var newName = sensorEditorPopup.currentInputText.trim();
                sensorNameManager.saveSensorName(sensorEditorPopup.currentSensor.id, newName);
                console.log("Saved custom name:", newName, "for unique ID:", sensorEditorPopup.currentSensor.id);
                sensorEditorPopup.close();
            }
        }
    }
}