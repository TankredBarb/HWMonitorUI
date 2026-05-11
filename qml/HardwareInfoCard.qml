import QtQuick 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: root

    Layout.fillWidth: true
    implicitHeight: 104
    color: "#FFFFFF"
    radius: 8
    border.color: "#D9DEE7"
    border.width: 1

    property var hardwareInfo: ({})

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        anchors.topMargin: 10
        anchors.bottomMargin: 10
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                Layout.preferredWidth: 4
                Layout.preferredHeight: 18
                radius: 2
                color: "#2F80ED"
            }

            Text {
                text: "HARDWARE"
                font.family: "Segoe UI"
                font.pixelSize: 12
                font.weight: Font.Bold
                color: "#1F2937"
                Layout.fillWidth: true
            }

            Rectangle {
                Layout.preferredWidth: 56
                Layout.preferredHeight: 20
                radius: 5
                color: "#ECFDF3"
                border.color: "#2EAD4F"
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "LIVE"
                    font.family: "Segoe UI"
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    color: "#2EAD4F"
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 1
            rowSpacing: 5
            columnSpacing: 0

            HardwareLine {
                Layout.fillWidth: true
                label: "CPU"
                value: root.hardwareInfo.cpu || "Unknown"
                accentColor: "#2F80ED"
                softColor: "#EFF8FF"
            }

            HardwareLine {
                Layout.fillWidth: true
                label: "GPU"
                value: root.hardwareInfo.gpu || "Unknown"
                accentColor: "#7C3AED"
                softColor: "#F4F3FF"
            }

            HardwareLine {
                Layout.fillWidth: true
                label: "MB"
                value: root.hardwareInfo.mb || "Unknown"
                accentColor: "#0E9384"
                softColor: "#F0FDFA"
            }
        }
    }

    component HardwareLine: RowLayout {
        id: line

        property string label: ""
        property string value: ""
        property color accentColor: "#2F80ED"
        property color softColor: "#EFF8FF"

        spacing: 8

        Rectangle {
            Layout.preferredWidth: 34
            Layout.preferredHeight: 18
            radius: 5
            color: line.softColor
            border.color: line.accentColor
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: line.label
                font.family: "Segoe UI"
                font.pixelSize: 8
                font.weight: Font.Bold
                color: line.accentColor
            }
        }

        Text {
            Layout.fillWidth: true
            text: line.value
            font.family: "Segoe UI"
            font.pixelSize: 11
            font.weight: Font.Medium
            color: "#1F2937"
            elide: Text.ElideRight
        }
    }
}
