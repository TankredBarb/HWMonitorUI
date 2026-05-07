import QtQuick 2.15
import QtQuick.Controls.Basic 2.15
import QtQuick.Layouts 1.15

Popup {
    id: root
    modal: true
    focus: true
    parent: mainWindow.contentItem
    anchors.centerIn: parent
    width: 340
    height: 340
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    property var currentSensor: null
    property string customSensorName: ""
    property alias currentInputText: nameInput.text

    signal saveRequested()

    background: Rectangle {
        color: "#FFFFFF"
        radius: 16
        border.color: "#D0D0D0"
        border.width: 1
    }
    Overlay.modal: Rectangle {
        color: "#80000000"
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Text {
                text: {
                    if (!currentSensor) return "⚡";
                    if (currentSensor.type === "Temperature") return "🌡️";
                    if (currentSensor.type === "Power") return "⚡";
                    if (currentSensor.type === "Load") return "📊";
                    return "⚡";
                }
                font.pixelSize: 28
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: "Edit Sensor Name"
                    font.family: "Segoe UI"
                    font.pixelSize: 16
                    font.weight: Font.Bold
                    color: "#1A1A1A"
                }

                Text {
                    text: currentSensor ? currentSensor.name : ""
                    font.family: "Segoe UI"
                    font.pixelSize: 11
                    color: "#666666"
                    elide: Text.ElideRight
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: "#E0E0E0"
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: "Current Value"
                font.family: "Segoe UI"
                font.pixelSize: 11
                color: "#666666"
            }

            Text {
                text: currentSensor ? (Number(currentSensor.value).toFixed(1) + " " + currentSensor.unit) : "--"
                font.family: "Segoe UI"
                font.pixelSize: 24
                font.weight: Font.Bold
                color: {
                    if (!currentSensor) return "#1A1A1A";
                    if (currentSensor.type === "Temperature" || currentSensor.type === "Load") {
                        if (currentSensor.value > 85) return "#D32F2F";
                        if (currentSensor.value > 70) return "#F57C00";
                        return "#388E3C";
                    }
                    return "#1976D2";
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: "Custom Name"
                font.family: "Segoe UI"
                font.pixelSize: 11
                color: "#666666"
            }

            TextField {
                id: nameInput
                Layout.fillWidth: true
                placeholderText: "Enter custom name (English or Russian)"
                text: root.customSensorName
                font.family: "Segoe UI"
                font.pixelSize: 13
                color: "#1A1A1A"
                selectByMouse: true
                validator: RegularExpressionValidator { regularExpression: /.{0,50}/ }

                background: Rectangle {
                    color: "#FFFFFF"
                    radius: 8
                    border.color: nameInput.activeFocus ? "#1976D2" : "#D0D0D0"
                    border.width: 1
                }

                placeholderTextColor: "#9E9E9E"
                selectionColor: "#1976D2"
                selectedTextColor: "#FFFFFF"

                onAccepted: root.saveRequested()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 8
            spacing: 10

            Item { Layout.fillWidth: true }

            Button {
                text: "Cancel"
                font.family: "Segoe UI"
                font.pixelSize: 12
                implicitWidth: 90
                implicitHeight: 36
                background: Rectangle {
                    color: parent.pressed ? "#E0E0E0" : "#F5F5F5"
                    radius: 8
                    border.color: "#D0D0D0"
                    border.width: 1
                }
                contentItem: Text {
                    text: parent.text
                    color: "#666666"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: root.close()
            }

            Button {
                text: "Save"
                font.family: "Segoe UI"
                font.pixelSize: 12
                implicitWidth: 90
                implicitHeight: 36
                background: Rectangle {
                    color: parent.pressed ? "#1565C0" : "#1976D2"
                    radius: 8
                }
                contentItem: Text {
                    text: parent.text
                    color: "#FFFFFF"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: root.saveRequested()
            }
        }
    }

    function openDialog(sensor) {
        currentSensor = sensor
        customSensorName = sensor.name
        nameInput.text = customSensorName
        open()
        nameInput.forceActiveFocus()
    }
}