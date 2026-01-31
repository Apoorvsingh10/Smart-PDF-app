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
    property alias source: pdfDocument.source
    property bool showBackButton: false
    property bool isPreview: false
    property bool isSaved: false
    property string savedFilePath: ""
    property bool pendingShare: false

    onSourceChanged: {
        // Reset saved state when loading a new file
        if (isPreview) {
            isSaved = false
            savedFilePath = ""
        }
    }

    signal back()
    signal saved(string fileUrl)
    signal showToast(string message, string type)

    background: Rectangle {
        color: Theme.background
    }

    PDFDocument {
        id: pdfDocument
        onLoadError: (error) => {
            console.log("ViewerScreen: Load error:", error)
            root.showToast(error, "error")
        }
    }

    PdfDocument {
        id: pdfViewerDocument
        source: pdfDocument.source
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
            anchors.rightMargin: Theme.spacingSmall
            spacing: Theme.spacingSmall

            ToolButton {
                icon.source: "qrc:/PDF_ToolKit/resources/icons/back.svg"
                icon.width: Theme.iconSizeMedium
                icon.height: Theme.iconSizeMedium
                visible: root.showBackButton
                onClicked: root.back()
            }

            Label {
                text: pdfDocument.isLoaded ? pdfDocument.fileName : qsTr("PDF Viewer")
                font.pixelSize: Theme.fontSizeTitle
                font.weight: Font.DemiBold
                color: Theme.surfaceForeground
                elide: Text.ElideMiddle
                Layout.fillWidth: true
            }

            // Page info badge
            Rectangle {
                visible: pdfDocument.isLoaded
                Layout.preferredWidth: pageInfoLabel.width + Theme.spacingMedium
                Layout.preferredHeight: 24
                radius: 12
                color: Theme.surfaceContainerHigh

                Label {
                    id: pageInfoLabel
                    anchors.centerIn: parent
                    text: qsTr("%1 pages").arg(pdfViewerDocument.pageCount)
                    font.pixelSize: Theme.fontSizeCaption
                    color: Theme.surfaceVariantForeground
                }
            }

            ToolButton {
                icon.source: "qrc:/PDF_ToolKit/resources/icons/save.svg"
                icon.width: Theme.iconSizeMedium
                icon.height: Theme.iconSizeMedium
                visible: pdfDocument.isLoaded
                onClicked: saveDialog.open()
                
                ToolTip.visible: hovered
                ToolTip.text: root.isPreview ? qsTr("Save PDF") : qsTr("Save Copy")
            }

            ToolButton {
                icon.source: "qrc:/PDF_ToolKit/resources/icons/share.svg"
                icon.width: Theme.iconSizeMedium
                icon.height: Theme.iconSizeMedium
                visible: pdfDocument.isLoaded
                onClicked: {
                    if (root.isPreview && !root.isSaved) {
                        // In preview mode, need to save first before sharing
                        root.pendingShare = true
                        saveDialog.open()
                    } else {
                        // Share using platform share functionality
                        var pathToShare = root.savedFilePath !== "" ? root.savedFilePath : pdfDocument.filePath
                        if (pathToShare !== "") {
                            ShareUtils.shareFile(pathToShare, "application/pdf")
                        } else {
                            root.showToast(qsTr("Cannot share: file not available"), "error")
                        }
                    }
                }

                ToolTip.visible: hovered
                ToolTip.text: root.isPreview && !root.isSaved ? qsTr("Save & Share") : qsTr("Share PDF")
            }

            ToolButton {
                icon.source: "qrc:/PDF_ToolKit/resources/icons/folder.svg"
                icon.width: Theme.iconSizeMedium
                icon.height: Theme.iconSizeMedium
                visible: !root.showBackButton
                onClicked: fileDialog.open()
                
                ToolTip.visible: hovered
                ToolTip.text: qsTr("Open PDF")
            }
        }
    }

    FileDialog {
        id: saveDialog
        title: root.pendingShare ? qsTr("Save PDF to Share") : qsTr("Save Copy")
        fileMode: FileDialog.SaveFile
        nameFilters: ["PDF files (*.pdf)"]
        defaultSuffix: "pdf"
        onAccepted: {
            if (FileUtils.copyFile(pdfDocument.source, selectedFile)) {
                root.showToast(qsTr("File saved successfully"), "success")

                // Retrieve the path of the saved file
                var savedPath = selectedFile.toString()

                // Log recent activity now that it is explicitly saved
                RecentActivityModel.addActivity(FileUtils.getFileName(selectedFile), "saved", savedPath)

                // Update state
                if (root.isPreview) {
                    root.isSaved = true
                    root.savedFilePath = savedPath
                }

                // If we were waiting to share, do it now
                if (root.pendingShare) {
                    root.pendingShare = false
                    ShareUtils.shareFile(savedPath, "application/pdf")
                }

                root.saved(savedPath)
            } else {
                root.showToast(qsTr("Failed to save file"), "error")
                root.pendingShare = false
            }
        }
        onRejected: {
            root.pendingShare = false
        }
    }

    FileDialog {
        id: fileDialog
        title: qsTr("Select PDF")
        nameFilters: ["PDF files (*.pdf)"]
        onAccepted: {
            pdfDocument.source = selectedFile
            // Log view activity
            RecentActivityModel.addActivity(FileUtils.getFileName(selectedFile), "viewed", selectedFile.toString())
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Empty state
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !pdfDocument.isLoaded

            ColumnLayout {
                anchors.centerIn: parent
                spacing: Theme.spacingLarge
                width: parent.width - Theme.spacingXLarge * 2

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 140
                    Layout.preferredHeight: 140
                    radius: 70
                    color: Theme.surfaceContainer

                    Rectangle {
                        anchors.centerIn: parent
                        width: 100
                        height: 100
                        radius: 50
                        color: Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.1)

                        Rectangle {
                            anchors.centerIn: parent
                            width: 60
                            height: 75
                            radius: Theme.radiusSmall
                            color: "#FFFFFF"
                            border.width: 2
                            border.color: Theme.outlineVariant

                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottomMargin: 8
                                width: 40
                                height: 18
                                radius: 4
                                color: Theme.error

                                Label {
                                    anchors.centerIn: parent
                                    text: "PDF"
                                    font.pixelSize: 9
                                    font.weight: Font.Bold
                                    color: "#FFFFFF"
                                }
                            }

                            Column {
                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.margins: 8
                                spacing: 4

                                Repeater {
                                    model: 3
                                    Rectangle {
                                        width: parent.width * (1 - index * 0.15)
                                        height: 3
                                        radius: 1.5
                                        color: Theme.outlineVariant
                                    }
                                }
                            }
                        }
                    }
                }

                ColumnLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Theme.spacingSmall

                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("View Your PDFs")
                        font.pixelSize: Theme.fontSizeHeadline
                        font.weight: Font.Bold
                        color: Theme.surfaceForeground
                    }

                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 280
                        text: qsTr("Open any PDF file to view, scroll through pages, and save copies")
                        font.pixelSize: Theme.fontSizeBody
                        color: Theme.surfaceVariantForeground
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                    }
                }

                Button {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 200
                    Layout.preferredHeight: Theme.buttonHeight
                    text: qsTr("Open PDF")
                    icon.source: "qrc:/PDF_ToolKit/resources/icons/folder.svg"
                    Material.background: Theme.warning
                    Material.foreground: Theme.warningForeground
                    font.weight: Font.DemiBold
                    onClicked: fileDialog.open()
                }
            }
        }

        // PDF loaded state
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: pdfDocument.isLoaded

            PdfMultiPageView {
                anchors.fill: parent
                document: pdfViewerDocument
                visible: pdfDocument.isLoaded && pdfDocument.hasPdfViewer
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: Theme.spacingLarge
                width: parent.width - Theme.spacingLarge * 2
                visible: pdfDocument.isLoaded && !pdfDocument.hasPdfViewer

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 100
                    Layout.preferredHeight: 100
                    radius: Theme.radiusMedium
                    color: Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.1)

                    Image {
                        anchors.centerIn: parent
                        source: "qrc:/PDF_ToolKit/resources/icons/pdf.svg"
                        sourceSize.width: Theme.iconSizeXLarge
                        sourceSize.height: Theme.iconSizeXLarge
                    }
                }

                ColumnLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Theme.spacingSmall

                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: pdfDocument.fileName
                        font.pixelSize: Theme.fontSizeTitle
                        font.weight: Font.DemiBold
                        color: Theme.surfaceForeground
                        elide: Text.ElideMiddle
                        Layout.maximumWidth: 300
                        horizontalAlignment: Text.AlignHCenter
                    }

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: Theme.spacingMedium

                        Rectangle {
                            Layout.preferredHeight: 28
                            Layout.preferredWidth: sizeLabel.width + Theme.spacingMedium
                            radius: Theme.radiusFull
                            color: Theme.surfaceContainer

                            Label {
                                id: sizeLabel
                                anchors.centerIn: parent
                                text: qsTr("%1 KB").arg(Math.round(pdfDocument.fileSize / 1024))
                                font.pixelSize: Theme.fontSizeCaption
                                color: Theme.surfaceVariantForeground
                            }
                        }
                    }
                }

                ColumnLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Theme.spacingSmall

                    Button {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 220
                        Layout.preferredHeight: Theme.buttonHeight
                        text: qsTr("Open in Default Viewer")
                        icon.source: "qrc:/PDF_ToolKit/resources/icons/viewer.svg"
                        Material.background: Theme.primary
                        Material.foreground: Theme.primaryForeground
                        font.weight: Font.Medium
                        onClicked: pdfDocument.openExternal()
                    }

                    Button {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 220
                        text: qsTr("Choose Different PDF")
                        flat: true
                        onClicked: fileDialog.open()
                    }
                }
            }
        }
    }
}
