import QtQuick 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: root
    Layout.fillWidth: true
    implicitHeight: 90
    color: "#FFFFFF"
    radius: 16
    border.color: "#D0D0D0"
    border.width: 1

    property var hardwareInfo: ({})

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 2
        spacing: 1

        Text {
            text: "HARDWARE MONITOR"
            font.family: "Segoe UI"
            font.pixelSize: 14
            font.weight: Font.DemiBold
            color: "#666666"
            Layout.alignment: Qt.AlignHCenter
        }

        RowLayout {
            spacing: 20
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 2

            ColumnLayout {
                spacing: 0
                Text { text: "CPU: " + (hardwareInfo.cpu || "Unknown"); color: "#1A1A1A"; font.pixelSize: 13; font.weight: Font.Medium }
                Text { text: "GPU: " + (hardwareInfo.gpu || "Unknown"); color: "#1A1A1A"; font.pixelSize: 13; font.weight: Font.Medium }
                Text { text: "MB:  " + (hardwareInfo.mb || "Unknown"); color: "#1A1A1A"; font.pixelSize: 13; font.weight: Font.Medium }
            }
        }
    }
}