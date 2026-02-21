import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import PDF_ToolKit 1.0

Page {
    id: root

    signal openMerge()
    signal openSplit()
    signal openCompress()
    signal openViewer()
    signal openFolders()
    signal openFolder(string folderName)
    signal openFileInViewer(string filePath)

    background: Rectangle {
        color: Theme.background
    }

    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: parent.width
            spacing: 0

            // Hero Header with Gradient
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 160

                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Theme.gradientStart }
                    GradientStop { position: 1.0; color: Theme.gradientEnd }
                }

                // Decorative circles
                Rectangle {
                    x: parent.width - 80
                    y: -40
                    width: 160
                    height: 160
                    radius: 80
                    color: "#FFFFFF"
                    opacity: 0.1
                }

                Rectangle {
                    x: -30
                    y: parent.height - 60
                    width: 100
                    height: 100
                    radius: 50
                    color: "#FFFFFF"
                    opacity: 0.08
                }

                // Profile Avatar (Top Right)
                Rectangle {
                    id: profileButton
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.rightMargin: Theme.spacingMedium
                    anchors.topMargin: Theme.spacingMedium
                    width: 40
                    height: 40
                    radius: 20
                    color: profileMouseArea.containsMouse ? "#FFFFFF40" : "#FFFFFF20"
                    border.width: 2
                    border.color: "#FFFFFF60"

                    Behavior on color {
                        ColorAnimation { duration: Theme.animationFast }
                    }

                    Image {
                        id: profileImage
                        anchors.centerIn: parent
                        width: 32
                        height: 32
                        source: AuthManager.userPhotoUrl ? AuthManager.userPhotoUrl : ""
                        visible: AuthManager.userPhotoUrl !== ""
                        fillMode: Image.PreserveAspectCrop
                        layer.enabled: true
                        layer.effect: Item {
                            Rectangle {
                                anchors.fill: parent
                                radius: 16
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: 16
                            color: "transparent"
                            border.width: 1
                            border.color: "#FFFFFF40"
                        }
                    }

                    // Fallback: Default avatar icon
                    Image {
                        anchors.centerIn: parent
                        width: 24
                        height: 24
                        visible: !profileImage.visible
                        source: "qrc:/PDF_ToolKit/resources/icons/default_user.svg"
                        sourceSize.width: 24
                        sourceSize.height: 24
                    }

                    MouseArea {
                        id: profileMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: profileMenu.open()
                    }
                }

                // Profile Menu
                Menu {
                    id: profileMenu
                    x: parent.width - width - Theme.spacingMedium
                    y: profileButton.y + profileButton.height + Theme.spacingSmall
                    width: 220

                    background: Rectangle {
                        implicitWidth: 220
                        radius: Theme.radiusMedium
                        color: Theme.surface
                        border.width: 1
                        border.color: Theme.outlineVariant

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: -1
                            z: -1
                            radius: parent.radius + 2
                            color: Theme.shadowMedium
                            anchors.topMargin: 4
                        }
                    }

                    Column {
                        width: parent.width
                        padding: Theme.spacingMedium
                        spacing: Theme.spacingSmall

                        // User info header
                        Row {
                            spacing: Theme.spacingSmall

                            Rectangle {
                                width: 44
                                height: 44
                                radius: 22
                                color: Theme.primaryContainer

                                Image {
                                    anchors.centerIn: parent
                                    width: 36
                                    height: 36
                                    source: AuthManager.userPhotoUrl ? AuthManager.userPhotoUrl : ""
                                    visible: AuthManager.userPhotoUrl !== ""
                                    fillMode: Image.PreserveAspectCrop
                                }

                                Image {
                                    anchors.centerIn: parent
                                    width: 28
                                    height: 28
                                    visible: !AuthManager.userPhotoUrl
                                    source: "qrc:/PDF_ToolKit/resources/icons/default_user_dark.svg"
                                    sourceSize.width: 28
                                    sourceSize.height: 28
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2

                                Label {
                                    text: AuthManager.userName || "User"
                                    font.pixelSize: Theme.fontSizeBody
                                    font.weight: Font.DemiBold
                                    color: Theme.surfaceForeground
                                    elide: Text.ElideRight
                                    width: 140
                                }

                                Label {
                                    text: AuthManager.userEmail || "Guest"
                                    font.pixelSize: Theme.fontSizeCaption
                                    color: Theme.surfaceVariantForeground
                                    elide: Text.ElideRight
                                    width: 140
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width - parent.padding * 2
                            height: 1
                            color: Theme.outlineVariant
                            opacity: 0.5
                        }
                    }

                    MenuItem {
                        text: qsTr("Sign Out")
                        icon.source: "qrc:/PDF_ToolKit/resources/icons/logout.svg"
                        icon.color: Theme.error
                        onTriggered: {
                            AuthManager.signOut()
                            profileMenu.close()
                        }
                    }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.spacingLarge
                    anchors.rightMargin: Theme.spacingLarge
                    anchors.topMargin: Theme.spacingXLarge
                    anchors.bottomMargin: Theme.spacingLarge
                    spacing: Theme.spacingSmall

                    Label {
                        text: qsTr("Smart PDF")
                        font.pixelSize: Theme.fontSizeDisplay
                        font.weight: Font.Bold
                        color: "#FFFFFF"
                    }

                    Label {
                        text: qsTr("Merge, split, and compress PDFs with ease")
                        font.pixelSize: Theme.fontSizeBody
                        color: "#FFFFFF"
                        opacity: 0.9
                    }

                    Item { Layout.fillHeight: true }
                }
            }

            // Main content area
            ColumnLayout {
                Layout.fillWidth: true
                Layout.margins: Theme.spacingMedium
                spacing: Theme.spacingLarge

                // Quick Actions Section
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingMedium

                    Label {
                        text: qsTr("Quick Actions")
                        font.pixelSize: Theme.fontSizeTitle
                        font.weight: Font.DemiBold
                        color: Theme.backgroundForeground
                    }

                    // Tool Cards Grid
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        rowSpacing: Theme.spacingMedium
                        columnSpacing: Theme.spacingMedium

                        ToolCard {
                            Layout.fillWidth: true
                            title: qsTr("Merge PDFs")
                            description: qsTr("Combine multiple files")
                            iconSource: "qrc:/PDF_ToolKit/resources/icons/merge.svg"
                            accentColor: Theme.primary
                            onClicked: root.openMerge()
                        }

                        ToolCard {
                            Layout.fillWidth: true
                            title: qsTr("Split PDF")
                            description: qsTr("Extract pages")
                            iconSource: "qrc:/PDF_ToolKit/resources/icons/split.svg"
                            accentColor: Theme.secondary
                            onClicked: root.openSplit()
                        }

                        ToolCard {
                            Layout.fillWidth: true
                            title: qsTr("Compress")
                            description: qsTr("Reduce file size")
                            iconSource: "qrc:/PDF_ToolKit/resources/icons/compress.svg"
                            accentColor: Theme.tertiary
                            onClicked: root.openCompress()
                        }

                        ToolCard {
                            Layout.fillWidth: true
                            title: qsTr("View PDF")
                            description: qsTr("Open and read")
                            iconSource: "qrc:/PDF_ToolKit/resources/icons/viewer.svg"
                            accentColor: Theme.warning
                            onClicked: root.openViewer()
                        }
                    }
                }

                // My Folders Section
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingSmall

                    RowLayout {
                        Layout.fillWidth: true

                        Label {
                            text: qsTr("My Folders")
                            font.pixelSize: Theme.fontSizeTitle
                            font.weight: Font.DemiBold
                            color: Theme.backgroundForeground
                            Layout.fillWidth: true
                        }

                        Button {
                            text: qsTr("View All")
                            flat: true
                            font.pixelSize: Theme.fontSizeCaption
                            Material.foreground: Theme.primary
                            onClicked: root.openFolders()
                        }
                    }

                    // Folders horizontal scroll - show ALL folders
                    ScrollView {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 100
                        ScrollBar.horizontal.policy: ScrollBar.AsNeeded
                        ScrollBar.vertical.policy: ScrollBar.AlwaysOff
                        clip: true

                        RowLayout {
                            spacing: Theme.spacingMedium

                            Repeater {
                                model: FolderManager.folders

                                delegate: FolderCard {
                                    id: folderCardDelegate
                                    folderName: modelData
                                    fileCount: FolderManager.getFileCount(modelData)
                                    accentColor: index === 0 ? Theme.primary : (index % 3 === 1 ? Theme.secondary : Theme.tertiary)
                                    onClicked: root.openFolder(modelData)
                                    
                                    // Drop target for drag and drop
                                    property bool isDropTarget: false
                                    
                                    DropArea {
                                        anchors.fill: parent
                                        keys: ["text/plain"]
                                        
                                        onEntered: (drag) => {
                                            folderCardDelegate.isDropTarget = true
                                            folderCardDelegate.color = Theme.primaryContainer
                                        }
                                        
                                        onExited: {
                                            folderCardDelegate.isDropTarget = false
                                            folderCardDelegate.color = Theme.cardSurface
                                        }
                                        
                                        onDropped: (drop) => {
                                            folderCardDelegate.isDropTarget = false
                                            folderCardDelegate.color = Theme.cardSurface
                                            var filePath = drop.text
                                            if (filePath && FolderManager.moveFileToFolder(filePath, modelData)) {
                                                console.log("Moved file to folder:", modelData)
                                            }
                                        }
                                    }
                                }
                            }

                            // Add folder button
                            Rectangle {
                                Layout.preferredWidth: 100
                                Layout.preferredHeight: 90
                                radius: Theme.radiusMedium
                                color: Theme.surfaceContainer
                                border.width: 2
                                border.color: Theme.outlineVariant

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: Theme.spacingSmall

                                    Label {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: "+"
                                        font.pixelSize: Theme.fontSizeHeadline
                                        color: Theme.surfaceForegroundVariant
                                    }

                                    Label {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: qsTr("New")
                                        font.pixelSize: Theme.fontSizeTiny
                                        color: Theme.surfaceForegroundVariant
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: createFolderDialog.open()
                                }
                            }
                        }
                    }
                }

                // Recent Activity Section
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingSmall

                    RowLayout {
                        Layout.fillWidth: true
                        
                        Label {
                            text: qsTr("Recent Activity")
                            font.pixelSize: Theme.fontSizeTitle
                            font.weight: Font.DemiBold
                            color: Theme.backgroundForeground
                            Layout.fillWidth: true
                        }
                        
                        Button {
                            text: qsTr("Clear")
                            flat: true
                            font.pixelSize: Theme.fontSizeCaption
                            Material.foreground: Theme.surfaceForegroundVariant
                            visible: RecentActivityModel.count > 0
                            onClicked: RecentActivityModel.clearAll()
                        }
                    }

                    // Recent items list
                    Repeater {
                        model: RecentActivityModel

                        delegate: RecentActivityItem {
                            Layout.fillWidth: true
                            fileName: model.fileName
                            action: model.action
                            timestamp: model.timestamp
                            filePath: model.filePath
                            index: index
                            onClicked: {
                                // Open file in viewer
                                var fileUrl = model.filePath.startsWith("/") ? "file://" + model.filePath : "file:///" + model.filePath
                                root.openFileInViewer(fileUrl)
                            }
                        }
                    }

                    // Empty state for recent activity
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 80
                        radius: Theme.radiusMedium
                        color: Theme.surfaceContainer
                        visible: RecentActivityModel.count === 0

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: Theme.spacingMedium

                            Rectangle {
                                Layout.preferredWidth: 44
                                Layout.preferredHeight: 44
                                radius: Theme.radiusSmall
                                color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.1)

                                Image {
                                    anchors.centerIn: parent
                                    source: "qrc:/PDF_ToolKit/resources/icons/pdf.svg"
                                    sourceSize.width: Theme.iconSizeMedium
                                    sourceSize.height: Theme.iconSizeMedium
                                    opacity: 0.7
                                }
                            }

                            ColumnLayout {
                                spacing: 2

                                Label {
                                    text: qsTr("No recent activity")
                                    font.pixelSize: Theme.fontSizeBody
                                    color: Theme.surfaceForeground
                                }

                                Label {
                                    text: qsTr("Your recent PDF operations will appear here")
                                    font.pixelSize: Theme.fontSizeCaption
                                    color: Theme.surfaceForegroundVariant
                                }
                            }
                        }
                    }
                }

                Item { Layout.preferredHeight: Theme.spacingXLarge }
            }
        }
    }

    // Select Folder Dialog for Move operation
    Dialog {
        id: selectFolderDialog
        property string sourceFilePath: ""
        
        title: qsTr("Move to Folder")
        anchors.centerIn: parent
        width: Math.min(parent.width - 48, 300)
        modal: true
        standardButtons: Dialog.Cancel
        
        ColumnLayout {
            anchors.fill: parent
            spacing: Theme.spacingMedium
            
            Label {
                text: qsTr("Select destination folder:")
                font.pixelSize: Theme.fontSizeBody
                color: Theme.surfaceForeground
            }
            
            ListView {
                Layout.fillWidth: true
                Layout.preferredHeight: 200
                clip: true
                model: FolderManager.folders
                delegate: ItemDelegate {
                    width: parent.width
                    text: modelData
                    icon.source: "qrc:/PDF_ToolKit/resources/icons/folder.svg"
                    icon.color: Theme.primary
                    onClicked: {
                        if (FolderManager.moveFileToFolder(selectFolderDialog.sourceFilePath, modelData)) {
                             toast.show(qsTr("File moved to %1").arg(modelData), "success")
                        } else {
                             toast.show(qsTr("Failed to move file"), "error")
                        }
                        selectFolderDialog.close()
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
                FolderManager.createFolder(folderNameField.text.trim())
                folderNameField.text = ""
            }
        }

        onRejected: {
            folderNameField.text = ""
        }
    }

    // Folder Card Component
    component FolderCard: Rectangle {
        id: folderCard
        property string folderName
        property int fileCount: 0
        property color accentColor: Theme.primary
        property bool isHovered: false
        signal clicked()

        Layout.preferredWidth: 120
        Layout.preferredHeight: 90
        radius: Theme.radiusMedium
        color: isHovered ? Theme.cardSurfaceHover : Theme.cardSurface
        border.width: 1
        border.color: isHovered ? accentColor : Theme.outlineVariant

        Behavior on scale {
            NumberAnimation { duration: Theme.animationFast; easing.type: Easing.OutCubic }
        }

        Behavior on color {
            ColorAnimation { duration: Theme.animationFast }
        }

        Behavior on border.color {
            ColorAnimation { duration: Theme.animationFast }
        }

        // Accent bar on hover (like ToolCard)
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 3
            radius: Theme.radiusMedium
            color: accentColor
            opacity: folderCard.isHovered ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: Theme.animationFast }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.spacingSmall
            spacing: Theme.spacingTiny

            Rectangle {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                radius: Theme.radiusSmall
                color: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, folderCard.isHovered ? 0.25 : 0.15)

                Behavior on color {
                    ColorAnimation { duration: Theme.animationFast }
                }

                Image {
                    anchors.centerIn: parent
                    source: "qrc:/PDF_ToolKit/resources/icons/folder.svg"
                    sourceSize.width: Theme.iconSizeSmall
                    sourceSize.height: Theme.iconSizeSmall
                }
            }

            Item { Layout.fillHeight: true }

            Label {
                text: folderName
                font.pixelSize: Theme.fontSizeCaption
                font.weight: Font.Medium
                color: Theme.surfaceForeground
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Label {
                text: qsTr("%1 files").arg(fileCount)
                font.pixelSize: Theme.fontSizeTiny
                color: Theme.surfaceForegroundVariant
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onEntered: {
                folderCard.isHovered = true
                folderCard.scale = 1.03
            }

            onExited: {
                folderCard.isHovered = false
                folderCard.scale = 1.0
            }

            onClicked: folderCard.clicked()
            onPressed: folderCard.scale = 0.95
            onReleased: folderCard.scale = folderCard.isHovered ? 1.03 : 1.0
        }
    }

    // Recent Activity Item Component
    component RecentActivityItem: Rectangle {
        id: activityItem
        property string fileName
        property string action
        property string timestamp
        property string filePath
        property int index: 0 // To know which item to delete
        signal clicked()

        implicitHeight: 64
        radius: Theme.radiusMedium
        color: mouseArea.containsMouse ? Theme.cardSurfaceHover : Theme.cardSurface
        border.width: 1
        border.color: Theme.outlineVariant

        Behavior on color {
            ColorAnimation { duration: Theme.animationFast }
        }
        
        Drag.active: dragHandler.active
        Drag.hotSpot.x: width / 2
        Drag.hotSpot.y: height / 2
        Drag.mimeData: { "text/plain": filePath }
        Drag.dragType: Drag.Automatic

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Theme.spacingMedium
            anchors.rightMargin: Theme.spacingSmall
            spacing: Theme.spacingMedium

            // Action icon
            Rectangle {
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                radius: Theme.radiusSmall
                color: {
                    if (action === "merged") return Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)
                    if (action === "split") return Qt.rgba(Theme.secondary.r, Theme.secondary.g, Theme.secondary.b, 0.15)
                    if (action === "compressed") return Qt.rgba(Theme.tertiary.r, Theme.tertiary.g, Theme.tertiary.b, 0.15)
                    return Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.15)
                }

                Image {
                    anchors.centerIn: parent
                    source: {
                        if (action === "merged") return "qrc:/PDF_ToolKit/resources/icons/merge.svg"
                        if (action === "split") return "qrc:/PDF_ToolKit/resources/icons/split.svg"
                        if (action === "compressed") return "qrc:/PDF_ToolKit/resources/icons/compress.svg"
                        if (action === "saved") return "qrc:/PDF_ToolKit/resources/icons/save.svg"
                        return "qrc:/PDF_ToolKit/resources/icons/viewer.svg"
                    }
                    sourceSize.width: 20
                    sourceSize.height: 20
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Label {
                    text: fileName
                    font.pixelSize: Theme.fontSizeBody
                    font.weight: Font.Medium
                    color: Theme.surfaceForeground
                    elide: Text.ElideMiddle
                    Layout.fillWidth: true
                }

                RowLayout {
                    spacing: Theme.spacingSmall

                    Label {
                        text: {
                            if (action === "merged") return qsTr("Merged")
                            if (action === "split") return qsTr("Split")
                            if (action === "compressed") return qsTr("Compressed")
                            if (action === "saved") return qsTr("Saved")
                            return qsTr("Viewed")
                        }
                        font.pixelSize: Theme.fontSizeCaption
                        color: {
                            if (action === "merged") return Theme.primary
                            if (action === "split") return Theme.secondary
                            if (action === "compressed") return Theme.tertiary
                            if (action === "saved") return Theme.success
                            return Theme.warning
                        }
                    }

                    Label {
                        text: "•"
                        font.pixelSize: Theme.fontSizeCaption
                        color: Theme.surfaceForegroundVariant
                    }

                    Label {
                        text: timestamp
                        font.pixelSize: Theme.fontSizeCaption
                        color: Theme.surfaceForegroundVariant
                    }
                }
            }

            // 3-dots Menu Button
            ToolButton {
                text: "⋮"
                font.pixelSize: 20
                onClicked: itemMenu.open()
                
                Menu {
                    id: itemMenu
                    MenuItem {
                        text: qsTr("Move to Folder")
                        onTriggered: {
                            selectFolderDialog.sourceFilePath = activityItem.filePath
                            selectFolderDialog.open()
                        }
                    }
                    MenuItem {
                        text: qsTr("Share")
                        onTriggered: {
                            ShareUtils.shareFile(activityItem.filePath, "application/pdf")
                        }
                    }
                    MenuItem {
                        text: qsTr("Delete")
                        Material.foreground: Theme.error
                        onTriggered: {
                            // Logic to delete actual file could go here, for now just remove from list
                            // But usually users expect deleting from recent list just removes the entry
                            // If they want to delete the file, that's a dangerous operation to put here without confirmation
                            // Assuming "delete from list":
                             // We need the index. Repeater doesn't pass index automatically to component unless we pass it.
                             // Wait, RecentActivityModel.removeActivity currently takes an index.
                             // I need to ensure I pass 'index' to this component.
                             // For now, I'll assume I can access the index via the delegate context or I passed it.
                             // Actually, in the delegate: index is available.
                             RecentActivityModel.removeActivity(activityItem.index)
                        }
                    }
                }
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            z: -1 // Behind the ToolButton
            onClicked: activityItem.clicked()
        }
        
        DragHandler {
            id: dragHandler
            target: null
        }
    }

    // Enhanced Tool Card Component
    component ToolCard: Rectangle {
        id: card
        property string title
        property string description
        property string iconSource
        property color accentColor: Theme.primary
        signal clicked()

        implicitHeight: 130
        radius: Theme.radiusMedium
        color: Theme.cardSurface
        border.width: 1
        border.color: Theme.outlineVariant

        property bool isHovered: false

        Behavior on color {
            ColorAnimation { duration: Theme.animationFast }
        }

        Behavior on scale {
            NumberAnimation { duration: Theme.animationFast; easing.type: Easing.OutCubic }
        }

        // Subtle shadow
        Rectangle {
            anchors.fill: parent
            anchors.margins: -1
            z: -1
            radius: parent.radius + 1
            color: "transparent"
            
            Rectangle {
                anchors.fill: parent
                anchors.topMargin: 4
                radius: parent.radius
                color: Theme.shadowLight
                z: -1
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.spacingMedium
            spacing: Theme.spacingSmall

            Rectangle {
                Layout.preferredWidth: 44
                Layout.preferredHeight: 44
                radius: Theme.radiusSmall
                color: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.15)

                Image {
                    anchors.centerIn: parent
                    source: iconSource
                    sourceSize.width: Theme.iconSizeMedium
                    sourceSize.height: Theme.iconSizeMedium
                }
            }

            Item { Layout.fillHeight: true }

            Label {
                text: title
                font.pixelSize: Theme.fontSizeSubtitle
                font.weight: Font.DemiBold
                color: Theme.surfaceForeground
            }

            Label {
                text: description
                font.pixelSize: Theme.fontSizeCaption
                color: Theme.surfaceForegroundVariant
            }
        }

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 3
            radius: Theme.radiusMedium
            color: accentColor
            opacity: card.isHovered ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: Theme.animationFast }
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            
            onEntered: {
                card.isHovered = true
                card.color = Theme.cardSurfaceHover
                card.scale = 1.02
            }
            
            onExited: {
                card.isHovered = false
                card.color = Theme.cardSurface
                card.scale = 1.0
            }
            
            onClicked: card.clicked()
            onPressed: card.scale = 0.98
            onReleased: card.scale = card.isHovered ? 1.02 : 1.0
        }
    }
}
