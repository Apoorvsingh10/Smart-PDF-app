import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import PDF_ToolKit 1.0

Page {
    id: root

    signal navigateToPaywall()

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
            anchors.leftMargin: Theme.spacingMedium
            anchors.rightMargin: Theme.spacingMedium

            Rectangle {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                radius: Theme.radiusSmall
                color: Qt.rgba(Theme.secondary.r, Theme.secondary.g, Theme.secondary.b, 0.15)

                Image {
                    anchors.centerIn: parent
                    source: "qrc:/PDF_ToolKit/resources/icons/settings.svg"
                    sourceSize.width: 20
                    sourceSize.height: 20
                }
            }

            Label {
                text: qsTr("Settings")
                font.pixelSize: Theme.fontSizeTitle
                font.weight: Font.DemiBold
                color: Theme.surfaceForeground
                Layout.fillWidth: true
            }
        }
    }

    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: parent.width
            spacing: Theme.spacingSmall

            // AI Configuration section
            SettingsSection {
                title: qsTr("AI Configuration")
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.margins: Theme.spacingMedium
                Layout.preferredHeight: apiKeyColumn.height + Theme.spacingLarge
                radius: Theme.radiusMedium
                color: Theme.surfaceContainer

                ColumnLayout {
                    id: apiKeyColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Theme.spacingMedium
                    spacing: Theme.spacingSmall

                    Label {
                        text: qsTr("Gemini API Key")
                        font.pixelSize: Theme.fontSizeBody
                        font.weight: Font.Medium
                        color: Theme.surfaceForeground
                    }

                    Label {
                        text: qsTr("Get your key from Google AI Studio")
                        font.pixelSize: Theme.fontSizeCaption
                        color: Theme.surfaceVariantForeground
                    }

                    TextField {
                        id: apiKeyField
                        Layout.fillWidth: true
                        placeholderText: qsTr("Enter your Gemini API key")
                        text: Settings.aiApiKey
                        echoMode: showKeyButton.checked ? TextInput.Normal : TextInput.Password
                        Material.accent: Theme.primary

                        rightPadding: showKeyButton.width + Theme.spacingSmall

                        Button {
                            id: showKeyButton
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.rightMargin: 4
                            width: 40
                            height: 40
                            flat: true
                            checkable: true
                            text: checked ? "Hide" : "Show"
                            font.pixelSize: Theme.fontSizeTiny
                        }
                    }

                    Button {
                        Layout.alignment: Qt.AlignRight
                        text: qsTr("Save API Key")
                        Material.background: Theme.primary
                        Material.foreground: Theme.primaryForeground
                        enabled: apiKeyField.text.length > 0

                        onClicked: {
                            Settings.aiApiKey = apiKeyField.text
                            apiKeySavedToast.show()
                        }
                    }
                }
            }

            // About section
            SettingsSection {
                title: qsTr("About")
            }

            SettingsItem {
                Layout.fillWidth: true
                title: qsTr("Version")
                subtitle: qsTr("1.0.0")
                iconSource: "qrc:/PDF_ToolKit/resources/icons/settings.svg"
                accentColor: Theme.tertiary
            }

            SettingsItem {
                Layout.fillWidth: true
                title: qsTr("Smart PDF")
                subtitle: qsTr("Built with Qt 6")
                iconSource: "qrc:/PDF_ToolKit/resources/icons/pdf.svg"
                accentColor: Theme.primary
            }

            // Subscription section
            SettingsSection {
                title: qsTr("Subscription")
            }

            // Plan info
            SettingsItem {
                Layout.fillWidth: true
                title: qsTr("Current Plan")
                subtitle: {
                    if (SubscriptionManager.plan === "lifetime") return qsTr("Lifetime Member")
                    if (SubscriptionManager.plan === "quarterly") return qsTr("Quarterly Plan")
                    if (SubscriptionManager.plan === "monthly") return qsTr("Monthly Plan")
                    return qsTr("Free Trial")
                }
                iconSource: "qrc:/PDF_ToolKit/resources/icons/ai.svg"
                accentColor: SubscriptionManager.isPremium ? Theme.success : Theme.secondary

                trailing: [
                    Rectangle {
                        width: planLabel.width + Theme.spacingSmall
                        height: 24
                        radius: Theme.radiusFull
                        color: SubscriptionManager.isPremium
                               ? Qt.rgba(Theme.success.r, Theme.success.g, Theme.success.b, 0.1)
                               : Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.1)

                        Label {
                            id: planLabel
                            anchors.centerIn: parent
                            text: SubscriptionManager.isPremium ? qsTr("PRO") : qsTr("FREE")
                            font.pixelSize: Theme.fontSizeTiny
                            font.weight: Font.DemiBold
                            color: SubscriptionManager.isPremium ? Theme.success : Theme.primary
                        }
                    }
                ]
            }

            // AI Usage info
            SettingsItem {
                Layout.fillWidth: true
                title: qsTr("AI Requests")
                subtitle: {
                    var used = SubscriptionManager.aiRequestsUsed
                    var limit = SubscriptionManager.aiRequestsLimit
                    var remaining = limit - used
                    if (SubscriptionManager.isPremium) {
                        return qsTr("%1 of %2 used this month").arg(used).arg(limit)
                    }
                    return qsTr("%1 of %2 remaining").arg(remaining).arg(limit)
                }
                iconSource: "qrc:/PDF_ToolKit/resources/icons/tools.svg"
                accentColor: Theme.tertiary

                trailing: [
                    Rectangle {
                        width: usageLabel.width + Theme.spacingSmall
                        height: 24
                        radius: Theme.radiusFull
                        color: Qt.rgba(Theme.tertiary.r, Theme.tertiary.g, Theme.tertiary.b, 0.1)

                        Label {
                            id: usageLabel
                            anchors.centerIn: parent
                            text: (SubscriptionManager.aiRequestsLimit - SubscriptionManager.aiRequestsUsed) + qsTr(" left")
                            font.pixelSize: Theme.fontSizeTiny
                            font.weight: Font.DemiBold
                            color: Theme.tertiary
                        }
                    }
                ]
            }

            // Expiry info (for non-lifetime plans)
            SettingsItem {
                Layout.fillWidth: true
                visible: SubscriptionManager.isPremium && SubscriptionManager.plan !== "lifetime"
                title: qsTr("Expires")
                subtitle: SubscriptionManager.expiresAt || qsTr("--")
                iconSource: "qrc:/PDF_ToolKit/resources/icons/settings.svg"
                accentColor: Theme.warning
            }

            // Reset date (for premium users)
            SettingsItem {
                Layout.fillWidth: true
                visible: SubscriptionManager.isPremium && SubscriptionManager.resetDate.length > 0
                title: qsTr("Requests Reset")
                subtitle: SubscriptionManager.resetDate
                iconSource: "qrc:/PDF_ToolKit/resources/icons/settings.svg"
                accentColor: Theme.primary
            }

            // Upgrade button (for free users)
            Rectangle {
                Layout.fillWidth: true
                Layout.margins: Theme.spacingMedium
                Layout.preferredHeight: upgradeButton.height + Theme.spacingMedium
                visible: !SubscriptionManager.isPremium
                radius: Theme.radiusMedium
                color: Theme.primaryContainer

                Button {
                    id: upgradeButton
                    anchors.centerIn: parent
                    width: parent.width - Theme.spacingLarge
                    height: Theme.buttonHeight
                    text: qsTr("Upgrade to PRO")
                    Material.background: Theme.primary
                    Material.foreground: Theme.primaryForeground
                    font.weight: Font.DemiBold

                    onClicked: root.navigateToPaywall()
                }
            }

            // Lifetime badge (for lifetime users)
            Rectangle {
                Layout.fillWidth: true
                Layout.margins: Theme.spacingMedium
                Layout.preferredHeight: 56
                visible: SubscriptionManager.plan === "lifetime"
                radius: Theme.radiusMedium
                color: Qt.rgba(Theme.success.r, Theme.success.g, Theme.success.b, 0.1)

                RowLayout {
                    anchors.centerIn: parent
                    spacing: Theme.spacingSmall

                    Label {
                        text: "✓"
                        font.pixelSize: Theme.fontSizeTitle
                        color: Theme.success
                    }

                    Label {
                        text: qsTr("Lifetime Member")
                        font.pixelSize: Theme.fontSizeSubtitle
                        font.weight: Font.DemiBold
                        color: Theme.success
                    }
                }
            }

            // Footer
            Item { Layout.preferredHeight: Theme.spacingXLarge }

            // Credits card
            Rectangle {
                Layout.fillWidth: true
                Layout.margins: Theme.spacingMedium
                Layout.preferredHeight: creditsContent.height + Theme.spacingLarge
                radius: Theme.radiusMedium
                color: Theme.primaryContainer

                ColumnLayout {
                    id: creditsContent
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Theme.spacingMedium
                    spacing: Theme.spacingSmall

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 56
                        Layout.preferredHeight: 56
                        radius: 28
                        color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.2)

                        Image {
                            anchors.centerIn: parent
                            source: "qrc:/PDF_ToolKit/resources/icons/pdf.svg"
                            sourceSize.width: Theme.iconSizeLarge
                            sourceSize.height: Theme.iconSizeLarge
                        }
                    }

                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("Thank you for using Smart PDF!")
                        font.pixelSize: Theme.fontSizeSubtitle
                        font.weight: Font.DemiBold
                        color: Theme.primaryContainerForeground
                    }

                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("Your all-in-one PDF solution")
                        font.pixelSize: Theme.fontSizeCaption
                        color: Theme.primaryContainerForeground
                        opacity: 0.8
                    }
                }
            }

            Item { Layout.preferredHeight: Theme.spacingXLarge }
        }
    }

    // Settings Section Header Component
    component SettingsSection: Item {
        property string title

        Layout.fillWidth: true
        Layout.preferredHeight: 40
        Layout.leftMargin: Theme.spacingMedium

        Label {
            anchors.verticalCenter: parent.verticalCenter
            text: title
            font.pixelSize: Theme.fontSizeCaption
            font.weight: Font.DemiBold
            color: Theme.primary
            textFormat: Text.PlainText
        }
    }

    // Settings Item Component
    component SettingsItem: Rectangle {
        id: settingsItem
        property string title
        property string subtitle
        property string iconSource
        property color accentColor: Theme.primary
        property alias trailing: trailingContainer.children

        implicitHeight: 72
        color: mouseArea.containsMouse ? Theme.cardSurfaceHover : "transparent"
        radius: Theme.radiusSmall

        Behavior on color {
            ColorAnimation { duration: Theme.animationFast }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Theme.spacingMedium
            anchors.rightMargin: Theme.spacingMedium
            spacing: Theme.spacingMedium

            // Icon badge
            Rectangle {
                Layout.preferredWidth: 44
                Layout.preferredHeight: 44
                radius: Theme.radiusSmall
                color: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.12)

                Image {
                    anchors.centerIn: parent
                    source: iconSource
                    sourceSize.width: Theme.iconSizeMedium
                    sourceSize.height: Theme.iconSizeMedium
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Label {
                    text: title
                    font.pixelSize: Theme.fontSizeBody
                    font.weight: Font.Medium
                    color: Theme.surfaceForeground
                }

                Label {
                    visible: subtitle !== ""
                    text: subtitle
                    font.pixelSize: Theme.fontSizeCaption
                    color: Theme.surfaceVariantForeground
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }

            Item {
                id: trailingContainer
                Layout.preferredWidth: childrenRect.width
                Layout.preferredHeight: childrenRect.height
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
        }
    }

    // Toast for API key saved
    Rectangle {
        id: apiKeySavedToast
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.spacingXLarge
        width: toastLabel.width + Theme.spacingLarge
        height: 44
        radius: Theme.radiusFull
        color: Theme.success
        opacity: 0
        visible: opacity > 0

        function show() {
            opacity = 1
            toastTimer.restart()
        }

        Behavior on opacity {
            NumberAnimation { duration: Theme.animationMedium }
        }

        Timer {
            id: toastTimer
            interval: 2000
            onTriggered: apiKeySavedToast.opacity = 0
        }

        Label {
            id: toastLabel
            anchors.centerIn: parent
            text: qsTr("API Key saved successfully")
            font.pixelSize: Theme.fontSizeBody
            font.weight: Font.Medium
            color: "white"
        }
    }
}
