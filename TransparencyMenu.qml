import QtQuick 2.15
import QtQuick.Controls.Basic 2.15
import QtQuick.Layouts 1.15

Menu {
    id: root
    
    property real transparencyValue: 0.5
    
    background: Rectangle {
        implicitWidth: 180
        implicitHeight: 70
        color: "white"
        radius: 12
        border.color: "#B0B0B0"
        border.width: 1
    }

    contentItem: ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "Transparency"
                font.family: "Segoe UI"
                font.pixelSize: 12
                font.weight: Font.Medium
                color: "#666666"
            }
            Item { Layout.fillWidth: true }
            Text {
                text: Math.round(root.transparencyValue * 100) + "%"
                font.family: "Consolas, Monaco, monospace"
                font.pixelSize: 12
                font.weight: Font.Bold
                color: "#007AFF"
            }
        }

        Slider {
            id: transSlider
            Layout.fillWidth: true
            Layout.preferredHeight: 20
            from: 0.1
            to: 1.0
            value: root.transparencyValue
            onMoved: root.transparencyValue = value
            
            background: Rectangle {
                x: transSlider.leftPadding
                y: transSlider.topPadding + transSlider.availableHeight / 2 - height / 2
                implicitWidth: 200
                implicitHeight: 4
                width: transSlider.availableWidth
                height: implicitHeight
                radius: 2
                color: "#E0E0E0"

                Rectangle {
                    width: transSlider.visualPosition * parent.width
                    height: parent.height
                    color: "#007AFF"
                    radius: 2
                }
            }

            handle: Rectangle {
                x: transSlider.leftPadding + transSlider.visualPosition * (transSlider.availableWidth - width)
                y: transSlider.topPadding + transSlider.availableHeight / 2 - height / 2
                implicitWidth: 16
                implicitHeight: 16
                radius: 8
                color: transSlider.pressed ? "#F0F0F0" : "#FFFFFF"
                border.color: "#007AFF"
                border.width: 2
            }
        }
    }
}
