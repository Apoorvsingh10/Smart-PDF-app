import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Dialogs
import PDF_ToolKit 1.0

Page {
    id: root
    property PDFEngine pdfEngine
    signal back()
    signal compressed(string path)
    signal showToast(string message, string type)

    property url selectedFile
    property string selectedFileName: ""
    property int compressionLevel: 1
    property string expectedOutputPath: ""

    background: Rectangle {
        color: Theme.background
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
                text: qsTr("Compress PDF")
                font.pixelSize: Theme.fontSizeTitle
                font.weight: Font.DemiBold
                color: Theme.surfaceForeground
                Layout.fillWidth: true
            }
        }
    }

    FileDialog {
        id: fileDialog
        title: qsTr("Select PDF to compress")
        nameFilters: ["PDF files (*.pdf)"]
        onAccepted: {
            root.selectedFile = selectedFile
            root.selectedFileName = FileUtils.getFileName(selectedFile)
        }
    }

    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: parent.width
            spacing: 0

            // Empty state
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: root.height - Theme.appBarHeight - 80
                visible: selectedFileName === ""

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
                            color: Qt.rgba(Theme.tertiary.r, Theme.tertiary.g, Theme.tertiary.b, 0.1)

                            Image {
                                anchors.centerIn: parent
                                source: "qrc:/PDF_ToolKit/resources/icons/compress.svg"
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
                            text: qsTr("Compress PDF")
                            font.pixelSize: Theme.fontSizeHeadline
                            font.weight: Font.Bold
                            color: Theme.surfaceForeground
                        }

                        Label {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: 280
                            text: qsTr("Reduce your PDF file size while maintaining quality")
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
                        Material.background: Theme.tertiary
                        Material.foreground: Theme.tertiaryForeground
                        font.weight: Font.DemiBold
                        onClicked: fileDialog.open()
                    }
                }
            }

            // File selected state
            ColumnLayout {
                Layout.fillWidth: true
                Layout.margins: Theme.spacingMedium
                spacing: Theme.spacingLarge
                visible: selectedFileName !== ""

                // Selected file card
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 80
                    radius: Theme.radiusMedium
                    color: Theme.cardSurface
                    border.width: 1
                    border.color: Theme.outlineVariant

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: Theme.spacingMedium
                        spacing: Theme.spacingMedium

                        Rectangle {
                            Layout.preferredWidth: 52
                            Layout.preferredHeight: 52
                            radius: Theme.radiusSmall
                            color: Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.1)

                            Image {
                                anchors.centerIn: parent
                                source: "qrc:/PDF_ToolKit/resources/icons/pdf.svg"
                                sourceSize.width: Theme.iconSizeLarge
                                sourceSize.height: Theme.iconSizeLarge
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Label {
                                text: selectedFileName
                                font.pixelSize: Theme.fontSizeBody
                                font.weight: Font.Medium
                                color: Theme.surfaceForeground
                                elide: Text.ElideMiddle
                                Layout.fillWidth: true
                            }

                            Label {
                                text: qsTr("Ready to compress")
                                font.pixelSize: Theme.fontSizeCaption
                                color: Theme.success
                            }
                        }

                        ToolButton {
                            icon.source: "qrc:/PDF_ToolKit/resources/icons/delete.svg"
                            onClicked: {
                                root.selectedFile = ""
                                root.selectedFileName = ""
                            }

                            background: Rectangle {
                                radius: Theme.radiusSmall
                                color: parent.hovered ? Theme.errorContainer : "transparent"
                            }
                        }
                    }
                }

                // Compression level section
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingMedium

                    Label {
                        text: qsTr("Compression Level")
                        font.pixelSize: Theme.fontSizeTitle
                        font.weight: Font.DemiBold
                        color: Theme.surfaceForeground
                    }

                    Label {
                        text: qsTr("Choose the balance between file size and quality")
                        font.pixelSize: Theme.fontSizeCaption
                        color: Theme.surfaceForegroundVariant
                    }

                    CompressionOption {
                        Layout.fillWidth: true
                        title: qsTr("Low Compression")
                        description: qsTr("Best quality, larger file")
                        reduction: qsTr("~20-30%")
                        icon: "💎"
                        isSelected: compressionLevel === 0
                        accentColor: Theme.success
                        onClicked: compressionLevel = 0
                    }

                    CompressionOption {
                        Layout.fillWidth: true
                        title: qsTr("Medium Compression")
                        description: qsTr("Balanced quality and size")
                        reduction: qsTr("~50-60%")
                        icon: "⚡"
                        isSelected: compressionLevel === 1
                        accentColor: Theme.tertiary
                        onClicked: compressionLevel = 1
                    }

                    CompressionOption {
                        Layout.fillWidth: true
                        title: qsTr("High Compression")
                        description: qsTr("Smallest file, lower quality")
                        reduction: qsTr("~70-80%")
                        icon: "🗜️"
                        isSelected: compressionLevel === 2
                        accentColor: Theme.warning
                        onClicked: compressionLevel = 2
                    }
                }

                Item { Layout.preferredHeight: Theme.spacingLarge }

                Button {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Theme.buttonHeight
                    text: qsTr("Compress PDF")
                    icon.source: "qrc:/PDF_ToolKit/resources/icons/compress.svg"
                    Material.background: Theme.tertiary
                    Material.foreground: Theme.tertiaryForeground
                    font.weight: Font.DemiBold
                    enabled: selectedFileName !== "" && !pdfEngine.isProcessing
                    opacity: enabled ? 1 : 0.5

                    onClicked: {
                        var fileName = FileUtils.getFileName(root.selectedFile)
                        var baseName = fileName.replace(/\.pdf$/i, "")
                        expectedOutputPath = FileUtils.getTempPath() + "/" + baseName + "_compressed.pdf"

                        pdfEngine.compressPDF(root.selectedFile.toString(), expectedOutputPath, compressionLevel)
                    }
                }

                Item { Layout.preferredHeight: Theme.spacingMedium }
            }
        }
    }

    component CompressionOption: Rectangle {
        id: option
        property string title
        property string description
        property string reduction
        property string icon
        property bool isSelected: false
        property color accentColor: Theme.primary
        signal clicked()

        implicitHeight: 80
        radius: Theme.radiusMedium
        color: isSelected ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.1) : Theme.cardSurface
        border.width: isSelected ? 2 : 1
        border.color: isSelected ? accentColor : Theme.outlineVariant

        Behavior on color {
            ColorAnimation { duration: Theme.animationFast }
        }

        Behavior on border.color {
            ColorAnimation { duration: Theme.animationFast }
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: Theme.spacingMedium
            spacing: Theme.spacingMedium

            Rectangle {
                Layout.preferredWidth: 48
                Layout.preferredHeight: 48
                radius: Theme.radiusSmall
                color: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, isSelected ? 0.2 : 0.1)

                Label {
                    anchors.centerIn: parent
                    text: icon
                    font.pixelSize: Theme.fontSizeTitle
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Label {
                    text: title
                    font.pixelSize: Theme.fontSizeBody
                    font.weight: Font.DemiBold
                    color: isSelected ? accentColor : Theme.surfaceForeground
                }

                Label {
                    text: description
                    font.pixelSize: Theme.fontSizeCaption
                    color: Theme.surfaceForegroundVariant
                }
            }

            Rectangle {
                Layout.preferredWidth: reductionLabel.width + Theme.spacingMedium
                Layout.preferredHeight: 28
                radius: Theme.radiusFull
                color: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.15)

                Label {
                    id: reductionLabel
                    anchors.centerIn: parent
                    text: reduction
                    font.pixelSize: Theme.fontSizeTiny
                    font.weight: Font.DemiBold
                    color: accentColor
                }
            }

            RadioButton {
                checked: isSelected
                onClicked: option.clicked()
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: option.clicked()
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
            if (success && expectedOutputPath !== "") {
                var outputPath = expectedOutputPath
                expectedOutputPath = ""
                
                root.compressed(outputPath)
            } else {
                root.showToast(message, success ? "success" : "error")
            }
        }
    }
}
