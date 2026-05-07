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
    height: 350
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    property var currentSensor: null
    property string customSensorName: ""
    property string customColor: "#1A1A1A"
    property bool customBold: false
    property alias currentInputText: nameInput.text

    signal saveRequested(string name, string color, bool isBold)

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
        spacing: 12

        // Header
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
                font.pixelSize: 24
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    text: "Sensor Settings"
                    font.family: "Segoe UI"
                    font.pixelSize: 15
                    font.weight: Font.Bold
                    color: "#1A1A1A"
                }

                Text {
                    text: currentSensor ? currentSensor.name : ""
                    font.family: "Segoe UI"
                    font.pixelSize: 10
                    color: "#666666"
                    elide: Text.ElideRight
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: "#F0F0F0"
        }

        // Custom Name Input
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            Text {
                text: "Custom Name"
                font.family: "Segoe UI"
                font.pixelSize: 11
                color: "#888888"
            }

            TextField {
                id: nameInput
                Layout.fillWidth: true
                placeholderText: "Enter custom name"
                text: root.customSensorName
                font.family: "Segoe UI"
                font.pixelSize: 13
                color: "#1A1A1A"
                selectByMouse: true

                background: Rectangle {
                    color: "#F8F9FA"
                    radius: 8
                    border.color: nameInput.activeFocus ? "#007AFF" : "#E0E0E0"
                    border.width: 1
                }
                onAccepted: root.saveRequested(nameInput.text, root.customColor, root.customBold)
            }
        }

        // Text Style (Styled CheckBox)
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            
            CheckBox {
                id: boldCheck
                checked: root.customBold
                onCheckedChanged: root.customBold = checked
                
                indicator: Rectangle {
                    implicitWidth: 18
                    implicitHeight: 18
                    x: boldCheck.leftPadding
                    y: parent.height / 2 - height / 2
                    radius: 4
                    border.color: boldCheck.checked ? "#007AFF" : "#C0C0C0"
                    color: boldCheck.checked ? "#007AFF" : "white"

                    Rectangle {
                        width: 10; height: 10
                        x: 4; y: 4
                        radius: 2
                        color: "white"
                        visible: boldCheck.checked
                    }
                }

                contentItem: Text {
                    text: "Bold Font Style"
                    font.family: "Segoe UI"
                    font.pixelSize: 13
                    font.weight: root.customBold ? Font.Bold : Font.Normal
                    color: "#333333"
                    leftPadding: boldCheck.indicator.width + 8
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }

        // Color Picker
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: "Label Color"
                font.family: "Segoe UI"
                font.pixelSize: 11
                color: "#888888"
            }

            Row {
                spacing: 10
                property var colors: ["#1A1A1A", "#D32F2F", "#1976D2", "#388E3C", "#F57C00", "#7B1FA2", "#455A64"]
                
                Repeater {
                    model: parent.colors
                    Rectangle {
                        width: 26; height: 26; radius: 13
                        color: modelData
                        border.color: root.customColor === modelData ? "#007AFF" : "transparent"
                        border.width: 2
                        
                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.customColor = modelData
                        }

                        Rectangle {
                            anchors.centerIn: parent
                            width: 6; height: 6; radius: 3; color: "white"
                            visible: root.customColor === modelData
                        }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true; Layout.maximumHeight: 10 } // Уменьшаем пустое пространство

        // Action Buttons
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Button {
                text: "Cancel"
                Layout.fillWidth: true
                implicitHeight: 36
                background: Rectangle {
                    color: parent.pressed ? "#D32F2F" : (parent.hovered ? "#FFEBEE" : "#FFFFFF")
                    radius: 8
                    border.color: parent.hovered ? "#D32F2F" : "#D0D0D0"
                }
                contentItem: Text {
                    text: parent.text
                    color: parent.pressed ? "white" : (parent.hovered ? "#D32F2F" : "#666666")
                    font.weight: parent.hovered ? Font.Bold : Font.Normal
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: root.close()
            }

            Button {
                text: "Save"
                Layout.fillWidth: true
                implicitHeight: 36
                background: Rectangle {
                    color: parent.pressed ? "#005BBF" : "#007AFF"
                    radius: 8
                }
                contentItem: Text {
                    text: parent.text
                    color: "#FFFFFF"
                    font.weight: Font.Bold
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: root.saveRequested(nameInput.text, root.customColor, root.customBold)
            }
        }
    }

    function openDialog(sensor) {
        currentSensor = sensor
        customSensorName = sensor.name
        customColor = sensor.color || "#1A1A1A"
        customBold = sensor.isBold || false
        nameInput.text = customSensorName
        open()
        nameInput.forceActiveFocus()
    }
}
