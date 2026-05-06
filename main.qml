import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls.Basic 2.15
import QtQuick.Layouts 1.15

Window {
    id: mainWindow
    visible: true
    title: "Qt Hardware Monitor"
    color: "#E8E8E8"

    // Dynamic size based on connection state - use fixed values to prevent flickering
    width: 380
    height: 580

    // Store previous state to prevent flickering
    property int prevState: -1
    onConnectionStateChanged: {
        prevState = connectionState
    }

    property var hardwareInfo: ({})
    property var sensors: []
    property int connectionState: 0 // 0=Disconnected, 1=Connecting, 2=Connected, 3=Error
    property string connectionStatusText: "Disconnected"

    function updateConnectionState(state) {
        connectionState = state;
        switch(state) {
            case 0: connectionStatusText = "Disconnected"; break;
            case 1: connectionStatusText = "Connecting..."; break;
            case 2: connectionStatusText = "Connected"; break;
            case 3: connectionStatusText = "Connection Error"; break;
        }
    }

    function reconnect() {
        console.log("Reconnecting...");
        reconnectClicked();
    }

    signal reconnectClicked()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        // --- Header Section (only visible when connected) ---
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 90
            color: "#FFFFFF"
            radius: 16
            border.color: "#D0D0D0"
            border.width: 1
            visible: connectionState === 2

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

        // --- Sensors List (only visible when connected) ---
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            visible: connectionState === 2
            ScrollBar.vertical.policy: ScrollBar.AsNeeded
            implicitHeight: connectionState === 2 ? parent.height - 180 : 0

            ColumnLayout {
                width: parent.width
                spacing: 12
                Layout.fillWidth: true

                Repeater {
                    model: sensors

                    delegate: Rectangle {
                        id: card
                        Layout.fillWidth: true
                        implicitHeight: 80
                        color: "#FFFFFF"
                        radius: 16
                        border.color: "#D0D0D0"
                        border.width: 1

                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                        }

                        scale: mouseArea.containsMouse ? 1.01 : 1.0
                        Behavior on scale {
                            NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                        }
                        Behavior on border.color {
                            ColorAnimation { duration: 150 }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 20
                            anchors.rightMargin: 20
                            spacing: 15

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                spacing: 2

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 10

                                    Text {
                                        text: modelData.type === "Temperature" ? "🌡️" : "⚡"
                                        font.pixelSize: 20
                                    }

                                    Text {
                                        text: modelData.name
                                        font.family: "Segoe UI"
                                        font.pixelSize: 14
                                        color: "#1A1A1A"
                                        font.weight: Font.Medium
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }
                                }

                                Text {
                                    text: Number(modelData.value).toFixed(1) + " " + modelData.unit
                                    font.family: "Segoe UI"
                                    font.pixelSize: 28
                                    font.weight: Font.Bold
                                    color: {
                                        if (modelData.type === "Temperature") {
                                            if (modelData.value > 85) return "#D32F2F";
                                            if (modelData.value > 70) return "#F57C00";
                                            return "#388E3C";
                                        }
                                        return "#1976D2";
                                    }
                                }
                            }

                            Canvas {
                                id: gauge
                                Layout.preferredWidth: 60
                                Layout.preferredHeight: 60
                                Layout.alignment: Qt.AlignVCenter
                                visible: modelData.type === "Temperature"
                                antialiasing: true

                                property real val: modelData.value || 0
                                property real maxVal: 100

                                onValChanged: requestPaint()

                                onPaint: {
                                    var ctx = getContext("2d");
                                    ctx.reset();

                                    var w = width;
                                    var h = height;
                                    var cx = w / 2;
                                    var cy = h / 2;
                                    var r = Math.min(w, h) / 2 - 6;

                                    var activeColor = "#388E3C";
                                    if (val > 85) activeColor = "#D32F2F";
                                    else if (val > 70) activeColor = "#F57C00";

                                    ctx.beginPath();
                                    ctx.arc(cx, cy, r, Math.PI * 0.75, Math.PI * 2.25);
                                    ctx.lineWidth = 6;
                                    ctx.strokeStyle = "#E0E0E0";
                                    ctx.lineCap = "round";
                                    ctx.stroke();

                                    var progress = Math.min(val / maxVal, 1.0);
                                    var endAngle = Math.PI * 0.75 + (Math.PI * 1.5 * progress);

                                    ctx.beginPath();
                                    ctx.arc(cx, cy, r, Math.PI * 0.75, endAngle);
                                    ctx.lineWidth = 6;
                                    ctx.strokeStyle = activeColor;
                                    ctx.lineCap = "round";
                                    ctx.stroke();
                                }
                            }
                        }
                    }
                }
            }
        }

        // Status message for non-connected states
        Text {
            Layout.alignment: Qt.AlignCenter
            Layout.fillWidth: true
            text: {
                if (connectionState === 3) return "Connection Error - hwmonitor may not be running";
                if (connectionState === 0) return "Disconnected - Click Reconnect to try again";
                if (connectionState === 1) return "Connecting...";
                return "";
            }
            color: connectionState === 3 ? "#F44336" : (connectionState === 0 ? "#9E9E9E" : "#FFA000")
            font.pixelSize: 14
            font.weight: Font.Medium
            visible: connectionState !== 2
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            Layout.preferredHeight: connectionState !== 2 ? implicitHeight : 0
        }

        // Connection Status Indicator and Reconnect button (bottom)
        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignBottom
            spacing: 8

            Item {
                Layout.fillWidth: true
            }

            Rectangle {
                id: connectionIndicator
                implicitWidth: 10
                implicitHeight: 10
                radius: 5
                color: {
                    if (connectionState === 0) return "#9E9E9E"; // Disconnected - Gray
                    if (connectionState === 1) return "#FFA000"; // Connecting - Orange
                    if (connectionState === 2) return "#4CAF50"; // Connected - Green
                    return "#F44336"; // Error - Red
                }
                visible: connectionState === 2
            }

            Text {
                text: connectionStatusText
                font.family: "Segoe UI"
                font.pixelSize: 14
                color: {
                    if (connectionState === 0) return "#9E9E9E";
                    if (connectionState === 1) return "#FFA000";
                    if (connectionState === 2) return "#4CAF50";
                    return "#F44336";
                }
                font.weight: Font.Bold
                Layout.alignment: Qt.AlignVCenter
                visible: connectionState === 2
            }

            // Reconnect button (visible only on error or disconnected)
            Button {
                visible: connectionState === 0 || connectionState === 3
                text: "Reconnect"
                font.family: "Segoe UI"
                font.pixelSize: 11
                Layout.alignment: Qt.AlignVCenter
                background: Rectangle {
                    color: parent.pressed ? "#1565C0" : "#1976D2"
                    radius: 4
                    implicitWidth: 70
                    implicitHeight: 24
                }
                contentItem: Text {
                    text: parent.text
                    color: "#FFFFFF"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: {
                    mainWindow.reconnect();
                }
            }
        }

        // Invisible spacer to fill remaining space when connected
        Item {
            Layout.fillHeight: true
            visible: connectionState === 2
        }
    }
}