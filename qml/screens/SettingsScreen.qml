import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import PDF_ToolKit 1.0

Page {
    id: root

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

            // About section
            SettingsSection {
                title: qsTr("About")
            }

            SettingsItem {
                Layout.fillWidth: true
                title: qsTr("Version")
                subtitle: qsTr("1.0.0")
                icon: "📱"
                accentColor: Theme.tertiary
            }

            SettingsItem {
                Layout.fillWidth: true
                title: qsTr("PdfPilot")
                subtitle: qsTr("Built with Qt 6 and ❤️")
                icon: "⚡"
                accentColor: Theme.primary
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

                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: "🎨"
                        font.pixelSize: Theme.fontSizeDisplay
                    }

                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("Thank you for using PdfPilot!")
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
        property string icon
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
}
