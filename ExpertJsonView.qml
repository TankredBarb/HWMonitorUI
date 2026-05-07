import QtQuick 2.15
import QtQuick.Controls.Basic 2.15
import QtQuick.Layouts 1.15

Popup {
    id: root
    modal: true
    focus: true
    parent: mainWindow.contentItem
    anchors.centerIn: parent
    width: parent.width - 40
    height: parent.height - 40
    padding: 0
    
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    property real maxLineWidth: 0

    background: Rectangle {
        color: "#0C0C0C"
        radius: 12
        border.color: "#333333"
        border.width: 1
    }

    // JSON Processing Logic
    function refreshModel() {
        try {
            var raw = appController.rawJson;
            if (!raw) return;
            
            var obj = JSON.parse(raw);
            var lines = [];
            var currentMax = 0;
            
            function process(item, key, level) {
                var indent = "  ".repeat(level);
                var prefix = key ? '"' + key + '": ' : "";
                var lineText = "";
                var color = "#AAAAAA";
                
                if (Array.isArray(item)) {
                    lineText = indent + prefix + "[";
                    lines.push({ text: lineText, color: color });
                    item.forEach(function(v, i) { process(v, null, level + 1); });
                    lines.push({ text: indent + "]", color: color });
                } else if (typeof item === 'object' && item !== null) {
                    lineText = indent + prefix + "{";
                    lines.push({ text: lineText, color: color });
                    Object.keys(item).forEach(function(k) { process(item[k], k, level + 1); });
                    lines.push({ text: indent + "}", color: color });
                } else {
                    var valStr = typeof item === 'string' ? '"' + item + '"' : item;
                    var valColor = typeof item === 'number' ? "#B5CEA8" : (typeof item === 'boolean' ? "#569CD6" : "#CE9178");
                    lineText = indent + prefix + valStr;
                    lines.push({ text: lineText, color: valColor });
                }
                
                // Rough estimate for width: 40 (line number) + length * 7.5px
                var estimatedWidth = 50 + (lineText.length * 7.5);
                if (estimatedWidth > currentMax) currentMax = estimatedWidth;
            }
            
            process(obj, null, 0);
            root.maxLineWidth = currentMax;
            jsonModel.clear();
            for (var i = 0; i < lines.length; i++) {
                jsonModel.append(lines[i]);
            }
        } catch (e) {
            console.log("JSON Parse Error: " + e);
        }
    }

    ListModel { id: jsonModel }

    // Removed automatic Connections to appController.rawJsonChanged

    onVisibleChanged: {
        if (visible && jsonModel.count === 0) refreshModel();
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Header
        Rectangle {
            Layout.fillWidth: true
            height: 40
            color: "#1E1E1E"
            radius: 12
            
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width; height: 10; color: "#1E1E1E"
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 4
                
                Text {
                    text: "JSON"
                    color: "#00FF41"
                    font.family: "Consolas"
                    font.pixelSize: 12
                    font.weight: Font.Bold
                }

                Button {
                    flat: true
                    implicitWidth: 65
                    onClicked: root.refreshModel()
                    contentItem: RowLayout {
                        spacing: 2
                        Text { text: "🔄"; font.pixelSize: 10 }
                        Text { text: "Refresh"; color: "#00FF41"; font.pixelSize: 10; font.weight: Font.Bold }
                    }
                    background: Rectangle {
                        color: parent.hovered ? "#2A2A2A" : "transparent"
                        radius: 4
                    }
                }

                Button {
                    flat: true
                    implicitWidth: 55
                    onClicked: {
                        dummyText.text = appController.rawJson
                        dummyText.selectAll()
                        dummyText.copy()
                    }
                    contentItem: RowLayout {
                        spacing: 2
                        Text { text: "📋"; font.pixelSize: 10 }
                        Text { text: "Copy"; color: "#AAAAAA"; font.pixelSize: 10; font.weight: Font.Bold }
                    }
                    background: Rectangle {
                        color: parent.hovered ? "#2A2A2A" : "transparent"
                        radius: 4
                    }
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: jsonModel.count + " l."
                    color: "#888888"
                    font.family: "Consolas"
                    font.pixelSize: 10
                    Layout.alignment: Qt.AlignRight
                }
            }
        }

        // Tree List
        ScrollView {
            id: jsonScrollView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            
            ScrollBar.horizontal.policy: ScrollBar.AsNeeded
            ScrollBar.vertical.policy: ScrollBar.AsNeeded

            ListView {
                id: jsonListView
                width: Math.max(jsonScrollView.availableWidth, root.maxLineWidth)
                model: jsonModel
                reuseItems: true
                cacheBuffer: 500
                
                delegate: Item {
                    width: jsonListView.width
                    height: 18
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        spacing: 10
                        
                        Text {
                            text: (index + 1)
                            color: "#555555"
                            font.family: "Consolas"
                            font.pixelSize: 10
                            Layout.preferredWidth: 35
                        }

                        Text {
                            text: model.text
                            color: model.color
                            font.family: "Consolas, Monaco, monospace"
                            font.pixelSize: 12
                            Layout.fillWidth: true
                        }
                    }
                }
            }
        }
    }

    TextEdit {
        id: dummyText
        visible: false
    }
}
