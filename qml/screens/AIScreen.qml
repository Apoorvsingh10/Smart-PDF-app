import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
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

    // Handle AI responses
    Connections {
        target: AIManager
        function onResponseReady(response) {
            // Response handled via property binding
        }
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
                text: qsTr("AI Assistant")
                font.pixelSize: Theme.fontSizeTitle
                font.weight: Font.DemiBold
                color: Theme.surfaceForeground
                Layout.fillWidth: true
            }

            // Subscription badge
            Rectangle {
                Layout.preferredWidth: subBadgeLabel.width + Theme.spacingMedium
                Layout.preferredHeight: 28
                radius: Theme.radiusFull
                color: SubscriptionManager.isPremium
                       ? Qt.rgba(Theme.success.r, Theme.success.g, Theme.success.b, 0.1)
                       : Theme.primaryContainer

                Label {
                    id: subBadgeLabel
                    anchors.centerIn: parent
                    text: {
                        if (SubscriptionManager.isPremium) {
                            return "PRO"
                        } else {
                            var remaining = SubscriptionManager.aiRequestsLimit - SubscriptionManager.aiRequestsUsed
                            return qsTr("%1/%2 free").arg(remaining).arg(SubscriptionManager.aiRequestsLimit)
                        }
                    }
                    font.pixelSize: Theme.fontSizeTiny
                    font.weight: Font.DemiBold
                    color: SubscriptionManager.isPremium ? Theme.success : Theme.primary
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (!SubscriptionManager.isPremium) {
                            root.navigateToPaywall()
                        }
                    }
                }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingMedium
        spacing: Theme.spacingMedium

        // PDF Info Card
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: pdfInfoContent.height + Theme.spacingMedium * 2
            radius: Theme.radiusMedium
            color: Theme.cardSurface
            border.width: 1
            border.color: Theme.outlineVariant

            ColumnLayout {
                id: pdfInfoContent
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Theme.spacingMedium
                spacing: Theme.spacingSmall

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingMedium

                    Rectangle {
                        Layout.preferredWidth: 52
                        Layout.preferredHeight: 52
                        radius: Theme.radiusSmall
                        color: Qt.rgba(Theme.secondary.r, Theme.secondary.g, Theme.secondary.b, 0.1)

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
                            text: pdfFileName || qsTr("No PDF selected")
                            font.pixelSize: Theme.fontSizeBody
                            font.weight: Font.Medium
                            color: Theme.surfaceForeground
                            elide: Text.ElideMiddle
                            Layout.fillWidth: true
                        }

                        Label {
                            text: pdfText.length > 0
                                  ? qsTr("%1 characters extracted").arg(pdfText.length.toLocaleString())
                                  : (AIManager.isImageBased ? qsTr("Image-based PDF") : qsTr("No text extracted"))
                            font.pixelSize: Theme.fontSizeCaption
                            color: pdfText.length > 0 || AIManager.isImageBased ? Theme.success : Theme.surfaceVariantForeground
                        }
                    }
                }

                // Image-based PDF banner
                Rectangle {
                    visible: AIManager.isImageBased
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    radius: Theme.radiusSmall
                    color: Theme.warningContainer

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: Theme.spacingTiny

                        Label {
                            text: "📷"
                            font.pixelSize: Theme.fontSizeCaption
                        }

                        Label {
                            text: qsTr("Scanned PDF - using vision analysis")
                            font.pixelSize: Theme.fontSizeCaption
                            color: Theme.warning
                        }
                    }
                }
            }
        }

        // Privacy badge
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: privacyLabel.width + Theme.spacingMedium
            Layout.preferredHeight: 24
            radius: Theme.radiusFull
            color: Qt.rgba(Theme.success.r, Theme.success.g, Theme.success.b, 0.1)

            Label {
                id: privacyLabel
                anchors.centerIn: parent
                text: "🔒 " + qsTr("Your PDF stays on device")
                font.pixelSize: Theme.fontSizeTiny
                color: Theme.success
            }
        }

        // Action Buttons
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingSmall

            Button {
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.buttonHeight
                text: qsTr("Summarize PDF")
                icon.source: "qrc:/PDF_ToolKit/resources/icons/ai.svg"
                Material.background: Theme.secondary
                Material.foreground: Theme.secondaryForeground
                font.weight: Font.DemiBold
                enabled: (pdfText.length > 0 || AIManager.isImageBased) && !AIManager.isLoading

                onClicked: {
                    AIManager.currentPdfText = pdfText
                    AIManager.summarizePdf()
                }
            }
        }

        // Question Input
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: questionField.height + Theme.spacingSmall * 2
            radius: Theme.radiusMedium
            color: Theme.cardSurface
            border.width: questionField.activeFocus ? 2 : 1
            border.color: questionField.activeFocus ? Theme.primary : Theme.outlineVariant

            RowLayout {
                anchors.fill: parent
                anchors.margins: Theme.spacingSmall
                spacing: Theme.spacingSmall

                TextField {
                    id: questionField
                    Layout.fillWidth: true
                    placeholderText: qsTr("Ask a question about this PDF...")
                    font.pixelSize: Theme.fontSizeBody
                    background: Item {}
                    enabled: (pdfText.length > 0 || AIManager.isImageBased) && !AIManager.isLoading

                    onAccepted: {
                        if (text.trim().length > 0) {
                            AIManager.currentPdfText = pdfText
                            AIManager.askQuestion(text)
                        }
                    }
                }

                Button {
                    Layout.preferredWidth: 80
                    Layout.preferredHeight: Theme.buttonHeightSmall
                    text: qsTr("Ask")
                    Material.background: Theme.primary
                    Material.foreground: Theme.primaryForeground
                    font.weight: Font.DemiBold
                    enabled: questionField.text.trim().length > 0 && !AIManager.isLoading

                    onClicked: {
                        AIManager.currentPdfText = pdfText
                        AIManager.askQuestion(questionField.text)
                    }
                }
            }
        }

        // Response Area
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Theme.radiusMedium
            color: Theme.surfaceContainer
            border.width: 1
            border.color: Theme.outlineVariant

            // Response Header with Maximize button
            Rectangle {
                id: responseHeader
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 40
                color: "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.spacingMedium
                    anchors.rightMargin: Theme.spacingSmall

                    Label {
                        text: qsTr("Response")
                        font.pixelSize: Theme.fontSizeCaption
                        font.weight: Font.DemiBold
                        color: Theme.surfaceVariantForeground
                        Layout.fillWidth: true
                    }

                    // Maximize button
                    ToolButton {
                        visible: AIManager.currentResponse.length > 0
                        icon.source: "qrc:/PDF_ToolKit/resources/icons/fullscreen.svg"
                        icon.width: 20
                        icon.height: 20
                        onClicked: root.isResponseMaximized = true

                        ToolTip.visible: hovered
                        ToolTip.text: qsTr("Expand")
                    }
                }

                // Separator line
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: Theme.spacingMedium
                    anchors.rightMargin: Theme.spacingMedium
                    height: 1
                    color: Theme.outlineVariant
                    opacity: 0.5
                    visible: AIManager.currentResponse.length > 0
                }
            }

            ScrollView {
                id: responseScrollView
                anchors.fill: parent
                anchors.topMargin: responseHeader.height
                anchors.margins: Theme.spacingMedium
                clip: true
                contentWidth: availableWidth

                TextArea {
                    id: responseText
                    width: responseScrollView.availableWidth
                    text: AIManager.currentResponse || qsTr("AI responses will appear here.\n\nTap 'Summarize PDF' for a quick overview, or ask a specific question about the document.")
                    font.pixelSize: Theme.fontSizeBody
                    color: AIManager.currentResponse ? Theme.surfaceForeground : Theme.surfaceVariantForeground
                    wrapMode: Text.WordWrap
                    textFormat: Text.MarkdownText
                    readOnly: true
                    selectByMouse: true
                    background: Item {}
                    padding: 0
                    leftPadding: 0
                    rightPadding: 0
                    topPadding: 0
                    bottomPadding: 0
                }
            }

            // Loading overlay
            Rectangle {
                anchors.fill: parent
                radius: Theme.radiusMedium
                color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, 0.9)
                visible: AIManager.isLoading

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: Theme.spacingMedium

                    BusyIndicator {
                        Layout.alignment: Qt.AlignHCenter
                        running: AIManager.isLoading
                        Material.accent: Theme.primary
                    }

                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: AIManager.isImageBased ? qsTr("Analyzing images...") : qsTr("Analyzing PDF...")
                        font.pixelSize: Theme.fontSizeBody
                        color: Theme.surfaceForeground
                    }

                    Button {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("Cancel")
                        flat: true
                        onClicked: AIManager.cancelRequest()
                    }
                }
            }
        }

        // Clear response button
        Button {
            Layout.alignment: Qt.AlignHCenter
            visible: AIManager.currentResponse.length > 0 && !AIManager.isLoading
            text: qsTr("Clear Response")
            flat: true
            onClicked: AIManager.clearResponse()
        }
    }

    // Fullscreen Response Overlay
    Rectangle {
        id: fullscreenOverlay
        anchors.fill: parent
        color: Theme.background
        visible: root.isResponseMaximized
        z: 100

        // Header
        Rectangle {
            id: fullscreenHeader
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: Theme.appBarHeight
            color: Theme.surfaceContainer

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
                    onClicked: root.isResponseMaximized = false
                }

                Label {
                    text: qsTr("AI Response")
                    font.pixelSize: Theme.fontSizeTitle
                    font.weight: Font.DemiBold
                    color: Theme.surfaceForeground
                    Layout.fillWidth: true
                }

                // Copy button
                ToolButton {
                    icon.source: "qrc:/PDF_ToolKit/resources/icons/copy.svg"
                    icon.width: 20
                    icon.height: 20
                    onClicked: {
                        fullscreenResponseText.selectAll()
                        fullscreenResponseText.copy()
                        fullscreenResponseText.deselect()
                        root.showToast(qsTr("Copied to clipboard"), "success")
                    }

                    ToolTip.visible: hovered
                    ToolTip.text: qsTr("Copy")
                }

                // Minimize button
                ToolButton {
                    icon.source: "qrc:/PDF_ToolKit/resources/icons/fullscreen_exit.svg"
                    icon.width: 20
                    icon.height: 20
                    onClicked: root.isResponseMaximized = false

                    ToolTip.visible: hovered
                    ToolTip.text: qsTr("Minimize")
                }
            }
        }

        // PDF info bar
        Rectangle {
            id: pdfInfoBar
            anchors.top: fullscreenHeader.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 44
            color: Theme.surfaceContainer

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.spacingMedium
                anchors.rightMargin: Theme.spacingMedium
                spacing: Theme.spacingSmall

                Image {
                    source: "qrc:/PDF_ToolKit/resources/icons/pdf.svg"
                    sourceSize.width: 20
                    sourceSize.height: 20
                }

                Label {
                    text: pdfFileName || qsTr("PDF Document")
                    font.pixelSize: Theme.fontSizeCaption
                    color: Theme.surfaceVariantForeground
                    elide: Text.ElideMiddle
                    Layout.fillWidth: true
                }
            }

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: Theme.outlineVariant
                opacity: 0.3
            }
        }

        // Fullscreen content
        ScrollView {
            id: fullscreenScrollView
            anchors.top: pdfInfoBar.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: Theme.spacingMedium
            clip: true
            contentWidth: availableWidth

            TextArea {
                id: fullscreenResponseText
                width: fullscreenScrollView.availableWidth
                text: AIManager.currentResponse
                font.pixelSize: Theme.fontSizeBody + 2
                color: Theme.surfaceForeground
                wrapMode: Text.WordWrap
                textFormat: Text.MarkdownText
                readOnly: true
                selectByMouse: true
                background: Item {}
                padding: 0
                leftPadding: 0
                rightPadding: 0
                topPadding: 0
                bottomPadding: Theme.spacingXLarge
            }
        }
    }

    // Limit reached dialog
    Dialog {
        id: limitDialog
        property string resetDate: ""

        modal: true
        anchors.centerIn: parent
        width: parent.width - Theme.spacingXLarge * 2
        padding: Theme.spacingLarge

        background: Rectangle {
            radius: Theme.radiusLarge
            color: Theme.surface
        }

        contentItem: ColumnLayout {
            spacing: Theme.spacingMedium

            Label {
                Layout.alignment: Qt.AlignHCenter
                text: "⏰"
                font.pixelSize: 48
            }

            Label {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Monthly Limit Reached")
                font.pixelSize: Theme.fontSizeTitle
                font.weight: Font.Bold
                color: Theme.surfaceForeground
            }

            Label {
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                text: limitDialog.resetDate
                      ? qsTr("Your AI requests will reset on %1").arg(limitDialog.resetDate)
                      : qsTr("You've used all your AI requests this month")
                font.pixelSize: Theme.fontSizeBody
                color: Theme.surfaceVariantForeground
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }

            Button {
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.buttonHeight
                text: qsTr("Upgrade for More")
                Material.background: Theme.primary
                Material.foreground: Theme.primaryForeground
                font.weight: Font.DemiBold

                onClicked: {
                    limitDialog.close()
                    root.navigateToPaywall()
                }
            }

            Button {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Maybe Later")
                flat: true
                onClicked: limitDialog.close()
            }
        }
    }
}
