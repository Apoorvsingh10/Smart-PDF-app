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
    signal merged(string path)
    signal showToast(string message, string type)

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
                text: qsTr("Merge PDFs")
                font.pixelSize: Theme.fontSizeTitle
                font.weight: Font.DemiBold
                color: Theme.surfaceForeground
                Layout.fillWidth: true
            }

            // File count badge
            Rectangle {
                visible: filesModel.count > 0
                Layout.preferredWidth: countLabel.width + Theme.spacingMedium
                Layout.preferredHeight: 24
                radius: 12
                color: Theme.primaryContainer

                Label {
                    id: countLabel
                    anchors.centerIn: parent
                    text: filesModel.count.toString()
                    font.pixelSize: Theme.fontSizeCaption
                    font.weight: Font.DemiBold
                    color: Theme.primaryForegroundContainer
                }
            }
        }
    }

    ListModel {
        id: filesModel
    }

    FileDialog {
        id: fileDialog
        title: qsTr("Select PDF")
        nameFilters: ["PDF files (*.pdf)"]
        onAccepted: {
            filesModel.append({ "url": selectedFile, "name": FileUtils.getFileName(selectedFile) })
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // File list area
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Empty state
            ColumnLayout {
                anchors.centerIn: parent
                spacing: Theme.spacingMedium
                visible: filesModel.count === 0
                opacity: filesModel.count === 0 ? 1 : 0

                Behavior on opacity {
                    NumberAnimation { duration: Theme.animationNormal }
                }

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 100
                    Layout.preferredHeight: 100
                    radius: 50
                    color: Theme.surfaceContainer

                    Image {
                        anchors.centerIn: parent
                        source: "qrc:/PDF_ToolKit/resources/icons/merge.svg"
                        sourceSize.width: Theme.iconSizeXLarge
                        sourceSize.height: Theme.iconSizeXLarge
                        opacity: 0.5
                    }
                }

                Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("No files added")
                    font.pixelSize: Theme.fontSizeTitle
                    font.weight: Font.Medium
                    color: Theme.surfaceForeground
                }

                Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("Add PDF files to combine them into one")
                    font.pixelSize: Theme.fontSizeBody
                    color: Theme.surfaceForegroundVariant
                }

                Button {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 180
                    Layout.preferredHeight: Theme.buttonHeight
                    text: qsTr("Add PDF")
                    icon.source: "qrc:/PDF_ToolKit/resources/icons/folder.svg"
                    Material.background: Theme.primary
                    Material.foreground: Theme.primaryForeground
                    font.weight: Font.Medium
                    onClicked: fileDialog.open()
                }
            }

            // File list
            ListView {
                id: filesList
                anchors.fill: parent
                anchors.margins: Theme.spacingMedium
                visible: filesModel.count > 0
                model: filesModel
                spacing: Theme.spacingSmall
                clip: true

                add: Transition {
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.animationNormal }
                        NumberAnimation { property: "scale"; from: 0.8; to: 1; duration: Theme.animationNormal; easing.type: Easing.OutBack }
                    }
                }

                remove: Transition {
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.animationFast }
                        NumberAnimation { property: "scale"; from: 1; to: 0.8; duration: Theme.animationFast }
                    }
                }

                displaced: Transition {
                    NumberAnimation { properties: "y"; duration: Theme.animationNormal; easing.type: Easing.OutCubic }
                }

                delegate: Rectangle {
                    id: fileItem
                    width: ListView.view.width
                    height: 72
                    radius: Theme.radiusMedium
                    color: Theme.cardSurface
                    border.width: 1
                    border.color: Theme.outlineVariant

                    property bool isHovered: false

                    Behavior on color {
                        ColorAnimation { duration: Theme.animationFast }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.spacingMedium
                        anchors.rightMargin: Theme.spacingSmall
                        spacing: Theme.spacingMedium

                        Rectangle {
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            radius: 16
                            color: Theme.primaryContainer

                            Label {
                                anchors.centerIn: parent
                                text: (index + 1).toString()
                                font.pixelSize: Theme.fontSizeBody
                                font.weight: Font.DemiBold
                                color: Theme.primaryForegroundContainer
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 44
                            Layout.preferredHeight: 44
                            radius: Theme.radiusSmall
                            color: Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.1)

                            Image {
                                anchors.centerIn: parent
                                source: "qrc:/PDF_ToolKit/resources/icons/pdf.svg"
                                sourceSize.width: Theme.iconSizeMedium
                                sourceSize.height: Theme.iconSizeMedium
                            }
                        }

                        Label {
                            Layout.fillWidth: true
                            text: model.name
                            font.pixelSize: Theme.fontSizeBody
                            font.weight: Font.Medium
                            color: Theme.surfaceForeground
                            elide: Text.ElideMiddle
                        }

                        ToolButton {
                            icon.source: "qrc:/PDF_ToolKit/resources/icons/delete.svg"
                            icon.width: Theme.iconSizeSmall
                            icon.height: Theme.iconSizeSmall
                            onClicked: filesModel.remove(index)

                            background: Rectangle {
                                radius: Theme.radiusSmall
                                color: parent.hovered ? Theme.errorContainer : "transparent"
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton

                        onEntered: {
                            fileItem.isHovered = true
                            fileItem.color = Theme.cardSurfaceHover
                        }

                        onExited: {
                            fileItem.isHovered = false
                            fileItem.color = Theme.cardSurface
                        }
                    }
                }
            }
        }

        // Bottom action bar
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: filesModel.count > 0 ? 140 : 80
            color: Theme.surfaceContainer

            Behavior on Layout.preferredHeight {
                NumberAnimation { duration: Theme.animationNormal; easing.type: Easing.OutCubic }
            }

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
                    visible: filesModel.count > 0
                    spacing: Theme.spacingSmall

                    Rectangle {
                        Layout.preferredWidth: 8
                        Layout.preferredHeight: 8
                        radius: 4
                        color: filesModel.count >= 2 ? Theme.success : Theme.warning
                    }

                    Label {
                        Layout.fillWidth: true
                        text: filesModel.count >= 2 
                            ? qsTr("Ready to merge %1 files").arg(filesModel.count)
                            : qsTr("Add at least 2 files to merge")
                        font.pixelSize: Theme.fontSizeCaption
                        color: Theme.surfaceForegroundVariant
                    }

                    Label {
                        text: qsTr("Max 3 files")
                        font.pixelSize: Theme.fontSizeTiny
                        color: Theme.surfaceForegroundVariant
                        opacity: 0.7
                    }
                }

                Button {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Theme.buttonHeightSmall
                    visible: filesModel.count > 0 && filesModel.count < 3
                    text: qsTr("Add Another PDF")
                    icon.source: "qrc:/PDF_ToolKit/resources/icons/folder.svg"
                    flat: true
                    onClicked: fileDialog.open()
                }

                Button {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Theme.buttonHeight
                    text: qsTr("Merge PDFs")
                    icon.source: "qrc:/PDF_ToolKit/resources/icons/merge.svg"
                    Material.background: Theme.primary
                    Material.foreground: Theme.primaryForeground
                    font.weight: Font.DemiBold
                    enabled: filesModel.count >= 2 && !pdfEngine.isProcessing
                    opacity: enabled ? 1 : 0.5
                    onClicked: {
                        var files = []
                        for (var i = 0; i < filesModel.count; i++) {
                            files.push(filesModel.get(i).url.toString())
                        }
                        pdfEngine.mergePDFs(files, FileUtils.getTempPath() + "/preview_merged.pdf")
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
            if (success) {
                var outputPath = FileUtils.getTempPath() + "/preview_merged.pdf"
                console.log("MergeScreen: Merge completed for preview. Output path:", outputPath)
                
                filesModel.clear()
                root.merged(outputPath)
            } else {
                root.showToast(message, "error")
            }
        }
    }
}
