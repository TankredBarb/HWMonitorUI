import QtQuick 2.15
import QtQuick.Controls.Basic 2.15
import QtQuick.Layouts 1.15

Popup {
    id: root

    modal: true
    focus: true
    parent: mainWindow.contentItem
    anchors.centerIn: parent
    width: 360
    height: 326
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 350; easing.type: Easing.OutCubic }
    }

    exit: Transition {
        NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 300; easing.type: Easing.OutCubic }
    }

    property var currentSensor: null
    property string customSensorName: ""
    property string customColor: "#1A1A1A"
    property bool customBold: false
    property alias currentInputText: nameInput.text

    signal saveRequested(string name, string color, bool isBold)

    background: Rectangle {
        color: "#E5E9F0"
        radius: 8
        border.color: "#D9DEE7"
        border.width: 1
    }

    Overlay.modal: Rectangle {
        color: "#660F172A"
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
                color: root.softTypeColor()
                border.color: root.typeColor()
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: root.typeLabel()
                    font.family: "Segoe UI"
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    color: root.typeColor()
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    text: "Sensor Settings"
                    font.family: "Segoe UI"
                    font.pixelSize: 15
                    font.weight: Font.Bold
                    color: "#1F2937"
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: currentSensor ? currentSensor.name : ""
                    font.family: "Segoe UI"
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    color: "#667085"
                    elide: Text.ElideRight
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
            Layout.preferredHeight: 48
            radius: 8
            color: "#F8FAFC"
            border.color: "#D9DEE7"
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8

                Rectangle {
                    Layout.preferredWidth: 4
                    Layout.fillHeight: true
                    radius: 2
                    color: root.customColor
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        Layout.fillWidth: true
                        text: "PREVIEW"
                        font.family: "Segoe UI"
                        font.pixelSize: 9
                        font.weight: Font.Bold
                        color: "#667085"
                    }

                    Text {
                        Layout.fillWidth: true
                        text: nameInput.text.length > 0 ? nameInput.text : "Sensor name"
                        font.family: "Segoe UI"
                        font.pixelSize: 13
                        font.weight: root.customBold ? Font.Bold : Font.Medium
                        color: root.customColor
                        elide: Text.ElideRight
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 5

            Text {
                text: "CUSTOM NAME"
                font.family: "Segoe UI"
                font.pixelSize: 10
                font.weight: Font.Bold
                color: "#667085"
            }

            TextField {
                id: nameInput

                Layout.fillWidth: true
                Layout.preferredHeight: 34
                placeholderText: "Enter custom name"
                text: root.customSensorName
                font.family: "Segoe UI"
                font.pixelSize: 13
                font.weight: Font.Medium
                color: "#1F2937"
                selectedTextColor: "#FFFFFF"
                selectionColor: "#007AFF"
                selectByMouse: true
                onAccepted: root.saveRequested(nameInput.text, root.customColor, root.customBold)

                background: Rectangle {
                    color: nameInput.activeFocus ? "#FFFFFF" : "#F8FAFC"
                    radius: 8
                    border.color: nameInput.activeFocus ? "#007AFF" : "#D9DEE7"
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 140 } }
                    Behavior on border.color { ColorAnimation { duration: 140 } }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 7

            AbstractButton {
                id: boldButton

                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                hoverEnabled: true
                checkable: true
                checked: root.customBold
                onClicked: root.customBold = checked

                contentItem: Text {
                    text: "B"
                    font.family: "Segoe UI"
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    color: root.customBold ? "#007AFF" : "#475467"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    radius: 7
                    color: root.customBold ? "#EFF8FF" : (boldButton.pressed ? "#EEF2F6" : (boldButton.hovered ? "#F8FBFF" : "#FFFFFF"))
                    border.color: root.customBold ? "#007AFF" : (boldButton.hovered ? "#B9D9FF" : "#D9DEE7")
                    border.width: root.customBold ? 2 : 1
                    Behavior on color { ColorAnimation { duration: 140 } }
                    Behavior on border.color { ColorAnimation { duration: 140 } }
                }
            }

            Repeater {
                model: ["#1A1A1A", "#D92D20", "#2F80ED", "#2EAD4F", "#F79009", "#7C3AED", "#0E9384"]

                Rectangle {
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    radius: 7
                    color: modelData
                    border.color: root.customColor === modelData ? "#007AFF" : "#D9DEE7"
                    border.width: root.customColor === modelData ? 3 : 1

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.customColor = modelData
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: 6
                        height: 6
                        radius: 3
                        color: "#FFFFFF"
                        visible: root.customColor === modelData
                    }
                }
            }

            Item { Layout.fillWidth: true }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Button {
                id: cancelButton

                text: "Cancel"
                Layout.fillWidth: true
                implicitHeight: 34
                onClicked: root.close()

                contentItem: Text {
                    text: cancelButton.text
                    color: cancelButton.pressed ? "#D92D20" : (cancelButton.hovered ? "#D92D20" : "#475467")
                    font.family: "Segoe UI"
                    font.pixelSize: 12
                    font.weight: Font.Bold
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    color: cancelButton.pressed ? "#FEF3F2" : (cancelButton.hovered ? "#FEF3F2" : "#FFFFFF")
                    radius: 8
                    border.color: cancelButton.hovered ? "#D92D20" : "#D9DEE7"
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 140 } }
                    Behavior on border.color { ColorAnimation { duration: 140 } }
                }
            }

            Button {
                id: saveButton

                text: "Save"
                Layout.fillWidth: true
                implicitHeight: 34
                onClicked: root.saveRequested(nameInput.text, root.customColor, root.customBold)

                contentItem: Text {
                    text: saveButton.text
                    color: "#FFFFFF"
                    font.family: "Segoe UI"
                    font.pixelSize: 12
                    font.weight: Font.Bold
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    color: saveButton.pressed ? "#005BBF" : (saveButton.hovered ? "#1677FF" : "#007AFF")
                    radius: 8
                    Behavior on color { ColorAnimation { duration: 140 } }
                }
            }
        }
    }

    function typeColor() {
        if (!currentSensor) return "#2F80ED";
        if (currentSensor.type === "Temperature") return "#2EAD4F";
        if (currentSensor.type === "Power") return "#7C3AED";
        if (currentSensor.type === "Load") return "#2F80ED";
        if (currentSensor.type === "Voltage") return "#0E9384";
        if (currentSensor.type === "Clock") return "#475467";
        if (currentSensor.type === "Fan") return "#1570EF";
        return "#2F80ED";
    }

    function softTypeColor() {
        if (!currentSensor) return "#EFF8FF";
        if (currentSensor.type === "Temperature") return "#ECFDF3";
        if (currentSensor.type === "Power") return "#F4F3FF";
        if (currentSensor.type === "Load") return "#EFF8FF";
        if (currentSensor.type === "Voltage") return "#F0FDFA";
        if (currentSensor.type === "Clock") return "#F8FAFC";
        if (currentSensor.type === "Fan") return "#EFF8FF";
        return "#EFF8FF";
    }

    function typeLabel() {
        if (!currentSensor || !currentSensor.type) return "SNS";
        if (currentSensor.type === "Temperature") return "TEMP";
        if (currentSensor.type === "Power") return "PWR";
        if (currentSensor.type === "Load") return "LOAD";
        if (currentSensor.type === "Voltage") return "VOLT";
        if (currentSensor.type === "Clock") return "CLK";
        if (currentSensor.type === "Fan") return "FAN";
        return currentSensor.type.toUpperCase();
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
