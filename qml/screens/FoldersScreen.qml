import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Dialogs
import PDF_ToolKit 1.0

Page {
    id: root
    signal back()
    signal openFile(string filePath)
    signal showToast(string message, string type)

    property string initialFolder: ""
    property string currentFolder: ""
    property var currentFiles: []

    Component.onCompleted: {
        if (initialFolder !== "") {
            currentFolder = initialFolder
            currentFiles = FolderManager.getFilesInFolder(initialFolder)
        }
    }

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
                onClicked: {
                    if (currentFolder !== "") {
                        currentFolder = ""
                    } else {
                        root.back()
                    }
                }
            }

            Label {
                text: currentFolder !== "" ? currentFolder : qsTr("My Folders")
                font.pixelSize: Theme.fontSizeTitle
                font.weight: Font.DemiBold
                color: Theme.surfaceForeground
                Layout.fillWidth: true
            }

            // Add Folder Button (visible only when NOT in a folder)
            ToolButton {
                icon.source: "qrc:/PDF_ToolKit/resources/icons/add.svg"
                icon.width: Theme.iconSizeMedium
                icon.height: Theme.iconSizeMedium
                visible: currentFolder === ""
                onClicked: createFolderDialog.open()
                
                ToolTip.visible: hovered
                ToolTip.text: qsTr("New Folder")
            }

            // Add File Button (visible only when IN a folder)
            ToolButton {
                icon.source: "qrc:/PDF_ToolKit/resources/icons/add.svg"
                icon.width: Theme.iconSizeMedium
                icon.height: Theme.iconSizeMedium
                visible: currentFolder !== ""
                onClicked: addFileDialog.open()
                
                ToolTip.visible: hovered
                ToolTip.text: qsTr("Add Files")
            }
        }
    }

    // Add File Dialog
    FileDialog {
        id: addFileDialog
        title: qsTr("Add PDF Files")
        nameFilters: ["PDF files (*.pdf)"]
        onAccepted: {
             var path = selectedFile.toString()
             // Remove file:// prefix if present
             if (path.startsWith("file:///")) {
                 path = path.slice(8)
             } else if (path.startsWith("file://")) {
                 path = path.slice(7)
             }
             
             if (FolderManager.moveFileToFolder(path, currentFolder)) {
                 // Refresh file list
                 currentFiles = FolderManager.getFilesInFolder(currentFolder)
                 root.showToast(qsTr("File added successfully"), "success")
             } else {
                 root.showToast(qsTr("Failed to add file"), "error")
             }
        }
    }

    // Folder list view
    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        visible: currentFolder === ""

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: Theme.spacingMedium
            model: FolderManager.folders
            spacing: Theme.spacingSmall
            clip: true

            delegate: Rectangle {
                id: folderItem
                width: ListView.view.width
                height: 72
                radius: Theme.radiusMedium
                color: Theme.cardSurface
                border.width: 1
                border.color: Theme.outlineVariant

                property bool isHovered: false
                property int fileCount: FolderManager.getFileCount(modelData)

                Behavior on color {
                    ColorAnimation { duration: Theme.animationFast }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.spacingMedium
                    anchors.rightMargin: Theme.spacingSmall
                    spacing: Theme.spacingMedium

                    Rectangle {
                        Layout.preferredWidth: 48
                        Layout.preferredHeight: 48
                        radius: Theme.radiusSmall
                        color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)

                        Image {
                            anchors.centerIn: parent
                            source: "qrc:/PDF_ToolKit/resources/icons/folder.svg"
                            sourceSize.width: Theme.iconSizeMedium
                            sourceSize.height: Theme.iconSizeMedium
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Label {
                            text: modelData
                            font.pixelSize: Theme.fontSizeBody
                            font.weight: Font.Medium
                            color: Theme.surfaceForeground
                        }

                        Label {
                            text: qsTr("%1 PDF files").arg(folderItem.fileCount)
                            font.pixelSize: Theme.fontSizeCaption
                            color: Theme.surfaceForegroundVariant
                        }
                    }

                    // Arrow indicator
                    Image {
                        source: "qrc:/PDF_ToolKit/resources/icons/back.svg"
                        sourceSize.width: 16
                        sourceSize.height: 16
                        rotation: 180
                        opacity: 0.5
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onEntered: {
                        folderItem.isHovered = true
                        folderItem.color = Theme.cardSurfaceHover
                    }

                    onExited: {
                        folderItem.isHovered = false
                        folderItem.color = Theme.cardSurface
                    }

                    onClicked: {
                        currentFolder = modelData
                        currentFiles = FolderManager.getFilesInFolder(modelData)
                    }

                    onPressAndHold: {
                        if (modelData !== "Documents") {
                            contextMenu.folderName = modelData
                            contextMenu.popup()
                        }
                    }
                }
            }

            // Empty state
            Item {
                anchors.centerIn: parent
                width: parent.width
                height: 200
                visible: parent.count === 0

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: Theme.spacingMedium

                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: "📁"
                        font.pixelSize: Theme.fontSizeDisplay
                    }

                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("No folders yet")
                        font.pixelSize: Theme.fontSizeTitle
                        color: Theme.surfaceForeground
                    }

                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("Create a folder to organize your PDFs")
                        font.pixelSize: Theme.fontSizeBody
                        color: Theme.surfaceForegroundVariant
                    }
                }
            }
        }
    }

    // Files in folder view
    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        visible: currentFolder !== ""

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: Theme.spacingMedium
            model: currentFiles
            spacing: Theme.spacingSmall
            clip: true

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
                        Layout.preferredWidth: 48
                        Layout.preferredHeight: 48
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
                        text: FileUtils.getFileName(modelData)
                        font.pixelSize: Theme.fontSizeBody
                        font.weight: Font.Medium
                        color: Theme.surfaceForeground
                        elide: Text.ElideMiddle
                    }

                    Image {
                        source: "qrc:/PDF_ToolKit/resources/icons/back.svg"
                        sourceSize.width: 16
                        sourceSize.height: 16
                        rotation: 180
                        opacity: 0.5
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onEntered: {
                        fileItem.isHovered = true
                        fileItem.color = Theme.cardSurfaceHover
                    }

                    onExited: {
                        fileItem.isHovered = false
                        fileItem.color = Theme.cardSurface
                    }

                    onClicked: {
                        var fileUrl = modelData.startsWith("/") ? "file://" + modelData : "file:///" + modelData
                        root.openFile(fileUrl)
                    }
                }
            }

            // Empty state for folder
            Item {
                anchors.centerIn: parent
                width: parent.width
                height: 200
                visible: currentFiles.length === 0

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: Theme.spacingMedium

                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: "📄"
                        font.pixelSize: Theme.fontSizeDisplay
                    }

                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("No files in this folder")
                        font.pixelSize: Theme.fontSizeTitle
                        color: Theme.surfaceForeground
                    }

                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("Your processed PDFs will appear here")
                        font.pixelSize: Theme.fontSizeBody
                        color: Theme.surfaceForegroundVariant
                    }
                }
            }
        }
    }

    // Create Folder Dialog
    Dialog {
        id: createFolderDialog
        title: qsTr("Create New Folder")
        anchors.centerIn: parent
        width: Math.min(parent.width - 48, 300)
        modal: true
        standardButtons: Dialog.Ok | Dialog.Cancel

        ColumnLayout {
            anchors.fill: parent
            spacing: Theme.spacingMedium

            TextField {
                id: folderNameField
                Layout.fillWidth: true
                placeholderText: qsTr("Folder name")
                focus: true
            }
        }

        onAccepted: {
            if (folderNameField.text.trim() !== "") {
                if (FolderManager.createFolder(folderNameField.text.trim())) {
                    root.showToast(qsTr("Folder created"), "success")
                } else {
                    root.showToast(qsTr("Could not create folder"), "error")
                }
                folderNameField.text = ""
            }
        }

        onRejected: {
            folderNameField.text = ""
        }
    }

    // Context menu for folder actions
    Menu {
        id: contextMenu
        property string folderName: ""

        MenuItem {
            text: qsTr("Rename")
            onTriggered: {
                renameFolderDialog.folderName = contextMenu.folderName
                renameFolderDialog.open()
            }
        }

        MenuItem {
            text: qsTr("Delete")
            Material.foreground: Theme.error
            onTriggered: {
                deleteFolderDialog.folderName = contextMenu.folderName
                deleteFolderDialog.open()
            }
        }
    }

    // Rename Folder Dialog
    Dialog {
        id: renameFolderDialog
        property string folderName: ""

        title: qsTr("Rename Folder")
        anchors.centerIn: parent
        width: Math.min(parent.width - 48, 300)
        modal: true
        standardButtons: Dialog.Ok | Dialog.Cancel

        ColumnLayout {
            anchors.fill: parent
            spacing: Theme.spacingMedium

            TextField {
                id: newFolderNameField
                Layout.fillWidth: true
                text: renameFolderDialog.folderName
                focus: true
            }
        }

        onAccepted: {
            if (newFolderNameField.text.trim() !== "" && newFolderNameField.text.trim() !== folderName) {
                if (FolderManager.renameFolder(folderName, newFolderNameField.text.trim())) {
                    root.showToast(qsTr("Folder renamed"), "success")
                } else {
                    root.showToast(qsTr("Could not rename folder"), "error")
                }
            }
        }
    }

    // Delete Folder Confirmation Dialog
    Dialog {
        id: deleteFolderDialog
        property string folderName: ""

        title: qsTr("Delete Folder?")
        anchors.centerIn: parent
        width: Math.min(parent.width - 48, 300)
        modal: true
        standardButtons: Dialog.Cancel | Dialog.Ok

        Label {
            text: qsTr("Are you sure you want to delete '%1' and all its contents?").arg(deleteFolderDialog.folderName)
            wrapMode: Text.WordWrap
            width: parent.width
        }

        onAccepted: {
            if (FolderManager.deleteFolder(folderName)) {
                root.showToast(qsTr("Folder deleted"), "success")
            } else {
                root.showToast(qsTr("Could not delete folder"), "error")
            }
        }
    }
}
