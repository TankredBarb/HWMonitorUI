import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls.Basic 2.15

RowLayout {
    id: root
    Layout.fillWidth: true
    Layout.alignment: Qt.AlignBottom
    spacing: 8

    // Forwarding properties and signals
    property bool isOverlay: false
    property bool isTransparent: false
    property int connectionState: 0
    property string connectionStatusText: ""
    
    signal overlayToggled()
    signal transparencyToggled()
    signal reconnectClicked()

    AbstractButton {
        id: overlayButton
        hoverEnabled: true
        Layout.preferredWidth: 34
        Layout.preferredHeight: 34
        ToolTip.visible: hovered
        ToolTip.text: root.isOverlay ? "Restore" : "Always on top"

        contentItem: Item {
            Rectangle {
                anchors.centerIn: parent
                width: 12; height: 12; radius: 2; color: "transparent"
                border.color: root.isOverlay ? "#007AFF" : "#666666"
                border.width: 2; rotation: root.isOverlay ? 0 : 45
                Behavior on rotation { NumberAnimation { duration: 200 } }
                Rectangle {
                    anchors.top: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter
                    width: 2; height: 5; color: parent.border.color
                }
            }
        }
        background: Rectangle {
            radius: 6
            color: parent.pressed ? "#E0E0E0" : (parent.hovered ? "#F0F0F0" : "transparent")
            border.color: root.isOverlay ? "#007AFF" : "transparent"
        }
        onClicked: root.overlayToggled()
    }

    AbstractButton {
        id: transButton
        hoverEnabled: true
        Layout.preferredWidth: 34
        Layout.preferredHeight: 34
        ToolTip.visible: hovered
        ToolTip.text: root.isTransparent ? "Make opaque" : "Make transparent"

        contentItem: Item {
            Rectangle {
                anchors.centerIn: parent
                width: 14; height: 14; radius: 7
                color: "transparent"
                border.color: root.isTransparent ? "#007AFF" : "#666666"
                border.width: 2

                Rectangle {
                    anchors.centerIn: parent
                    width: 4; height: 4; radius: 2
                    color: parent.border.color
                    visible: root.isTransparent
                }
            }
        }
        background: Rectangle {
            radius: 6
            color: parent.pressed ? "#E0E0E0" : (parent.hovered ? "#F0F0F0" : "transparent")
            border.color: root.isTransparent ? "#007AFF" : "transparent"
        }
        onClicked: root.transparencyToggled()
    }

    Item { Layout.fillWidth: true }

    RowLayout {
        spacing: 8
        visible: root.connectionState === 2
        opacity: (root.isOverlay || root.isTransparent) ? 0.5 : 1.0
        Rectangle { width: 8; height: 8; radius: 4; color: "#4CAF50" }
        Text {
            text: root.connectionStatusText
            font.pixelSize: 12; font.weight: Font.DemiBold; color: "#555555"
            visible: !root.isOverlay
        }
    }

    Button {
        visible: (root.connectionState === 0 || root.connectionState === 3) && !root.isOverlay
        text: "Reconnect"
        font.pixelSize: 11
        contentItem: Text { text: parent.text; color: "white"; font.weight: Font.Bold; horizontalAlignment: Text.AlignHCenter }
        background: Rectangle { color: parent.pressed ? "#005BBF" : "#007AFF"; radius: 6; implicitWidth: 80; implicitHeight: 28 }
        onClicked: root.reconnectClicked()
    }
}
