import QtQuick 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: root

    implicitWidth: 150
    implicitHeight: 82

    property var sensorData: model.sensorData
    property bool isHovered: false
    property bool showUpdateFlash: true

    property string sensorName: model.name
    property real sensorValue: model.value
    property real displayValue: sensorValue
    Behavior on displayValue {
        NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
    }
    property string sensorUnit: model.unit
    property string sensorType: model.type
    property string sensorColor: model.color || "#1A1A1A"
    property bool sensorBold: model.isBold || false
    property bool initialized: false
    property real previousSensorValue: sensorValue
    property real normalizedValue: Math.max(0, Math.min(1, displayValue / 100))
    property color accentColor: statusColor()
    property color softAccentColor: softColor()

    color: isHovered ? "#F8FBFF" : "#FFFFFF"
    radius: 8
    border.color: isHovered ? root.accentColor : "#D9DEE7"
    border.width: 1

    Behavior on border.color { ColorAnimation { duration: 150 } }
    Behavior on color { ColorAnimation { duration: 150 } }

    signal clicked()

    Component.onCompleted: {
        previousSensorValue = sensorValue
        displayValue = sensorValue
        initialized = true
    }

    onSensorValueChanged: {
        if (showUpdateFlash && initialized && Math.abs(sensorValue - previousSensorValue) > 0.05) {
            valueFlash.restart()
        }
        previousSensorValue = sensorValue
        displayValue = sensorValue
    }

    function statusColor() {
        if (root.sensorType === "Temperature") {
            if (root.displayValue >= 85) return "#D92D20";
            if (root.displayValue >= 70) return "#F79009";
            return "#2EAD4F";
        }
        if (root.sensorType === "Load") {
            if (root.displayValue >= 90) return "#D92D20";
            if (root.displayValue >= 75) return "#F79009";
            return "#2F80ED";
        }
        if (root.sensorType === "Power") return "#7C3AED";
        if (root.sensorType === "Voltage") return "#0E9384";
        if (root.sensorType === "Clock") return "#475467";
        if (root.sensorType === "Fan") return "#1570EF";
        return "#2F80ED";
    }

    function softColor() {
        if (root.accentColor === "#D92D20") return "#FEF3F2";
        if (root.accentColor === "#F79009") return "#FFFAEB";
        if (root.accentColor === "#2EAD4F") return "#ECFDF3";
        if (root.accentColor === "#7C3AED") return "#F4F3FF";
        if (root.accentColor === "#0E9384") return "#F0FDFA";
        return "#EFF8FF";
    }

    function typeLabel() {
        if (root.sensorType === "Temperature") return "TEMP";
        if (root.sensorType === "Power") return "PWR";
        if (root.sensorType === "Load") return "LOAD";
        if (root.sensorType === "Voltage") return "VOLT";
        if (root.sensorType === "Clock") return "CLK";
        if (root.sensorType === "Fan") return "FAN";
        return root.sensorType ? root.sensorType.toUpperCase() : "SENSOR";
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onContainsMouseChanged: root.isHovered = containsMouse
        onClicked: root.clicked()
    }

    Rectangle {
        width: 4
        radius: 2
        color: root.accentColor
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.topMargin: 10
        anchors.bottomMargin: 10
        Behavior on color { ColorAnimation { duration: 220 } }
    }

    Rectangle {
        id: flashOverlay
        anchors.fill: parent
        radius: parent.radius
        color: root.accentColor
        opacity: 0
    }

    SequentialAnimation {
        id: valueFlash
        NumberAnimation {
            target: flashOverlay
            property: "opacity"
            from: 0.20
            to: 0.20
            duration: 180
        }
        NumberAnimation {
            target: flashOverlay
            property: "opacity"
            from: 0.20
            to: 0
            duration: 1400
            easing.type: Easing.OutCubic
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 10
        anchors.topMargin: 10
        anchors.bottomMargin: 10
        spacing: 10

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 5

            RowLayout {
                Layout.fillWidth: true
                spacing: 7

                Rectangle {
                    Layout.preferredWidth: 34
                    Layout.preferredHeight: 18
                    radius: 5
                    color: root.softAccentColor
                    border.color: root.accentColor
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: root.typeLabel()
                        font.family: "Segoe UI"
                        font.pixelSize: 8
                        font.weight: Font.Bold
                        color: root.accentColor
                    }
                }

                Text {
                    text: root.sensorName
                    font.family: "Segoe UI"
                    font.pixelSize: 12
                    color: root.sensorColor
                    font.weight: root.sensorBold ? Font.Bold : Font.Medium
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }

            Text {
                text: root.displayValue.toFixed(1) + " " + root.sensorUnit
                font.family: "Consolas, Monaco, monospace"
                font.pixelSize: 19
                font.weight: Font.Bold
                color: root.accentColor
                Behavior on color { ColorAnimation { duration: 220 } }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 3
                radius: 2
                color: "#EEF2F6"
                visible: root.sensorType === "Temperature" || root.sensorType === "Load"

                Rectangle {
                    width: parent.width * root.normalizedValue
                    height: parent.height
                    radius: parent.radius
                    color: root.accentColor
                    Behavior on width { NumberAnimation { duration: 360; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 220 } }
                }
            }
        }

        SensorGauge {
            Layout.preferredWidth: Math.max(48, Math.min(78, root.height - 28))
            Layout.preferredHeight: Layout.preferredWidth
            Layout.alignment: Qt.AlignVCenter
            visible: root.sensorType === "Temperature" || root.sensorType === "Load"
            value: root.displayValue
            maxValue: 100
            sensorType: root.sensorType
        }
    }
}
