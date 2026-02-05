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
        width: Math.min(parent.width - 48, 400)
        spacing: Theme.spacingLarge

        // Logo Section
        Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 120
            Layout.preferredHeight: 120
            
            Rectangle {
                anchors.fill: parent
                radius: 24
                color: Theme.primaryContainer
                
                Image {
                    anchors.centerIn: parent
                    source: "qrc:/PDF_ToolKit/resources/icons/pdf.svg"
                    sourceSize.width: 80
                    sourceSize.height: 80
                    
                    // Simple color overlay effect (tinting)
                    property bool colored: true
                }
            }
        }
        
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Theme.spacingTiny
            
            Label {
                text: qsTr("PdfPilot")
                font.pixelSize: 32
                font.weight: Font.Bold
                color: Theme.onBackground
                Layout.alignment: Qt.AlignHCenter
            }
            
            Label {
                text: qsTr("Your Ultimate PDF Tool")
                font.pixelSize: Theme.fontSizeSubtitle
                color: Theme.onSurfaceVariant
                Layout.alignment: Qt.AlignHCenter
            }
        }

        Item { Layout.preferredHeight: 32 } // Spacer

        // Buttons
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingMedium

            // Google Button
            Button {
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                
                contentItem: RowLayout {
                    spacing: 12
                    
                    // Placeholder icon circle
                    Rectangle {
                        width: 24; height: 24; radius: 12
                        color: "transparent"
                        border.color: "#DB4437" // Google Red
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
                        color: "#757575"
                    }
                }
                
                background: Rectangle {
                    color: "#FFFFFF"
                    radius: Theme.radiusMedium
                    border.width: 1
                    border.color: "#E0E0E0"
                }
                
                onClicked: AuthManager.loginWithGoogle()
            }

            // Facebook Button
            Button {
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                
                contentItem: RowLayout {
                    spacing: 12
                    
                    // Placeholder icon circle
                    Rectangle {
                        width: 24; height: 24; radius: 12
                        color: "white"
                        
                        Label {
                            anchors.centerIn: parent
                            text: "f"
                            font.bold: true
                            color: "#1877F2"
                        }
                    }
                    
                    Label {
                        text: qsTr("Continue with Facebook")
                        font.weight: Font.Medium
                        font.pixelSize: Theme.fontSizeBody
                        color: "#FFFFFF"
                    }
                }
                
                background: Rectangle {
                    color: "#1877F2" // Facebook Blue
                    radius: Theme.radiusMedium
                }
                
                onClicked: AuthManager.loginWithFacebook()
            }
            
            Item { Layout.preferredHeight: 8 }

            // Divider
            RowLayout {
                Layout.fillWidth: true
                spacing: 16
                
                Rectangle { Layout.fillWidth: true; height: 1; color: Theme.outlineVariant }
                Label { text: qsTr("OR"); color: Theme.onSurfaceVariant; font.pixelSize: 12 }
                Rectangle { Layout.fillWidth: true; height: 1; color: Theme.outlineVariant }
            }

            // Guest Button
            Button {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                text: qsTr("Continue as Guest")
                font.weight: Font.Medium
                
                contentItem: Text {
                    text: parent.text
                    font: parent.font
                    opacity: enabled ? 1.0 : 0.3
                    color: Theme.onSurface
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
