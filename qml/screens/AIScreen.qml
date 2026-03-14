import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import PDF_ToolKit 1.0

Page {
    id: root

    property url pdfPath
    property string pdfFileName: ""
    property string pdfText: ""
    property bool isResponseMaximized: false

    signal back()
    signal showToast(string message, string type)
    signal navigateToPaywall()

    background: Rectangle {
        color: Theme.background
    }

    // Clear response when leaving the screen
    Component.onDestruction: {
        AIManager.clearResponse()
        AIManager.cancelRequest()
    }

    onVisibleChanged: {
        if (!visible) {
            AIManager.clearResponse()
            AIManager.cancelRequest()
        }
    }

    // Handle AI responses
    Connections {
        target: AIManager
        function onResponseReady(response) {}
        function onErrorOccurred(error) {
            root.showToast(error, "error")
        }
        function onAccessDenied() {
            root.navigateToPaywall()
        }
        function onLimitReached(resetDate) {
            limitDialog.resetDate = resetDate
            limitDialog.open()
        }
    }

    // Custom elegant header
    Rectangle {
        id: headerArea
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 70
        z: 10

        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "#7C3AED" }
            GradientStop { position: 1.0; color: "#A78BFA" }
        }

        // Back button
        ToolButton {
            id: backBtn
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 4
            icon.source: "qrc:/PDF_ToolKit/resources/icons/back.svg"
            icon.width: 24
            icon.height: 24
            icon.color: "#FFFFFF"
            onClicked: root.back()
        }

        // Title with icon
        Row {
            anchors.centerIn: parent
            spacing: 10

            Image {
                source: "qrc:/PDF_ToolKit/resources/icons/ai_brain.svg"
                sourceSize.width: 24
                sourceSize.height: 24
                anchors.verticalCenter: parent.verticalCenter

                // Make icon white
                layer.enabled: true
                layer.effect: ColorOverlay {
                    color: "#FFFFFF"
                }
            }

            Label {
                text: qsTr("AI Assistant")
                font.pixelSize: 20
                font.weight: Font.Bold
                color: "#FFFFFF"
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // Subscription badge
        Rectangle {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: 16
            width: subLabel.width + 20
            height: 30
            radius: 15
            color: SubscriptionManager.isPremium ? "#10B981" : "#FFFFFF"

            Label {
                id: subLabel
                anchors.centerIn: parent
                text: {
                    if (SubscriptionManager.isPremium) return "PRO"
                    var remaining = SubscriptionManager.aiRequestsLimit - SubscriptionManager.aiRequestsUsed
                    return qsTr("%1 left").arg(remaining)
                }
                font.pixelSize: 12
                font.weight: Font.Bold
                color: SubscriptionManager.isPremium ? "#FFFFFF" : "#7C3AED"
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (!SubscriptionManager.isPremium) root.navigateToPaywall()
                }
            }
        }
    }

    ScrollView {
        anchors.top: headerArea.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: parent.width
            spacing: 0

            // Main content area
            ColumnLayout {
                Layout.fillWidth: true
                Layout.margins: 20
                spacing: 20

                // PDF Info Card - Elegant design
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 80
                    radius: 16
                    color: Theme.cardSurface
                    border.width: 1
                    border.color: Theme.outlineVariant

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 16

                        // PDF Icon with gradient background
                        Rectangle {
                            Layout.preferredWidth: 48
                            Layout.preferredHeight: 48
                            radius: 12
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: "#F3E8FF" }
                                GradientStop { position: 1.0; color: "#E9D5FF" }
                            }

                            Image {
                                anchors.centerIn: parent
                                source: "qrc:/PDF_ToolKit/resources/icons/pdf.svg"
                                sourceSize.width: 24
                                sourceSize.height: 24
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Label {
                                text: pdfFileName || qsTr("No PDF selected")
                                font.pixelSize: 15
                                font.weight: Font.DemiBold
                                color: Theme.surfaceForeground
                                elide: Text.ElideMiddle
                                Layout.fillWidth: true
                            }

                            Row {
                                spacing: 8

                                Rectangle {
                                    width: statusText.width + 12
                                    height: 20
                                    radius: 10
                                    color: (pdfText.length > 0 || AIManager.isImageBased)
                                           ? Qt.rgba(16/255, 185/255, 129/255, 0.1)
                                           : Qt.rgba(Theme.surfaceVariantForeground.r, Theme.surfaceVariantForeground.g, Theme.surfaceVariantForeground.b, 0.1)

                                    Label {
                                        id: statusText
                                        anchors.centerIn: parent
                                        text: pdfText.length > 0
                                              ? qsTr("Ready")
                                              : (AIManager.isImageBased ? qsTr("Image PDF") : qsTr("No text"))
                                        font.pixelSize: 11
                                        font.weight: Font.Medium
                                        color: (pdfText.length > 0 || AIManager.isImageBased) ? "#10B981" : Theme.surfaceVariantForeground
                                    }
                                }

                                Label {
                                    visible: pdfText.length > 0
                                    text: qsTr("%1 chars").arg(pdfText.length.toLocaleString())
                                    font.pixelSize: 12
                                    color: Theme.surfaceVariantForeground
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }
                    }
                }

                // Summarize Section - Premium Card Feel
                Rectangle {
                    id: summarizeCard
                    Layout.fillWidth: true
                    Layout.preferredHeight: 120
                    radius: 20
                    color: summarizeArea.containsMouse ? "#F5F3FF" : "#FAFAFA"
                    border.width: 2
                    border.color: summarizeArea.containsMouse ? "#8B5CF6" : "#E5E7EB"

                    property bool isHovered: summarizeArea.containsMouse

                    Behavior on color { ColorAnimation { duration: 200 } }
                    Behavior on border.color { ColorAnimation { duration: 200 } }
                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                    // Subtle gradient overlay on hover
                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        opacity: summarizeCard.isHovered ? 0.5 : 0
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "#F3E8FF" }
                            GradientStop { position: 1.0; color: "#EDE9FE" }
                        }
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 16

                        // Icon container
                        Rectangle {
                            Layout.preferredWidth: 60
                            Layout.preferredHeight: 60
                            radius: 16
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: "#8B5CF6" }
                                GradientStop { position: 1.0; color: "#7C3AED" }
                            }

                            Image {
                                id: summaryIcon
                                anchors.centerIn: parent
                                source: "qrc:/PDF_ToolKit/resources/icons/summary.svg"
                                sourceSize.width: 28
                                sourceSize.height: 28

                                layer.enabled: true
                                layer.effect: ColorOverlay {
                                    color: "#FFFFFF"
                                }

                                SequentialAnimation on scale {
                                    loops: Animation.Infinite
                                    running: summarizeCard.isHovered
                                    NumberAnimation { to: 1.1; duration: 300 }
                                    NumberAnimation { to: 1.0; duration: 300 }
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Label {
                                text: qsTr("Summarize PDF")
                                font.pixelSize: 18
                                font.weight: Font.Bold
                                color: "#1F2937"
                            }

                            Label {
                                text: qsTr("Get a quick AI-powered summary of your document")
                                font.pixelSize: 13
                                color: "#6B7280"
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                        }

                        // Arrow indicator with glow
                        Rectangle {
                            id: summarizeArrow
                            Layout.preferredWidth: 44
                            Layout.preferredHeight: 44
                            radius: 22
                            color: summarizeCard.isHovered ? "#7C3AED" : "#E5E7EB"

                            Behavior on color { ColorAnimation { duration: 200 } }

                            // Glow effect when hovered
                            layer.enabled: summarizeCard.isHovered
                            layer.effect: DropShadow {
                                transparentBorder: true
                                horizontalOffset: 0
                                verticalOffset: 0
                                radius: 16
                                samples: 33
                                color: "#7C3AED"
                                spread: 0.3
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "→"
                                font.pixelSize: 20
                                font.weight: Font.Bold
                                color: summarizeCard.isHovered ? "#FFFFFF" : "#9CA3AF"

                                Behavior on color { ColorAnimation { duration: 200 } }
                            }
                        }
                    }

                    MouseArea {
                        id: summarizeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: (pdfText.length > 0 || AIManager.isImageBased) && !AIManager.isLoading

                        onEntered: summarizeCard.scale = 1.02
                        onExited: summarizeCard.scale = 1.0
                        onPressed: summarizeCard.scale = 0.98
                        onReleased: summarizeCard.scale = summarizeCard.isHovered ? 1.02 : 1.0

                        onClicked: {
                            AIManager.currentPdfText = pdfText
                            AIManager.summarizePdf()
                        }
                    }

                    // Disabled overlay
                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: "#FFFFFF"
                        opacity: (pdfText.length === 0 && !AIManager.isImageBased) ? 0.6 : 0
                        visible: opacity > 0
                    }
                }

                // Ask Question Section - Chat-like input
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: questionInput.height + 32
                    radius: 28
                    color: "#FFFFFF"
                    border.width: questionInput.activeFocus ? 2 : 1
                    border.color: questionInput.activeFocus ? "#7C3AED" : "#E5E7EB"

                    Behavior on border.color { ColorAnimation { duration: 150 } }
                    Behavior on border.width { NumberAnimation { duration: 150 } }

                    // Shadow effect
                    layer.enabled: questionInput.activeFocus
                    layer.effect: DropShadow {
                        transparentBorder: true
                        horizontalOffset: 0
                        verticalOffset: 4
                        radius: 12
                        samples: 25
                        color: Qt.rgba(124/255, 58/255, 237/255, 0.15)
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 20
                        anchors.rightMargin: 8
                        anchors.topMargin: 8
                        anchors.bottomMargin: 8
                        spacing: 12

                        // Chat icon
                        Rectangle {
                            Layout.preferredWidth: 36
                            Layout.preferredHeight: 36
                            radius: 18
                            color: "#F3E8FF"
                            visible: !questionInput.activeFocus && questionInput.text.length === 0

                            Image {
                                anchors.centerIn: parent
                                source: "qrc:/PDF_ToolKit/resources/icons/ai_brain.svg"
                                sourceSize.width: 20
                                sourceSize.height: 20
                            }
                        }

                        TextField {
                            id: questionInput
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            placeholderText: qsTr("Ask anything about this PDF...")
                            placeholderTextColor: "#9CA3AF"
                            font.pixelSize: 15
                            color: "#1F2937"
                            background: Item {}
                            enabled: (pdfText.length > 0 || AIManager.isImageBased) && !AIManager.isLoading

                            onAccepted: {
                                if (text.trim().length > 0) {
                                    AIManager.currentPdfText = pdfText
                                    AIManager.askQuestion(text)
                                }
                            }
                        }

                        // Send button
                        Rectangle {
                            id: sendBtn
                            Layout.preferredWidth: 44
                            Layout.preferredHeight: 44
                            radius: 22
                            color: questionInput.text.trim().length > 0 ? "#7C3AED" : "#E5E7EB"
                            scale: sendArea.pressed ? 0.9 : 1.0

                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on scale { NumberAnimation { duration: 100 } }

                            Image {
                                anchors.centerIn: parent
                                source: "qrc:/PDF_ToolKit/resources/icons/send.svg"
                                sourceSize.width: 20
                                sourceSize.height: 20

                                // Tint to white when active
                                layer.enabled: true
                                layer.effect: ColorOverlay {
                                    color: questionInput.text.trim().length > 0 ? "#FFFFFF" : "#9CA3AF"
                                }
                            }

                            MouseArea {
                                id: sendArea
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                enabled: questionInput.text.trim().length > 0 && !AIManager.isLoading

                                onClicked: {
                                    AIManager.currentPdfText = pdfText
                                    AIManager.askQuestion(questionInput.text)
                                }
                            }
                        }
                    }
                }

                // Quick suggestion chips
                Flow {
                    Layout.fillWidth: true
                    spacing: 8
                    visible: !AIManager.currentResponse && !AIManager.isLoading

                    Repeater {
                        model: [
                            qsTr("Key points?"),
                            qsTr("Main topics?"),
                            qsTr("Conclusions?")
                        ]

                        Rectangle {
                            width: chipText.width + 24
                            height: 32
                            radius: 16
                            color: chipArea.containsMouse ? "#F3E8FF" : "#F9FAFB"
                            border.width: 1
                            border.color: chipArea.containsMouse ? "#8B5CF6" : "#E5E7EB"

                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            Label {
                                id: chipText
                                anchors.centerIn: parent
                                text: modelData
                                font.pixelSize: 13
                                color: chipArea.containsMouse ? "#7C3AED" : "#6B7280"

                                Behavior on color { ColorAnimation { duration: 150 } }
                            }

                            MouseArea {
                                id: chipArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                enabled: (pdfText.length > 0 || AIManager.isImageBased) && !AIManager.isLoading

                                onClicked: {
                                    questionInput.text = modelData
                                    AIManager.currentPdfText = pdfText
                                    AIManager.askQuestion(modelData)
                                }
                            }
                        }
                    }
                }

                // Response Area - Clean and elegant
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 250
                    radius: 20
                    color: "#FFFFFF"
                    border.width: 1
                    border.color: "#E5E7EB"

                    // Header
                    Rectangle {
                        id: responseHeaderBar
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 50
                        color: "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 20
                            anchors.rightMargin: 12

                            // AI icon
                            Rectangle {
                                Layout.preferredWidth: 28
                                Layout.preferredHeight: 28
                                radius: 14
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: "#8B5CF6" }
                                    GradientStop { position: 1.0; color: "#7C3AED" }
                                }

                                Image {
                                    anchors.centerIn: parent
                                    source: "qrc:/PDF_ToolKit/resources/icons/sparkle.svg"
                                    sourceSize.width: 14
                                    sourceSize.height: 14

                                    layer.enabled: true
                                    layer.effect: ColorOverlay {
                                        color: "#FFFFFF"
                                    }
                                }
                            }

                            Label {
                                text: qsTr("AI Response")
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                                color: "#374151"
                                Layout.fillWidth: true
                            }

                            // Action buttons
                            Row {
                                spacing: 4
                                visible: AIManager.currentResponse.length > 0

                                ToolButton {
                                    width: 36
                                    height: 36
                                    icon.source: "qrc:/PDF_ToolKit/resources/icons/copy.svg"
                                    icon.width: 18
                                    icon.height: 18
                                    onClicked: {
                                        responseTextArea.selectAll()
                                        responseTextArea.copy()
                                        responseTextArea.deselect()
                                        root.showToast(qsTr("Copied!"), "success")
                                    }
                                }

                                ToolButton {
                                    width: 36
                                    height: 36
                                    icon.source: "qrc:/PDF_ToolKit/resources/icons/fullscreen.svg"
                                    icon.width: 18
                                    icon.height: 18
                                    onClicked: root.isResponseMaximized = true
                                }
                            }
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: 20
                            anchors.rightMargin: 20
                            height: 1
                            color: "#F3F4F6"
                        }
                    }

                    // Response content
                    ScrollView {
                        id: responseScroll
                        anchors.top: responseHeaderBar.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: 20
                        anchors.topMargin: 12
                        clip: true
                        contentWidth: availableWidth

                        TextArea {
                            id: responseTextArea
                            width: responseScroll.availableWidth
                            text: AIManager.currentResponse || ""
                            font.pixelSize: 15
                            color: "#1F2937"
                            wrapMode: Text.WordWrap
                            textFormat: Text.MarkdownText
                            readOnly: true
                            selectByMouse: true
                            background: Item {}
                            padding: 0
                            visible: AIManager.currentResponse.length > 0
                        }

                        // Empty state
                        Item {
                            width: responseScroll.availableWidth
                            height: responseScroll.height
                            visible: !AIManager.currentResponse && !AIManager.isLoading

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 16

                                Rectangle {
                                    Layout.alignment: Qt.AlignHCenter
                                    width: 64
                                    height: 64
                                    radius: 32
                                    color: "#F3E8FF"

                                    Image {
                                        anchors.centerIn: parent
                                        source: "qrc:/PDF_ToolKit/resources/icons/ai_brain.svg"
                                        sourceSize.width: 32
                                        sourceSize.height: 32
                                    }
                                }

                                Label {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: qsTr("Ready to help!")
                                    font.pixelSize: 16
                                    font.weight: Font.DemiBold
                                    color: "#374151"
                                }

                                Label {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: qsTr("Summarize or ask a question")
                                    font.pixelSize: 14
                                    color: "#9CA3AF"
                                }
                            }
                        }
                    }

                    // Loading state
                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: Qt.rgba(1, 1, 1, 0.95)
                        visible: AIManager.isLoading

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 20

                            // Animated dots loader
                            Row {
                                Layout.alignment: Qt.AlignHCenter
                                spacing: 8

                                Repeater {
                                    model: 3
                                    Rectangle {
                                        width: 12
                                        height: 12
                                        radius: 6
                                        color: "#7C3AED"

                                        SequentialAnimation on opacity {
                                            loops: Animation.Infinite
                                            PauseAnimation { duration: index * 200 }
                                            NumberAnimation { from: 0.3; to: 1; duration: 400 }
                                            NumberAnimation { from: 1; to: 0.3; duration: 400 }
                                        }

                                        SequentialAnimation on scale {
                                            loops: Animation.Infinite
                                            PauseAnimation { duration: index * 200 }
                                            NumberAnimation { from: 0.8; to: 1.2; duration: 400 }
                                            NumberAnimation { from: 1.2; to: 0.8; duration: 400 }
                                        }
                                    }
                                }
                            }

                            Label {
                                Layout.alignment: Qt.AlignHCenter
                                text: AIManager.isImageBased ? qsTr("Analyzing images...") : qsTr("Thinking...")
                                font.pixelSize: 15
                                font.weight: Font.Medium
                                color: "#6B7280"
                            }

                            Button {
                                Layout.alignment: Qt.AlignHCenter
                                text: qsTr("Cancel")
                                flat: true
                                font.pixelSize: 13
                                Material.foreground: "#7C3AED"
                                onClicked: AIManager.cancelRequest()
                            }
                        }
                    }
                }

                // Clear button
                Button {
                    Layout.alignment: Qt.AlignHCenter
                    visible: AIManager.currentResponse.length > 0 && !AIManager.isLoading
                    text: qsTr("Clear")
                    flat: true
                    font.pixelSize: 14
                    Material.foreground: "#7C3AED"
                    onClicked: AIManager.clearResponse()
                }

                Item { Layout.preferredHeight: 20 }
            }
        }
    }

    // Fullscreen Response Overlay
    Rectangle {
        id: fullscreenOverlay
        anchors.fill: parent
        color: "#FFFFFF"
        visible: root.isResponseMaximized
        z: 100

        // Header
        Rectangle {
            id: fsHeader
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 60
            color: "#FFFFFF"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 16

                ToolButton {
                    icon.source: "qrc:/PDF_ToolKit/resources/icons/back.svg"
                    icon.width: 24
                    icon.height: 24
                    onClicked: root.isResponseMaximized = false
                }

                Rectangle {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    radius: 16
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#8B5CF6" }
                        GradientStop { position: 1.0; color: "#7C3AED" }
                    }

                    Image {
                        anchors.centerIn: parent
                        source: "qrc:/PDF_ToolKit/resources/icons/sparkle.svg"
                        sourceSize.width: 16
                        sourceSize.height: 16

                        layer.enabled: true
                        layer.effect: ColorOverlay {
                            color: "#FFFFFF"
                        }
                    }
                }

                Label {
                    text: qsTr("AI Response")
                    font.pixelSize: 18
                    font.weight: Font.Bold
                    color: "#1F2937"
                    Layout.fillWidth: true
                }

                ToolButton {
                    icon.source: "qrc:/PDF_ToolKit/resources/icons/copy.svg"
                    icon.width: 20
                    icon.height: 20
                    onClicked: {
                        fsResponseText.selectAll()
                        fsResponseText.copy()
                        fsResponseText.deselect()
                        root.showToast(qsTr("Copied!"), "success")
                    }
                }

                ToolButton {
                    icon.source: "qrc:/PDF_ToolKit/resources/icons/fullscreen_exit.svg"
                    icon.width: 20
                    icon.height: 20
                    onClicked: root.isResponseMaximized = false
                }
            }

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: "#F3F4F6"
            }
        }

        // PDF info
        Rectangle {
            id: fsPdfInfo
            anchors.top: fsHeader.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 44
            color: "#FAFAFA"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                spacing: 10

                Image {
                    source: "qrc:/PDF_ToolKit/resources/icons/pdf.svg"
                    sourceSize.width: 18
                    sourceSize.height: 18
                }

                Label {
                    text: pdfFileName || qsTr("PDF Document")
                    font.pixelSize: 13
                    color: "#6B7280"
                    elide: Text.ElideMiddle
                    Layout.fillWidth: true
                }
            }

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: "#F3F4F6"
            }
        }

        // Content
        ScrollView {
            id: fsScroll
            anchors.top: fsPdfInfo.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 24
            clip: true
            contentWidth: availableWidth

            TextArea {
                id: fsResponseText
                width: fsScroll.availableWidth
                text: AIManager.currentResponse
                font.pixelSize: 16
                color: "#1F2937"
                wrapMode: Text.WordWrap
                textFormat: Text.MarkdownText
                readOnly: true
                selectByMouse: true
                background: Item {}
                padding: 0
                bottomPadding: 40
            }
        }
    }

    // Limit Dialog
    Dialog {
        id: limitDialog
        property string resetDate: ""

        modal: true
        anchors.centerIn: parent
        width: parent.width - 48
        padding: 28

        background: Rectangle {
            radius: 24
            color: "#FFFFFF"
        }

        contentItem: ColumnLayout {
            spacing: 20

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 72
                height: 72
                radius: 36
                color: "#FEF3C7"

                Text {
                    anchors.centerIn: parent
                    text: "⏰"
                    font.pixelSize: 32
                }
            }

            Label {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Limit Reached")
                font.pixelSize: 20
                font.weight: Font.Bold
                color: "#1F2937"
            }

            Label {
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                text: limitDialog.resetDate
                      ? qsTr("Resets on %1").arg(limitDialog.resetDate)
                      : qsTr("You've used all AI requests")
                font.pixelSize: 14
                color: "#6B7280"
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                radius: 26
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "#7C3AED" }
                    GradientStop { position: 1.0; color: "#8B5CF6" }
                }

                Label {
                    anchors.centerIn: parent
                    text: qsTr("Upgrade to PRO")
                    font.pixelSize: 16
                    font.weight: Font.Bold
                    color: "#FFFFFF"
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        limitDialog.close()
                        root.navigateToPaywall()
                    }
                }
            }

            Button {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Maybe Later")
                flat: true
                font.pixelSize: 14
                Material.foreground: "#6B7280"
                onClicked: limitDialog.close()
            }
        }
    }
}
