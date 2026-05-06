import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Window {
    id: mainWindow
    width: 450
    height: 550
    visible: true
    title: "Qt Hardware Monitor"
    color: "#E8E8E8"

    property var hardwareInfo: ({})
    property var sensors: []

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        // --- Header Section ---
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 90
            color: "#FFFFFF"
            radius: 16
            border.color: "#D0D0D0"
            border.width: 1

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 4

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

                    ColumnLayout {
                        spacing: 0
                        Text { text: "CPU: " + (hardwareInfo.cpu || "Unknown"); color: "#1A1A1A"; font.pixelSize: 13; font.weight: Font.Medium }
                        Text { text: "GPU: " + (hardwareInfo.gpu || "Unknown"); color: "#1A1A1A"; font.pixelSize: 13; font.weight: Font.Medium }
                        Text { text: "MB:  " + (hardwareInfo.mb || "Unknown"); color: "#1A1A1A"; font.pixelSize: 13; font.weight: Font.Medium }
                    }
                }
            }
        }

        // --- Sensors List ---
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            Repeater {
                model: sensors

                delegate: Rectangle {
                    id: card
                    Layout.fillWidth: true
                    Layout.preferredHeight: 80
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

            Text {
                Layout.alignment: Qt.AlignCenter
                text: sensors.length === 0 ? "Waiting for data..." : ""
                color: "#999999"
                font.pixelSize: 16
                visible: sensors.length === 0
            }
        }
    }
}