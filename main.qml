import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls.Basic 2.15
import QtQuick.Layouts 1.15

Window {
    id: mainWindow
    visible: true
    title: "Qt Hardware Monitor"
    color: "#E8E8E8"

    width: 385
    height: 530

    property var hardwareInfo: ({})
    property var sensors: []
    property int connectionState: 0
    property string connectionStatusText: "Disconnected"

    // Properties for sensor editor dialog
    property var currentSensor: null
    property string customSensorName: ""

    function reconnect() {
        console.log("Reconnecting...");
        reconnectClicked();
    }

    signal reconnectClicked()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        // --- Header Section ---
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

        // --- Sensors Grid ---
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            visible: connectionState === 2
            ScrollBar.vertical.policy: ScrollBar.AsNeeded

            GridLayout {
                width: parent.width
                columns: 2
                rowSpacing: 10
                columnSpacing: 10
                Layout.fillWidth: true

                Repeater {
                    model: sensors

                    delegate: Rectangle {
                        id: card
                        Layout.preferredWidth: 170
                        Layout.preferredHeight: 75
                        Layout.minimumWidth: 80

                        // Состояние выделения храним отдельно, чтобы оно не сбрасывалось при обновлении данных
                        property bool isHovered: false

                        // Цвета и границы
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

                        // MouseArea теперь заполняет ВСЮ карточку без отступов
                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onContainsMouseChanged: {
                                card.isHovered = containsMouse
                            }

                            onClicked: {
                                sensorEditorPopup.openDialog(modelData)
                            }
                        }

                        // Контент внутри, с отступами, чтобы не прилипал к краям
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 14 // Отступы ВНУТРИ карточки
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
                                            if (modelData.type === "Temperature") return "🌡️";
                                            if (modelData.type === "Power") return "⚡";
                                            if (modelData.type === "Load") return "📊";
                                            return "⚡";
                                        }
                                        font.pixelSize: 16
                                    }

                                    Text {
                                        text: modelData.name
                                        font.family: "Segoe UI"
                                        font.pixelSize: 11
                                        color: "#1A1A1A"
                                        font.weight: Font.Medium
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }
                                }

                                Text {
                                    text: Number(modelData.value).toFixed(1) + " " + modelData.unit
                                    font.family: "Segoe UI"
                                    font.pixelSize: 20
                                    font.weight: Font.Bold
                                    color: {
                                        if (modelData.type === "Temperature" || modelData.type === "Load") {
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
                                Layout.preferredWidth: 55
                                Layout.preferredHeight: 55
                                Layout.alignment: Qt.AlignVCenter
                                visible: modelData.type === "Temperature" || modelData.type === "Load"
                                antialiasing: true

                                property real val: modelData.value || 0
                                property real maxVal: modelData.type === "Temperature" ? 100 : 100

                                onValChanged: requestPaint()

                                onPaint: {
                                    var ctx = getContext("2d");
                                    ctx.reset();

                                    var w = width;
                                    var h = height;
                                    var cx = w / 2;
                                    var cy = h / 2;
                                    var r = Math.min(w, h) / 2 - 5;

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

        // Status message
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
        }

        // Bottom bar
        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignBottom
            spacing: 8

            Item { Layout.fillWidth: true }

            Rectangle {
                id: connectionIndicator
                implicitWidth: 10
                implicitHeight: 10
                radius: 5
                color: {
                    if (connectionState === 0) return "#9E9E9E";
                    if (connectionState === 1) return "#FFA000";
                    if (connectionState === 2) return "#4CAF50";
                    return "#F44336";
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

        Item {
            Layout.fillHeight: true
            visible: connectionState === 2
        }
    }

    // Sensor Editor Dialog
    Popup {
        id: sensorEditorPopup
        modal: true
        focus: true
        parent: mainWindow.contentItem
        anchors.centerIn: parent
        width: 340
        height: 340
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        background: Rectangle {
            color: "#FFFFFF"
            radius: 16
            border.color: "#D0D0D0"
            border.width: 1
        }
        Overlay.modal: Rectangle {
            color: "#80000000"
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 20

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Text {
                    text: {
                        if (currentSensor && currentSensor.type === "Temperature") return "🌡️";
                        if (currentSensor && currentSensor.type === "Power") return "⚡";
                        if (currentSensor && currentSensor.type === "Load") return "📊";
                        return "⚡";
                    }
                    font.pixelSize: 28
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: "Edit Sensor Name"
                        font.family: "Segoe UI"
                        font.pixelSize: 16
                        font.weight: Font.Bold
                        color: "#1A1A1A"
                    }

                    Text {
                        text: currentSensor ? currentSensor.name : ""
                        font.family: "Segoe UI"
                        font.pixelSize: 11
                        color: "#666666"
                        elide: Text.ElideRight
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: "#E0E0E0"
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: "Current Value"
                    font.family: "Segoe UI"
                    font.pixelSize: 11
                    color: "#666666"
                }

                Text {
                    text: currentSensor ? Number(currentSensor.value).toFixed(1) + " " + currentSensor.unit : "--"
                    font.family: "Segoe UI"
                    font.pixelSize: 24
                    font.weight: Font.Bold
                    color: {
                        if (!currentSensor) return "#1A1A1A";
                        if (currentSensor.type === "Temperature" || currentSensor.type === "Load") {
                            if (currentSensor.value > 85) return "#D32F2F";
                            if (currentSensor.value > 70) return "#F57C00";
                            return "#388E3C";
                        }
                        return "#1976D2";
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: "Custom Name"
                    font.family: "Segoe UI"
                    font.pixelSize: 11
                    color: "#666666"
                }

                TextField {
                    id: nameInput
                    Layout.fillWidth: true
                    placeholderText: "Enter custom name (English or Russian)"
                    text: customSensorName
                    font.family: "Segoe UI"
                    font.pixelSize: 13
                    color: "#1A1A1A"
                    selectByMouse: true
                    validator: RegularExpressionValidator { regularExpression: /.{0,50}/ }

                    background: Rectangle {
                        color: "#FFFFFF"
                        radius: 8
                        border.color: nameInput.activeFocus ? "#1976D2" : "#D0D0D0"
                        border.width: 1
                    }

                    placeholderTextColor: "#9E9E9E"
                    selectionColor: "#1976D2"
                    selectedTextColor: "#FFFFFF"

                    onAccepted: mainWindow.saveCustomNameAction()
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 8
                spacing: 10

                Item { Layout.fillWidth: true }

                Button {
                    text: "Cancel"
                    font.family: "Segoe UI"
                    font.pixelSize: 12
                    implicitWidth: 90
                    implicitHeight: 36
                    background: Rectangle {
                        color: parent.pressed ? "#E0E0E0" : "#F5F5F5"
                        radius: 8
                        border.color: "#D0D0D0"
                        border.width: 1
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "#666666"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: sensorEditorPopup.close()
                }

                Button {
                    text: "Save"
                    font.family: "Segoe UI"
                    font.pixelSize: 12
                    implicitWidth: 90
                    implicitHeight: 36
                    background: Rectangle {
                        color: parent.pressed ? "#1565C0" : "#1976D2"
                        radius: 8
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "#FFFFFF"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: mainWindow.saveCustomNameAction()
                }
            }
        }

        function openDialog(sensor) {
            currentSensor = sensor
            customSensorName = sensor.name
            nameInput.text = customSensorName
            open()
            nameInput.forceActiveFocus()
        }
    }

    // Глобальная функция сохранения
    function saveCustomNameAction() {
        if (currentSensor) {
            var newName = nameInput.text.trim();
            sensorNameManager.saveSensorName(currentSensor.id, newName);
            console.log("Saved custom name:", newName, "for unique ID:", currentSensor.id);
            sensorEditorPopup.close();
        }
    }
}