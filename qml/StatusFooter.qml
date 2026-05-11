import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls.Basic 2.15

RowLayout {
    id: root

    Layout.fillWidth: true
    Layout.alignment: Qt.AlignBottom
    spacing: 8

    property bool isOverlay: false
    property bool isTransparent: false
    property bool showUpdateFlash: true
    property int connectionState: 0
    property string connectionStatusText: ""

    signal overlayToggled()
    signal transparencyToggled()
    signal updateFlashToggled()
    signal reconnectClicked()

    function statusText() {
        if (root.connectionStatusText.length > 0) return root.connectionStatusText;
        if (root.connectionState === 0) return "Disconnected";
        if (root.connectionState === 1) return "Connecting";
        if (root.connectionState === 2) return "Connected";
        if (root.connectionState === 3) return "Connection Error";
        return "Unknown";
    }

    function statusAccentColor() {
        if (root.connectionState === 2) return "#2EAD4F";
        if (root.connectionState === 1) return "#F79009";
        if (root.connectionState === 3) return "#D92D20";
        return "#667085";
    }

    function statusSoftColor() {
        if (root.connectionState === 2) return "#ECFDF3";
        if (root.connectionState === 1) return "#FFFAEB";
        if (root.connectionState === 3) return "#FEF3F2";
        return "#F8FAFC";
    }

    AbstractButton {
        id: overlayButton

        hoverEnabled: true
        Layout.preferredWidth: 34
        Layout.preferredHeight: 34
        ToolTip.visible: hovered
        ToolTip.text: root.isOverlay ? "Restore" : "Always on top"
        onClicked: root.overlayToggled()

        contentItem: Item {
            Rectangle {
                anchors.centerIn: parent
                width: 12
                height: 12
                radius: 2
                color: "transparent"
                border.color: root.isOverlay ? "#007AFF" : "#475467"
                border.width: 2
                rotation: root.isOverlay ? 0 : 45
                Behavior on rotation { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                Behavior on border.color { ColorAnimation { duration: 140 } }

                Rectangle {
                    anchors.top: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 2
                    height: 5
                    radius: 1
                    color: parent.border.color
                }
            }
        }

        background: Rectangle {
            radius: 8
            color: root.isOverlay ? "#EFF8FF" : (overlayButton.pressed ? "#EEF2F6" : (overlayButton.hovered ? "#F8FBFF" : "#FFFFFF"))
            border.color: root.isOverlay ? "#007AFF" : (overlayButton.hovered ? "#B9D9FF" : "#D9DEE7")
            border.width: 1
            Behavior on color { ColorAnimation { duration: 140 } }
            Behavior on border.color { ColorAnimation { duration: 140 } }
        }
    }

    AbstractButton {
        id: transButton

        hoverEnabled: true
        Layout.preferredWidth: 34
        Layout.preferredHeight: 34
        ToolTip.visible: hovered
        ToolTip.text: root.isTransparent ? "Make opaque" : "Make transparent"
        onClicked: root.transparencyToggled()

        contentItem: Item {
            Rectangle {
                anchors.centerIn: parent
                width: 14
                height: 14
                radius: 7
                color: root.isTransparent ? "#EFF8FF" : "transparent"
                border.color: root.isTransparent ? "#007AFF" : "#475467"
                border.width: 2
                Behavior on color { ColorAnimation { duration: 140 } }
                Behavior on border.color { ColorAnimation { duration: 140 } }

                Rectangle {
                    anchors.centerIn: parent
                    width: 4
                    height: 4
                    radius: 2
                    color: parent.border.color
                    visible: root.isTransparent
                }
            }
        }

        background: Rectangle {
            radius: 8
            color: root.isTransparent ? "#EFF8FF" : (transButton.pressed ? "#EEF2F6" : (transButton.hovered ? "#F8FBFF" : "#FFFFFF"))
            border.color: root.isTransparent ? "#007AFF" : (transButton.hovered ? "#B9D9FF" : "#D9DEE7")
            border.width: 1
            Behavior on color { ColorAnimation { duration: 140 } }
            Behavior on border.color { ColorAnimation { duration: 140 } }
        }
    }

    AbstractButton {
        id: flashButton

        hoverEnabled: true
        Layout.preferredWidth: 34
        Layout.preferredHeight: 34
        ToolTip.visible: hovered
        ToolTip.text: root.showUpdateFlash ? "Disable update highlight" : "Enable update highlight"
        onClicked: root.updateFlashToggled()

        contentItem: Item {
            Rectangle {
                anchors.centerIn: parent
                width: 6
                height: 6
                radius: 3
                color: root.showUpdateFlash ? "#007AFF" : "#475467"
            }

            Rectangle {
                anchors.centerIn: parent
                width: 14
                height: 14
                radius: 7
                color: "transparent"
                border.color: root.showUpdateFlash ? "#007AFF" : "#475467"
                border.width: 2
                opacity: root.showUpdateFlash ? 0.9 : 0.55
            }

            Rectangle {
                anchors.centerIn: parent
                width: 20
                height: 20
                radius: 10
                color: "transparent"
                border.color: root.showUpdateFlash ? "#007AFF" : "#475467"
                border.width: 1
                opacity: root.showUpdateFlash ? 0.35 : 0.18
            }
        }

        background: Rectangle {
            radius: 8
            color: root.showUpdateFlash ? "#EFF8FF" : (flashButton.pressed ? "#EEF2F6" : (flashButton.hovered ? "#F8FBFF" : "#FFFFFF"))
            border.color: root.showUpdateFlash ? "#007AFF" : (flashButton.hovered ? "#B9D9FF" : "#D9DEE7")
            border.width: 1
            Behavior on color { ColorAnimation { duration: 140 } }
            Behavior on border.color { ColorAnimation { duration: 140 } }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        visible: root.isOverlay
        spacing: 6
        opacity: root.isTransparent ? 0.8 : 1.0

        Item { Layout.fillWidth: true }

        Item { Layout.fillWidth: true }
    }

    Item {
        Layout.fillWidth: true
        visible: !root.isOverlay
    }

    Rectangle {
        visible: root.connectionState >= 0
        Layout.preferredWidth: Math.max(92, statusLabel.implicitWidth + 28)
        Layout.preferredHeight: 26
        radius: 8
        color: root.statusSoftColor()
        border.color: root.statusAccentColor()
        border.width: 1
        opacity: root.isTransparent ? 0.75 : 1.0
        Behavior on color { ColorAnimation { duration: 160 } }
        Behavior on border.color { ColorAnimation { duration: 160 } }

        RowLayout {
            anchors.centerIn: parent
            spacing: 6

            Rectangle {
                Layout.preferredWidth: 7
                Layout.preferredHeight: 7
                radius: 4
                color: root.statusAccentColor()
                Behavior on color { ColorAnimation { duration: 160 } }
            }

            Text {
                id: statusLabel
                text: root.statusText()
                font.family: "Segoe UI"
                font.pixelSize: 12
                font.weight: Font.Bold
                color: root.statusAccentColor()
                Behavior on color { ColorAnimation { duration: 160 } }
            }
        }    
    }

    Button {
        id: reconnectButton

        visible: root.connectionState === 0 || root.connectionState === 3
        text: "Reconnect"
        font.pixelSize: 11
        onClicked: root.reconnectClicked()

        contentItem: Text {
            text: reconnectButton.text
            color: "#FFFFFF"
            font.family: "Segoe UI"
            font.pixelSize: 11
            font.weight: Font.Bold
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        background: Rectangle {
            implicitWidth: 86
            implicitHeight: 30
            radius: 8
            color: reconnectButton.pressed ? "#005BBF" : (reconnectButton.hovered ? "#1677FF" : "#007AFF")
            Behavior on color { ColorAnimation { duration: 140 } }
        }
    }
}
