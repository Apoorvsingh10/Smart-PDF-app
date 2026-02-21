import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material
import PDF_ToolKit 1.0
import "../theme"

Page {
    id: root
    
    signal loginSuccess()
    signal showToast(string message, string type)

    background: Rectangle {
        color: Theme.background
        
        // Background decoration
        Rectangle {
            width: parent.width * 1.5
            height: width
            radius: width / 2
            x: -width * 0.2
            y: -height * 0.5
            color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.05)
        }
    }

    // Auth Manager connections
    Connections {
        target: AuthManager
        function onAuthSuccess(message) {
            root.showToast(message, "success")
            if (AuthManager.isAuthenticated) {
                root.loginSuccess()
            }
        }
        function onAuthError(message) {
            root.showToast(message, "error")
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(parent.width - Theme.spacingXXLarge, 400)
        spacing: Theme.spacingLarge

        // Logo Section
        Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 120
            Layout.preferredHeight: 120

            Rectangle {
                anchors.fill: parent
                radius: Theme.radiusLarge
                color: Theme.primaryContainer

                Image {
                    anchors.centerIn: parent
                    source: "qrc:/PDF_ToolKit/resources/icons/pdf.svg"
                    sourceSize.width: Theme.iconSizeHero
                    sourceSize.height: Theme.iconSizeHero
                }
            }
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Theme.spacingTiny

            Label {
                text: qsTr("Smart PDF")
                font.pixelSize: Theme.fontSizeDisplay
                font.weight: Font.Bold
                color: Theme.backgroundForeground
                Layout.alignment: Qt.AlignHCenter
            }

            Label {
                text: qsTr("Your Ultimate PDF Tool")
                font.pixelSize: Theme.fontSizeSubtitle
                color: Theme.surfaceVariantForeground
                Layout.alignment: Qt.AlignHCenter
            }
        }

        Item { Layout.preferredHeight: Theme.spacingXLarge }

        // Buttons
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingMedium

            // Google Button
            Button {
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.buttonHeight

                contentItem: RowLayout {
                    spacing: Theme.spacingSmall

                    Rectangle {
                        width: Theme.iconSizeMedium
                        height: Theme.iconSizeMedium
                        radius: Theme.iconSizeMedium / 2
                        color: "transparent"
                        border.color: "#DB4437"
                        border.width: 2

                        Label {
                            anchors.centerIn: parent
                            text: "G"
                            font.bold: true
                            color: "#DB4437"
                        }
                    }

                    Label {
                        text: qsTr("Sign in with Google")
                        font.weight: Font.Medium
                        font.pixelSize: Theme.fontSizeBody
                        color: Theme.surfaceVariantForeground
                    }
                }

                background: Rectangle {
                    color: Theme.surface
                    radius: Theme.radiusMedium
                    border.width: 1
                    border.color: Theme.outlineVariant
                }

                onClicked: AuthManager.loginWithGoogle()
            }

            Item { Layout.preferredHeight: Theme.spacingSmall }

            // Divider
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingMedium

                Rectangle { Layout.fillWidth: true; height: 1; color: Theme.outlineVariant }
                Label { text: qsTr("OR"); color: Theme.surfaceVariantForeground; font.pixelSize: Theme.fontSizeCaption }
                Rectangle { Layout.fillWidth: true; height: 1; color: Theme.outlineVariant }
            }

            // Guest Button
            Button {
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.buttonHeightSmall
                text: qsTr("Continue as Guest")
                font.weight: Font.Medium

                contentItem: Text {
                    text: parent.text
                    font: parent.font
                    opacity: enabled ? 1.0 : Theme.disabledOpacity
                    color: Theme.surfaceForeground
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }

                background: Rectangle {
                    color: "transparent"
                    radius: Theme.radiusMedium
                    border.width: 1
                    border.color: Theme.outline
                }

                onClicked: AuthManager.loginAnonymously()
            }
        }
    }
}
