import QtQuick 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: root
    Layout.preferredWidth: 170
    Layout.preferredHeight: 75
    Layout.minimumWidth: 80

    property var sensorData: null
    property bool isHovered: false

    color: isHovered ? "#E3F2FD" : "#FFFFFF"
    radius: 16
    border.color: isHovered ? "#1976D2" : "#D0D0D0"
    border.width: isHovered ? 2 : 1

    Behavior on border.color {
        ColorAnimation { duration: 150 }
    }
    Behavior on color {
        ColorAnimation { duration: 150 }
    }
    Behavior on border.width {
        NumberAnimation { duration: 150 }
    }

    signal clicked()

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onContainsMouseChanged: {
            root.isHovered = containsMouse
        }

        onClicked: {
            root.clicked()
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: {
                        if (!sensorData) return "⚡";
                        if (sensorData.type === "Temperature") return "🌡️";
                        if (sensorData.type === "Power") return "⚡";
                        if (sensorData.type === "Load") return "📊";
                        return "⚡";
                    }
                    font.pixelSize: 16
                }

                Text {
                    text: sensorData ? sensorData.name : ""
                    font.family: "Segoe UI"
                    font.pixelSize: 11
                    color: "#1A1A1A"
                    font.weight: Font.Medium
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }

            Text {
                text: sensorData ? (Number(sensorData.value).toFixed(1) + " " + sensorData.unit) : ""
                font.family: "Segoe UI"
                font.pixelSize: 20
                font.weight: Font.Bold
                color: {
                    if (!sensorData) return "#1A1A1A";
                    if (sensorData.type === "Temperature" || sensorData.type === "Load") {
                        if (sensorData.value > 85) return "#D32F2F";
                        if (sensorData.value > 70) return "#F57C00";
                        return "#388E3C";
                    }
                    return "#1976D2";
                }
            }
        }

        SensorGauge {
            Layout.preferredWidth: 55
            Layout.preferredHeight: 55
            Layout.alignment: Qt.AlignVCenter
            visible: sensorData && (sensorData.type === "Temperature" || sensorData.type === "Load")
            value: sensorData ? sensorData.value : 0
            maxValue: sensorData && sensorData.type === "Temperature" ? 100 : 100
            sensorType: sensorData ? sensorData.type : ""
        }
    }
}