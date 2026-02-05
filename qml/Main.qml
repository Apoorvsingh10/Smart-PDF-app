import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import PDF_ToolKit 1.0

ApplicationWindow {
    id: window
    width: 400
    height: 800
    visible: true
    title: qsTr("PdfPilot")

    Material.theme: Theme.isDark ? Material.Dark : Material.Light
    Material.primary: Theme.primary
    Material.accent: Theme.secondary

    MainViewModel {
        id: mainViewModel
    }



    // Handle Android back button
    Shortcut {
        sequences: ["Escape", "Back"]
        onActivated: handleBackButton()
    }

    function handleBackButton() {
        if (stackView.depth > 1) {
            stackView.pop()
        } else if (mainViewModel.currentTabIndex !== 0) {
            // Go to home tab
            mainViewModel.currentTabIndex = 0
            stackView.replace(homeScreen)
        }
        // If on home and depth is 1, do nothing (don't exit app)
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        StackView {
            id: stackView
            Layout.fillWidth: true
            Layout.fillHeight: true
            initialItem: AuthManager.isAuthenticated ? homeScreen : loginScreen

            Keys.onBackPressed: function(event) {
                handleBackButton()
                event.accepted = true
            }

            pushEnter: Transition {
                ParallelAnimation {
                    PropertyAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.animationNormal; easing.type: Easing.OutCubic }
                    PropertyAnimation { property: "x"; from: 40; to: 0; duration: Theme.animationNormal; easing.type: Easing.OutCubic }
                }
            }
            pushExit: Transition {
                PropertyAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.animationFast }
            }
            popEnter: Transition {
                ParallelAnimation {
                    PropertyAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.animationNormal; easing.type: Easing.OutCubic }
                    PropertyAnimation { property: "x"; from: -40; to: 0; duration: Theme.animationNormal; easing.type: Easing.OutCubic }
                }
            }
            popExit: Transition {
                ParallelAnimation {
                    PropertyAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.animationFast }
                    PropertyAnimation { property: "x"; from: 0; to: 40; duration: Theme.animationNormal; easing.type: Easing.OutCubic }
                }
            }
        }

        // Premium Bottom Navigation
        Rectangle {
            visible: AuthManager.isAuthenticated
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.bottomNavHeight
            color: Theme.surfaceContainer

            // Top border line
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: Theme.outlineVariant
                opacity: 0.5
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.spacingSmall
                anchors.rightMargin: Theme.spacingSmall
                spacing: 0

                NavBarItem {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    iconSource: "qrc:/PDF_ToolKit/resources/icons/home.svg"
                    label: qsTr("Home")
                    isSelected: mainViewModel.currentTabIndex === 0
                    accentColor: Theme.primary
                    onClicked: {
                        mainViewModel.currentTabIndex = 0
                        stackView.replace(homeScreen)
                    }
                }

                NavBarItem {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    iconSource: "qrc:/PDF_ToolKit/resources/icons/viewer.svg"
                    label: qsTr("Viewer")
                    isSelected: mainViewModel.currentTabIndex === 1
                    accentColor: Theme.warning
                    onClicked: {
                        mainViewModel.currentTabIndex = 1
                        stackView.replace(viewerScreen)
                    }
                }

                NavBarItem {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    iconSource: "qrc:/PDF_ToolKit/resources/icons/tools.svg"
                    label: qsTr("Tools")
                    isSelected: mainViewModel.currentTabIndex === 2
                    accentColor: Theme.tertiary
                    onClicked: {
                        mainViewModel.currentTabIndex = 2
                        toolsMenu.open()
                    }
                }

                NavBarItem {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    iconSource: "qrc:/PDF_ToolKit/resources/icons/settings.svg"
                    label: qsTr("Settings")
                    isSelected: mainViewModel.currentTabIndex === 3
                    accentColor: Theme.secondary
                    onClicked: {
                        mainViewModel.currentTabIndex = 3
                        stackView.replace(settingsScreen)
                    }
                }
            }
        }
    }

    // Enhanced Tools Menu
    Menu {
        id: toolsMenu
        x: (parent.width - width) / 2
        y: parent.height - Theme.bottomNavHeight - height - Theme.spacingMedium
        width: 220

        background: Rectangle {
            implicitWidth: 220
            radius: Theme.radiusMedium
            color: Theme.surface
            border.width: 1
            border.color: Theme.outlineVariant

            // Shadow
            Rectangle {
                anchors.fill: parent
                anchors.margins: -1
                z: -1
                radius: parent.radius + 2
                color: Theme.shadowMedium
                anchors.topMargin: 4
            }
        }

        MenuItem {
            text: qsTr("Merge PDFs")
            icon.source: "qrc:/PDF_ToolKit/resources/icons/merge.svg"
            icon.color: Theme.primary
            onTriggered: stackView.push(mergeScreen)
        }
        MenuItem {
            text: qsTr("Split PDF")
            icon.source: "qrc:/PDF_ToolKit/resources/icons/split.svg"
            icon.color: Theme.secondary
            onTriggered: stackView.push(splitScreen)
        }
        MenuItem {
            text: qsTr("Compress PDF")
            icon.source: "qrc:/PDF_ToolKit/resources/icons/compress.svg"
            icon.color: Theme.tertiary
            onTriggered: stackView.push(compressScreen)
        }
    }

    // Screen Components
    Component {
        id: homeScreen
        HomeScreen {
            onOpenMerge: stackView.push(mergeScreen)
            onOpenSplit: stackView.push(splitScreen)
            onOpenCompress: stackView.push(compressScreen)
            onOpenViewer: {
                mainViewModel.currentTabIndex = 1
                stackView.replace(viewerScreen)
            }
            onOpenFolders: {
                stackView.push(foldersScreen)
            }
            onOpenFolder: (folderName) => {
                stackView.push(foldersScreen, { "initialFolder": folderName })
            }
            onOpenFileInViewer: (filePath) => {
                mainViewModel.currentTabIndex = 1
                stackView.push(viewerScreen, { "source": filePath, "showBackButton": true })
            }
        }
    }

    Component {
        id: viewerScreen
        ViewerScreen {
            pdfEngine: mainViewModel.pdfEngine
            onShowToast: (msg, type) => toast.show(msg, type)
            onBack: {
                stackView.pop()
            }
            onSaved: (fileUrl) => {
                console.log("Main: File saved to:", fileUrl)
                stackView.clear()
                mainViewModel.currentTabIndex = 1
                stackView.push(viewerScreen, { "source": fileUrl, "showBackButton": false })
            }
        }
    }

    Component {
        id: mergeScreen
        MergeScreen {
            pdfEngine: mainViewModel.pdfEngine
            onBack: stackView.pop()
            onMerged: (path) => {
                console.log("Main: Received merged path:", path)
                mainViewModel.currentTabIndex = 1
                var fileUrl = path.startsWith("/") ? "file://" + path : "file:///" + path
                console.log("Main: Converting to file URL:", fileUrl)
                stackView.push(viewerScreen, { "source": fileUrl, "showBackButton": true, "isPreview": true })
            }
            onShowToast: (msg, type) => toast.show(msg, type)
        }
    }

    Component {
        id: splitScreen
        SplitScreen {
            pdfEngine: mainViewModel.pdfEngine
            onBack: stackView.pop()
            onSplit: (path) => {
                console.log("Main: Received split path:", path)
                mainViewModel.currentTabIndex = 1
                var fileUrl = path.startsWith("/") ? "file://" + path : "file:///" + path
                console.log("Main: Converting to file URL:", fileUrl)
                stackView.push(viewerScreen, { "source": fileUrl, "showBackButton": true, "isPreview": true })
            }
            onShowToast: (msg, type) => toast.show(msg, type)
        }
    }

    Component {
        id: compressScreen
        CompressScreen {
            pdfEngine: mainViewModel.pdfEngine
            onBack: stackView.pop()
            onCompressed: (path) => {
                console.log("Main: Received compressed path:", path)
                mainViewModel.currentTabIndex = 1
                var fileUrl = path.startsWith("/") ? "file://" + path : "file:///" + path
                console.log("Main: Converting to file URL:", fileUrl)
                stackView.push(viewerScreen, { "source": fileUrl, "showBackButton": true, "isPreview": true })
            }
            onShowToast: (msg, type) => toast.show(msg, type)
        }
    }

    Component {
        id: settingsScreen
        SettingsScreen {}
    }

    Component {
        id: foldersScreen
        FoldersScreen {
            onBack: stackView.pop()
            onOpenFile: (filePath) => {
                mainViewModel.currentTabIndex = 1
                stackView.push(viewerScreen, { "source": filePath, "showBackButton": true })
            }
            onShowToast: (msg, type) => toast.show(msg, type)
        }
    }

    Component {
        id: loginScreen
        LoginScreen {
            onLoginSuccess: {
                stackView.replace(homeScreen)
            }
            onShowToast: (msg, type) => toast.show(msg, type)
        }
    }

    // Enhanced NavBar Item Component
    component NavBarItem: Item {
        id: navItem
        property string iconSource
        property string label
        property bool isSelected: false
        property color accentColor: Theme.primary
        signal clicked()

        ColumnLayout {
            anchors.centerIn: parent
            spacing: Theme.spacingTiny

            // Icon container with pill indicator
            Item {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 64
                Layout.preferredHeight: 32

                // Active pill background
                Rectangle {
                    id: pillBg
                    anchors.centerIn: parent
                    width: navItem.isSelected ? 56 : 0
                    height: 28
                    radius: 14
                    color: Qt.rgba(navItem.accentColor.r, navItem.accentColor.g, navItem.accentColor.b, 0.15)
                    
                    Behavior on width {
                        NumberAnimation { duration: Theme.animationNormal; easing.type: Easing.OutCubic }
                    }
                }

                Image {
                    anchors.centerIn: parent
                    source: iconSource
                    sourceSize.width: Theme.iconSizeMedium
                    sourceSize.height: Theme.iconSizeMedium
                    opacity: navItem.isSelected ? 1 : 0.6

                    Behavior on opacity {
                        NumberAnimation { duration: Theme.animationFast }
                    }
                }
            }

            Label {
                Layout.alignment: Qt.AlignHCenter
                text: label
                font.pixelSize: Theme.fontSizeTiny
                font.weight: navItem.isSelected ? Font.DemiBold : Font.Normal
                color: navItem.isSelected ? navItem.accentColor : Theme.surfaceVariantForeground

                Behavior on color {
                    ColorAnimation { duration: Theme.animationFast }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: parent.clicked()
        }
    }

    ToastNotification {
        id: toast
        z: 100
    }
}
