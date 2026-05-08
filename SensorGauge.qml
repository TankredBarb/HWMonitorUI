import QtQuick 2.15

Item {
    id: root

    property real value: 0
    property real maxValue: 100
    property string sensorType: ""
    property real displayValue: value
    property real progress: Math.max(0, Math.min(1, displayValue / Math.max(1, maxValue)))
    property color accentColor: statusColor()
    property real gaugeSize: Math.max(1, Math.min(width, height))
    property real strokeWidth: Math.max(5, Math.min(8, gaugeSize * 0.11))
    property int valueFontSize: Math.max(10, Math.min(16, Math.round(gaugeSize * 0.22)))
    property int unitFontSize: Math.max(9, Math.min(12, Math.round(gaugeSize * 0.17)))

    Behavior on displayValue {
        NumberAnimation { duration: 420; easing.type: Easing.OutCubic }
    }

    onValueChanged: displayValue = value
    onDisplayValueChanged: gaugeCanvas.requestPaint()
    onAccentColorChanged: gaugeCanvas.requestPaint()
    onWidthChanged: gaugeCanvas.requestPaint()
    onHeightChanged: gaugeCanvas.requestPaint()

    function statusColor() {
        if (root.sensorType === "Temperature") {
            if (root.displayValue >= 85) return "#D92D20";
            if (root.displayValue >= 70) return "#F79009";
            return "#2EAD4F";
        }
        if (root.sensorType === "Load") {
            if (root.displayValue >= 90) return "#D92D20";
            if (root.displayValue >= 75) return "#F79009";
            return "#2F80ED";
        }
        return "#2F80ED";
    }

    Canvas {
        id: gaugeCanvas

        anchors.fill: parent
        antialiasing: true
        renderStrategy: Canvas.Cooperative
        renderTarget: Canvas.Image

        onPaint: {
            var ctx = getContext("2d");
            if (!ctx) return;

            ctx.save();
            ctx.clearRect(0, 0, width, height);

            var size = Math.min(width, height);
            var cx = width / 2;
            var cy = height / 2;
            var radius = size / 2 - root.strokeWidth / 2 - 2;
            var startAngle = Math.PI * 0.72;
            var sweep = Math.PI * 1.56;
            var endAngle = startAngle + sweep * root.progress;

            ctx.beginPath();
            ctx.arc(cx, cy, radius, startAngle, startAngle + sweep);
            ctx.lineWidth = root.strokeWidth;
            ctx.strokeStyle = "#EEF2F6";
            ctx.lineCap = "round";
            ctx.stroke();

            ctx.beginPath();
            ctx.arc(cx, cy, radius, startAngle, endAngle);
            ctx.lineWidth = root.strokeWidth;
            ctx.strokeStyle = root.accentColor;
            ctx.lineCap = "round";
            ctx.stroke();

            ctx.restore();
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 0

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Math.round(root.displayValue)
            font.family: "Consolas, Monaco, monospace"
            font.pixelSize: root.valueFontSize
            font.weight: Font.Bold
            color: "#1F2937"
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.sensorType === "Temperature" ? "C" : "%"
            font.family: "Segoe UI"
            font.pixelSize: root.unitFontSize
            font.weight: Font.Bold
            color: root.accentColor
        }
    }
}
