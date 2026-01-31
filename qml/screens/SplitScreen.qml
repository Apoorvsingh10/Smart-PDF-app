import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Dialogs
import QtQuick.Pdf
import PDF_ToolKit 1.0

Page {
    id: root
    property PDFEngine pdfEngine
    signal back()
    signal split(string path)
    signal showToast(string message, string type)

    background: Rectangle {
        color: Theme.background
    }

    PdfDocument {
        id: pdfDoc
    }

    ListModel {
        id: pagesModel
    }

    header: ToolBar {
        Material.background: Theme.surfaceContainer
        height: Theme.appBarHeight

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: Theme.outlineVariant
            opacity: 0.3
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Theme.spacingSmall
            anchors.rightMargin: Theme.spacingMedium

            ToolButton {
                icon.source: "qrc:/PDF_ToolKit/resources/icons/back.svg"
                icon.width: Theme.iconSizeMedium
                icon.height: Theme.iconSizeMedium
                onClicked: root.back()
            }

            Label {
                text: pdfDoc.source.toString() !== "" ? qsTr("Edit Pages") : qsTr("Split PDF")
                font.pixelSize: Theme.fontSizeTitle
                font.weight: Font.DemiBold
                color: Theme.surfaceForeground
                Layout.fillWidth: true
            }

            // Page count badge
            Rectangle {
                visible: pdfDoc.source.toString() !== ""
                Layout.preferredWidth: pageCountLabel.width + Theme.spacingMedium
                Layout.preferredHeight: 24
                radius: 12
                color: Theme.secondaryContainer

                Label {
                    id: pageCountLabel
                    anchors.centerIn: parent
                    text: qsTr("%1 pages").arg(pdfDoc.pageCount)
                    font.pixelSize: Theme.fontSizeCaption
                    font.weight: Font.Medium
                    color: Theme.secondaryForegroundContainer
                }
            }

            ToolButton {
                icon.source: "qrc:/PDF_ToolKit/resources/icons/folder.svg"
                visible: pdfDoc.source.toString() !== ""
                onClicked: {
                    pdfDoc.source = ""
                    pagesModel.clear()
                }
                
                ToolTip.visible: hovered
                ToolTip.text: qsTr("Choose different file")
            }
        }
    }

    FileDialog {
        id: fileDialog
        title: qsTr("Select PDF to split")
        nameFilters: ["PDF files (*.pdf)"]
        onAccepted: {
            pdfDoc.source = selectedFile
            pagesModel.clear()
            for (var i = 0; i < pdfDoc.pageCount; i++) {
                pagesModel.append({"pageNumber": i + 1, "excluded": false})
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Empty state
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: pdfDoc.source.toString() === ""

            ColumnLayout {
                anchors.centerIn: parent
                spacing: Theme.spacingLarge
                width: parent.width - Theme.spacingXLarge * 2

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 120
                    Layout.preferredHeight: 120
                    radius: 60
                    color: Theme.surfaceContainer

                    Rectangle {
                        anchors.centerIn: parent
                        width: 80
                        height: 80
                        radius: 40
                        color: Qt.rgba(Theme.secondary.r, Theme.secondary.g, Theme.secondary.b, 0.1)

                        Image {
                            anchors.centerIn: parent
                            source: "qrc:/PDF_ToolKit/resources/icons/split.svg"
                            sourceSize.width: Theme.iconSizeXLarge
                            sourceSize.height: Theme.iconSizeXLarge
                            opacity: 0.7
                        }
                    }
                }

                ColumnLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Theme.spacingSmall

                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("Split Your PDF")
                        font.pixelSize: Theme.fontSizeHeadline
                        font.weight: Font.Bold
                        color: Theme.surfaceForeground
                    }

                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 280
                        text: qsTr("Select pages you want to keep and create a new PDF with just those pages")
                        font.pixelSize: Theme.fontSizeBody
                        color: Theme.surfaceForegroundVariant
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                    }
                }

                Button {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 200
                    Layout.preferredHeight: Theme.buttonHeight
                    text: qsTr("Select PDF")
                    icon.source: "qrc:/PDF_ToolKit/resources/icons/folder.svg"
                    Material.background: Theme.secondary
                    Material.foreground: Theme.secondaryForeground
                    font.weight: Font.DemiBold
                    onClicked: fileDialog.open()
                }
            }
        }

        // Page grid view
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: pdfDoc.source.toString() !== ""

            GridView {
                id: pagesGrid
                anchors.fill: parent
                anchors.margins: Theme.spacingMedium
                cellWidth: Math.max(160, (width - Theme.spacingMedium) / 2)
                cellHeight: 240
                model: pagesModel
                clip: true

                flickDeceleration: 3000
                maximumFlickVelocity: 3000

                delegate: Item {
                    width: pagesGrid.cellWidth - Theme.spacingSmall
                    height: pagesGrid.cellHeight - Theme.spacingSmall

                    Rectangle {
                        id: pageCard
                        anchors.fill: parent
                        anchors.margins: Theme.spacingTiny
                        radius: Theme.radiusMedium
                        color: model.excluded ? Theme.surfaceVariant : Theme.cardSurface
                        border.width: model.excluded ? 0 : 1
                        border.color: Theme.outlineVariant
                        opacity: model.excluded ? 0.6 : 1.0

                        Behavior on opacity {
                            NumberAnimation { duration: Theme.animationFast }
                        }

                        Behavior on color {
                            ColorAnimation { duration: Theme.animationFast }
                        }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Theme.spacingSmall
                            spacing: Theme.spacingSmall

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: Theme.radiusSmall
                                color: "#FFFFFF"
                                clip: true

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: -1
                                    z: -1
                                    radius: parent.radius + 1
                                    color: "transparent"
                                    
                                    Rectangle {
                                        anchors.fill: parent
                                        anchors.topMargin: 2
                                        radius: parent.radius
                                        color: Theme.shadowLight
                                    }
                                }

                                PdfPageImage {
                                    anchors.fill: parent
                                    anchors.margins: 2
                                    document: pdfDoc
                                    currentFrame: model.pageNumber - 1
                                    asynchronous: true
                                    fillMode: Image.PreserveAspectFit
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    color: Theme.background
                                    opacity: model.excluded ? 0.7 : 0
                                    visible: model.excluded

                                    Behavior on opacity {
                                        NumberAnimation { duration: Theme.animationFast }
                                    }

                                    Image {
                                        anchors.centerIn: parent
                                        source: "qrc:/PDF_ToolKit/resources/icons/delete.svg"
                                        sourceSize.width: Theme.iconSizeLarge
                                        sourceSize.height: Theme.iconSizeLarge
                                        opacity: 0.5
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Theme.spacingSmall

                                Rectangle {
                                    Layout.preferredWidth: 28
                                    Layout.preferredHeight: 28
                                    radius: 14
                                    color: model.excluded ? Theme.surfaceVariant : Theme.secondaryContainer

                                    Label {
                                        anchors.centerIn: parent
                                        text: model.pageNumber.toString()
                                        font.pixelSize: Theme.fontSizeCaption
                                        font.weight: Font.DemiBold
                                        color: model.excluded ? Theme.surfaceForegroundVariant : Theme.secondaryForegroundContainer
                                    }
                                }

                                Label {
                                    Layout.fillWidth: true
                                    text: model.excluded ? qsTr("Excluded") : qsTr("Included")
                                    font.pixelSize: Theme.fontSizeTiny
                                    color: Theme.surfaceForegroundVariant
                                }

                                Rectangle {
                                    Layout.preferredWidth: 36
                                    Layout.preferredHeight: 36
                                    radius: Theme.radiusSmall
                                    color: model.excluded ? Theme.successContainer : Theme.errorContainer

                                    Image {
                                        anchors.centerIn: parent
                                        source: model.excluded ? "qrc:/PDF_ToolKit/resources/icons/add.svg" : "qrc:/PDF_ToolKit/resources/icons/delete.svg"
                                        sourceSize.width: Theme.iconSizeSmall
                                        sourceSize.height: Theme.iconSizeSmall
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            pagesModel.setProperty(index, "excluded", !model.excluded)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Bottom action bar
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 100
            color: Theme.surfaceContainer
            visible: pdfDoc.source.toString() !== ""

            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: Theme.outlineVariant
                opacity: 0.3
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.spacingMedium
                spacing: Theme.spacingSmall

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingSmall

                    Rectangle {
                        Layout.preferredWidth: 8
                        Layout.preferredHeight: 8
                        radius: 4
                        color: {
                            var included = 0
                            for (var i = 0; i < pagesModel.count; i++) {
                                if (!pagesModel.get(i).excluded) included++
                            }
                            return included > 0 ? Theme.success : Theme.error
                        }
                    }

                    Label {
                        Layout.fillWidth: true
                        text: {
                            var included = 0
                            for (var i = 0; i < pagesModel.count; i++) {
                                if (!pagesModel.get(i).excluded) included++
                            }
                            return qsTr("%1 of %2 pages selected").arg(included).arg(pagesModel.count)
                        }
                        font.pixelSize: Theme.fontSizeCaption
                        color: Theme.surfaceForegroundVariant
                    }

                    Button {
                        text: qsTr("Select All")
                        flat: true
                        font.pixelSize: Theme.fontSizeTiny
                        onClicked: {
                            for (var i = 0; i < pagesModel.count; i++) {
                                pagesModel.setProperty(i, "excluded", false)
                            }
                        }
                    }
                }

                Button {
                    id: splitButton
                    property string expectedOutputPath: ""

                    Layout.fillWidth: true
                    Layout.preferredHeight: Theme.buttonHeight
                    text: qsTr("Create Split PDF")
                    icon.source: "qrc:/PDF_ToolKit/resources/icons/split.svg"
                    Material.background: Theme.secondary
                    Material.foreground: Theme.secondaryForeground
                    font.weight: Font.DemiBold
                    enabled: !pdfEngine.isProcessing
                    opacity: enabled ? 1 : 0.5

                    onClicked: {
                        var selectedPages = []
                        for (var i = 0; i < pagesModel.count; i++) {
                            if (!pagesModel.get(i).excluded) {
                                selectedPages.push(i)
                            }
                        }

                        if (selectedPages.length === 0) {
                            root.showToast(qsTr("Please select at least one page"), "error")
                            return
                        }

                        var fileName = FileUtils.getFileName(pdfDoc.source)
                        var baseName = fileName.replace(/\.pdf$/i, "")
                        expectedOutputPath = FileUtils.getTempPath() + "/" + baseName + "_split.pdf"

                        pdfEngine.splitPDF(pdfDoc.source.toString(), FileUtils.getTempPath(), selectedPages)
                    }
                }
            }
        }
    }

    ProgressOverlay {
        visible: pdfEngine.isProcessing
        progress: pdfEngine.progress
        message: pdfEngine.currentOperation
    }

    Connections {
        target: pdfEngine
        function onOperationCompleted(success, message) {
            if (success && splitButton.expectedOutputPath !== "") {
                var outputPath = splitButton.expectedOutputPath
                splitButton.expectedOutputPath = ""
                
                root.split(outputPath)
            } else {
                root.showToast(message, success ? "success" : "error")
            }
        }
    }
}
