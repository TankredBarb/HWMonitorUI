import QtQuick 2.15
import QtQuick.Controls.Basic 2.15
import QtQuick.Layouts 1.15

Menu {
    id: root

    property real transparencyValue: 0.5

    background: Rectangle {
        implicitWidth: 230
        implicitHeight: 104
        color: "#FFFFFF"
        radius: 8
        border.color: "#D9DEE7"
        border.width: 1
    }

    contentItem: ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 7

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                Layout.preferredWidth: 4
                Layout.preferredHeight: 18
                radius: 2
                color: "#007AFF"
            }

            Text {
                text: "OPACITY"
                font.family: "Segoe UI"
                font.pixelSize: 12
                font.weight: Font.Bold
                color: "#1F2937"
                Layout.fillWidth: true
            }

            Rectangle {
                Layout.preferredWidth: 48
                Layout.preferredHeight: 20
                radius: 6
                color: "#EFF8FF"
                border.color: "#007AFF"
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: Math.round(root.transparencyValue * 100) + "%"
                    font.family: "Consolas, Monaco, monospace"
                    font.pixelSize: 12
                    font.weight: Font.Bold
                    color: "#007AFF"
                }
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
                width: transSlider.availableWidth
                height: 5
                radius: 3
                color: "#EEF2F6"

                Rectangle {
                    width: transSlider.visualPosition * parent.width
                    height: parent.height
                    radius: parent.radius
                    color: "#007AFF"
                }
            }

            handle: Rectangle {
                x: transSlider.leftPadding + transSlider.visualPosition * (transSlider.availableWidth - width)
                y: transSlider.topPadding + transSlider.availableHeight / 2 - height / 2
                implicitWidth: 16
                implicitHeight: 16
                radius: 8
                color: transSlider.pressed ? "#EFF8FF" : "#FFFFFF"
                border.color: "#007AFF"
                border.width: 2

                Behavior on color { ColorAnimation { duration: 120 } }
            }
        }

        RowLayout {
            Layout.fillWidth: true
        spacing: 6

            OpacityPreset {
                label: "25"
                value: 0.25
                selected: Math.abs(root.transparencyValue - value) < 0.015
                onPresetClicked: (presetValue) => root.transparencyValue = presetValue
            }

            OpacityPreset {
                label: "50"
                value: 0.50
                selected: Math.abs(root.transparencyValue - value) < 0.015
                onPresetClicked: (presetValue) => root.transparencyValue = presetValue
            }

            OpacityPreset {
                label: "75"
                value: 0.75
                selected: Math.abs(root.transparencyValue - value) < 0.015
                onPresetClicked: (presetValue) => root.transparencyValue = presetValue
            }

            OpacityPreset {
                label: "100"
                value: 1.0
                selected: Math.abs(root.transparencyValue - value) < 0.015
                onPresetClicked: (presetValue) => root.transparencyValue = presetValue
            }
        }
    }

    component OpacityPreset: AbstractButton {
        id: preset

        property string label: ""
        property real value: 1.0
        property bool selected: false

        signal presetClicked(real presetValue)

        Layout.fillWidth: true
        Layout.preferredHeight: 21
        hoverEnabled: true
        onClicked: preset.presetClicked(value)

        contentItem: Text {
            text: preset.label + "%"
            font.family: "Segoe UI"
            font.pixelSize: 10
            font.weight: Font.Bold
            color: preset.selected ? "#007AFF" : "#475467"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        background: Rectangle {
            radius: 6
            color: preset.selected ? "#EFF8FF" : (preset.pressed ? "#EEF2F6" : (preset.hovered ? "#F8FBFF" : "#FFFFFF"))
            border.color: preset.selected ? "#007AFF" : (preset.hovered ? "#B9D9FF" : "#D9DEE7")
            border.width: 1

            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on border.color { ColorAnimation { duration: 120 } }
        }
    }
}
