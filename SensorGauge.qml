import QtQuick 2.15

Canvas {
    id: root
    antialiasing: true

    property real value: 0
    property real maxValue: 100
    property string sensorType: ""

    onValueChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d");
        ctx.reset();

        var w = width;
        var h = height;
        var cx = w / 2;
        var cy = h / 2;
        var r = Math.min(w, h) / 2 - 5;

        var activeColor = "#388E3C";
        if (value > 85) activeColor = "#D32F2F";
        else if (value > 70) activeColor = "#F57C00";

        ctx.beginPath();
        ctx.arc(cx, cy, r, Math.PI * 0.75, Math.PI * 2.25);
        ctx.lineWidth = 6;
        ctx.strokeStyle = "#E0E0E0";
        ctx.lineCap = "round";
        ctx.stroke();

        var progress = Math.min(value / maxValue, 1.0);
        var endAngle = Math.PI * 0.75 + (Math.PI * 1.5 * progress);

        ctx.beginPath();
        ctx.arc(cx, cy, r, Math.PI * 0.75, endAngle);
        ctx.lineWidth = 6;
        ctx.strokeStyle = activeColor;
        ctx.lineCap = "round";
        ctx.stroke();
    }
}