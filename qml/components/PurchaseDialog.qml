import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import PDF_ToolKit 1.0

Dialog {
    id: purchaseDialog
    modal: true
    anchors.centerIn: parent
    width: parent.width - Theme.spacingXLarge * 2
    padding: 0

    property bool isIndian: AIManager.isIndianLocale()
    property string price: isIndian ? "₹99" : "$2.99"
    property string originalPrice: isIndian ? "₹299" : "$7.99"

    background: Rectangle {
        radius: Theme.radiusLarge
        color: Theme.surface

        // Shadow
        Rectangle {
            anchors.fill: parent
            anchors.margins: -1
            z: -1
            radius: parent.radius + 2
            color: "transparent"

            Rectangle {
                anchors.fill: parent
                anchors.topMargin: 8
                radius: parent.radius
                color: Theme.shadowMedium
            }
        }
    }

    contentItem: ColumnLayout {
        spacing: Theme.spacingMedium

        // Header with close button
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 48

            ToolButton {
                anchors.right: parent.right
                anchors.top: parent.top
                icon.source: "qrc:/PDF_ToolKit/resources/icons/delete.svg"
                icon.width: Theme.iconSizeSmall
                icon.height: Theme.iconSizeSmall
                onClicked: purchaseDialog.close()
            }
        }

        // Content
        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Theme.spacingLarge
            Layout.rightMargin: Theme.spacingLarge
            Layout.bottomMargin: Theme.spacingLarge
            spacing: Theme.spacingMedium

            // Early bird badge
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: earlyBirdLabel.width + Theme.spacingLarge
                Layout.preferredHeight: 32
                radius: Theme.radiusFull
                color: Theme.warning

                Label {
                    id: earlyBirdLabel
                    anchors.centerIn: parent
                    text: qsTr("Early Bird - Limited Time!")
                    font.pixelSize: Theme.fontSizeCaption
                    font.weight: Font.Bold
                    color: Theme.warningForeground
                }
            }

            // AI Icon
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 80
                Layout.preferredHeight: 80
                radius: 40
                color: Qt.rgba(Theme.secondary.r, Theme.secondary.g, Theme.secondary.b, 0.1)

                Image {
                    anchors.centerIn: parent
                    source: "qrc:/PDF_ToolKit/resources/icons/ai_brain.svg"
                    sourceSize.width: Theme.iconSizeXLarge
                    sourceSize.height: Theme.iconSizeXLarge
                }
            }

            // Title
            Label {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Unlock AI Assistant")
                font.pixelSize: Theme.fontSizeHeadline
                font.weight: Font.Bold
                color: Theme.surfaceForeground
            }

            // Benefits list
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingSmall

                BenefitRow { text: qsTr("Unlimited PDF summaries") }
                BenefitRow { text: qsTr("Ask unlimited questions") }
                BenefitRow { text: qsTr("Lifetime access - pay once, use forever") }
                BenefitRow {
                    text: qsTr("100% Private - PDFs never leave your device")
                    isPrivacy: true
                }
            }

            Item { Layout.preferredHeight: Theme.spacingSmall }

            // Price display with strikethrough
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Theme.spacingSmall

                Label {
                    text: originalPrice
                    font.pixelSize: Theme.fontSizeTitle
                    font.strikeout: true
                    color: Theme.surfaceVariantForeground
                }

                Label {
                    text: price
                    font.pixelSize: Theme.fontSizeDisplay
                    font.weight: Font.Bold
                    color: Theme.primary
                }

                Rectangle {
                    width: lifetimeLabel.width + Theme.spacingSmall
                    height: 24
                    radius: Theme.radiusFull
                    color: Qt.rgba(Theme.success.r, Theme.success.g, Theme.success.b, 0.1)

                    Label {
                        id: lifetimeLabel
                        anchors.centerIn: parent
                        text: qsTr("lifetime")
                        font.pixelSize: Theme.fontSizeTiny
                        font.weight: Font.DemiBold
                        color: Theme.success
                    }
                }
            }

            Item { Layout.preferredHeight: Theme.spacingSmall }

            // Purchase button
            Button {
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.buttonHeight
                text: qsTr("Unlock Now")
                Material.background: Theme.primary
                Material.foreground: Theme.primaryForeground
                font.pixelSize: Theme.fontSizeSubtitle
                font.weight: Font.Bold

                onClicked: {
                    // For now, just set purchased (replace with actual IAP)
                    AIManager.setPurchased(true)
                    purchaseDialog.close()
                }
            }

            // Maybe later link
            Label {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Maybe later")
                font.pixelSize: Theme.fontSizeCaption
                color: Theme.surfaceVariantForeground

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: purchaseDialog.close()
                }
            }
        }
    }

    // Benefit row component
    component BenefitRow: RowLayout {
        property string text
        property bool isPrivacy: false

        Layout.fillWidth: true
        spacing: Theme.spacingSmall

        Label {
            text: isPrivacy ? "🔒" : "✓"
            font.pixelSize: Theme.fontSizeBody
            color: isPrivacy ? Theme.success : Theme.primary
        }

        Label {
            Layout.fillWidth: true
            text: parent.text
            font.pixelSize: Theme.fontSizeBody
            color: Theme.surfaceForeground
            wrapMode: Text.WordWrap
        }
    }
}
