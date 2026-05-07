import QtQuick 2.15
import QtQuick.Layouts 1.15
// Layouts больше не нужен для позиционирования внутри Flow, но можно оставить для внутренних элементов

Rectangle {
    id: root

    // Убрали Layout.fillWidth и прочие Layout свойства, так как мы в Flow

    // Ширину и высоту теперь задает родитель (Flow) в main.qml,
    // но можно задать implicit для корректной работы, если вдруг родитель не задал
    implicitWidth: 150
    implicitHeight: 75

    property var sensorData: model.sensorData
    property bool isHovered: false

    property string sensorName: model.name
    property real sensorValue: model.value
    Behavior on sensorValue {
        NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
    }
    property string sensorUnit: model.unit
    property string sensorType: model.type

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

    // Внутри карточки можно использовать RowLayout для выравнивания контента
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
                        if (root.sensorType === "Temperature") return "🌡️";
                        if (root.sensorType === "Power") return "⚡";
                        if (root.sensorType === "Load") return "📊";
                        return "⚡";
                    }
                    font.pixelSize: 16
                }

                Text {
                    text: root.sensorName
                    font.family: "Segoe UI"
                    font.pixelSize: 11
                    color: "#1A1A1A"
                    font.weight: Font.Medium
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }

            Text {
                text: root.sensorValue.toFixed(1) + " " + root.sensorUnit
                font.family: "Consolas, Monaco, monospace"
                font.pixelSize: 18
                font.weight: Font.Bold
                color: {
                    if (root.sensorType === "Temperature" || root.sensorType === "Load") {
                        if (root.sensorValue > 85) return "#D32F2F";
                        if (root.sensorValue > 70) return "#F57C00";
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
            visible: root.sensorType === "Temperature" || root.sensorType === "Load"
            value: root.sensorValue
            maxValue: root.sensorType === "Temperature" ? 100 : 100
            sensorType: root.sensorType
        }
    }
}