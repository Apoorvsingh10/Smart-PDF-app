import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import PDF_ToolKit 1.0

Page {
    id: root

    signal back()
    signal showToast(string message, string type)

    background: Rectangle {
        color: Theme.background
    }

    // Handle payment results
    Connections {
        target: PaymentManager
        function onPaymentSuccess(paymentId, orderId, plan) {
            root.showToast(qsTr("AI Assistant unlocked!"), "success")
            root.back()
        }
        function onPaymentFailed(errorCode, errorDesc) {
            root.showToast(qsTr("Payment failed: ") + errorDesc, "error")
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
                text: qsTr("Upgrade")
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
            spacing: Theme.spacingLarge

            Item { Layout.preferredHeight: Theme.spacingLarge }

            // Hero section - Centered
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                spacing: Theme.spacingMedium

                // AI Icon with glow effect
                Item {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 120
                    Layout.preferredHeight: 120

                    // Outer glow
                    Rectangle {
                        anchors.centerIn: parent
                        width: 120
                        height: 120
                        radius: 60
                        color: "transparent"
                        border.width: 2
                        border.color: Qt.rgba(139/255, 92/255, 246/255, 0.3)
                    }

                    // Main circle
                    Rectangle {
                        anchors.centerIn: parent
                        width: 100
                        height: 100
                        radius: 50

                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "#8B5CF6" }
                            GradientStop { position: 1.0; color: "#7C3AED" }
                        }

                        // Custom AI Icon using Canvas
                        Canvas {
                            anchors.centerIn: parent
                            width: 48
                            height: 48

                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.reset();

                                var c = "#FFFFFF";
                                ctx.strokeStyle = c;
                                ctx.fillStyle = c;
                                ctx.lineWidth = 2.5;
                                ctx.lineCap = "round";
                                ctx.lineJoin = "round";

                                var w = width;
                                var h = height;
                                var cx = w / 2;
                                var cy = h / 2;

                                // Center brain circle
                                ctx.beginPath();
                                ctx.arc(cx, cy, 8, 0, Math.PI * 2);
                                ctx.fill();

                                // Neural connection nodes
                                var nodes = [
                                    {x: cx, y: 4},
                                    {x: w - 4, y: cy},
                                    {x: cx, y: h - 4},
                                    {x: 4, y: cy},
                                    {x: w - 8, y: 8},
                                    {x: w - 8, y: h - 8},
                                    {x: 8, y: h - 8},
                                    {x: 8, y: 8}
                                ];

                                // Draw connection lines
                                ctx.beginPath();
                                for (var i = 0; i < nodes.length; i++) {
                                    ctx.moveTo(cx, cy);
                                    ctx.lineTo(nodes[i].x, nodes[i].y);
                                }
                                ctx.stroke();

                                // Draw outer nodes
                                for (var j = 0; j < nodes.length; j++) {
                                    ctx.beginPath();
                                    ctx.arc(nodes[j].x, nodes[j].y, 3.5, 0, Math.PI * 2);
                                    ctx.fill();
                                }

                                // Pulse ring
                                ctx.lineWidth = 1.5;
                                ctx.globalAlpha = 0.4;
                                ctx.beginPath();
                                ctx.arc(cx, cy, 16, 0, Math.PI * 2);
                                ctx.stroke();
                            }
                        }
                    }
                }

                Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("Unlock AI Assistant")
                    font.pixelSize: 26
                    font.weight: Font.Bold
                    color: Theme.surfaceForeground
                    horizontalAlignment: Text.AlignHCenter
                }

                Label {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.maximumWidth: 280
                    text: qsTr("Summarize PDFs and ask questions instantly")
                    font.pixelSize: Theme.fontSizeBody
                    color: Theme.surfaceVariantForeground
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }
            }

            Item { Layout.preferredHeight: Theme.spacingSmall }

            // Plan cards
            ColumnLayout {
                Layout.fillWidth: true
                Layout.margins: Theme.spacingMedium
                spacing: Theme.spacingSmall

                // Monthly
                PlanCard {
                    Layout.fillWidth: true
                    planId: "monthly"
                    planLabel: qsTr("Monthly")
                    price: PaymentManager.getPlanPrice("monthly")
                    priceSubtitle: qsTr("/month")
                    features: [qsTr("15 AI requests per month"), qsTr("Cancel anytime")]
                    onSelected: PaymentManager.startPayment("monthly")
                }

                // Quarterly - Best value
                PlanCard {
                    Layout.fillWidth: true
                    planId: "quarterly"
                    planLabel: qsTr("Quarterly")
                    price: PaymentManager.getPlanPrice("quarterly")
                    priceSubtitle: qsTr("/3 months")
                    features: [qsTr("15 AI requests per month"), qsTr("Save 17%")]
                    isBestValue: true
                    onSelected: PaymentManager.startPayment("quarterly")
                }

                // Lifetime
                PlanCard {
                    Layout.fillWidth: true
                    planId: "lifetime"
                    planLabel: qsTr("Early Bird Lifetime")
                    price: PaymentManager.getPlanPrice("lifetime")
                    priceSubtitle: qsTr("one-time")
                    features: [qsTr("15 AI requests per month"), qsTr("Limited offer")]
                    isLifetime: true
                    onSelected: PaymentManager.startPayment("lifetime")
                }
            }

            // Privacy badge
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: privacyRow.width + Theme.spacingLarge
                Layout.preferredHeight: 32
                radius: Theme.radiusFull
                color: Qt.rgba(Theme.success.r, Theme.success.g, Theme.success.b, 0.1)

                RowLayout {
                    id: privacyRow
                    anchors.centerIn: parent
                    spacing: Theme.spacingTiny

                    Label {
                        text: "🔒"
                        font.pixelSize: Theme.fontSizeBody
                    }

                    Label {
                        text: qsTr("Your PDFs stay on your device")
                        font.pixelSize: Theme.fontSizeCaption
                        color: Theme.success
                    }
                }
            }

            Item { Layout.preferredHeight: Theme.spacingXLarge }
        }
    }

    // Loading overlay
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, 0.9)
        visible: PaymentManager.isProcessing

        ColumnLayout {
            anchors.centerIn: parent
            spacing: Theme.spacingMedium

            BusyIndicator {
                Layout.alignment: Qt.AlignHCenter
                running: PaymentManager.isProcessing
                Material.accent: Theme.primary
            }

            Label {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Processing payment...")
                font.pixelSize: Theme.fontSizeBody
                color: Theme.surfaceForeground
            }
        }
    }

    // Plan card component
    component PlanCard: Rectangle {
        id: planCard

        property string planId
        property string planLabel
        property string price
        property string priceSubtitle
        property var features: []
        property bool isBestValue: false
        property bool isLifetime: false

        signal selected()

        implicitHeight: cardContent.height + Theme.spacingLarge
        radius: Theme.radiusMedium
        color: Theme.cardSurface
        border.width: isBestValue ? 2 : 1
        border.color: isBestValue ? Theme.primary : Theme.outlineVariant

        ColumnLayout {
            id: cardContent
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Theme.spacingMedium
            spacing: Theme.spacingSmall

            // Best value badge
            Rectangle {
                visible: isBestValue
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: bestValueLabel.width + Theme.spacingMedium
                Layout.preferredHeight: 24
                radius: Theme.radiusFull
                color: Theme.primary

                Label {
                    id: bestValueLabel
                    anchors.centerIn: parent
                    text: qsTr("BEST VALUE")
                    font.pixelSize: Theme.fontSizeTiny
                    font.weight: Font.Bold
                    color: Theme.primaryForeground
                }
            }

            // Plan name
            Label {
                Layout.alignment: Qt.AlignHCenter
                text: planLabel
                font.pixelSize: Theme.fontSizeSubtitle
                font.weight: Font.DemiBold
                color: Theme.surfaceForeground
            }

            // Price
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Theme.spacingTiny

                Label {
                    text: price
                    font.pixelSize: Theme.fontSizeHeadline
                    font.weight: Font.Bold
                    color: isBestValue ? Theme.primary : Theme.surfaceForeground
                }

                Label {
                    text: priceSubtitle
                    font.pixelSize: Theme.fontSizeCaption
                    color: Theme.surfaceVariantForeground
                }
            }

            // Features
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingTiny

                Repeater {
                    model: features

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: Theme.spacingTiny

                        Label {
                            text: "✓"
                            font.pixelSize: Theme.fontSizeCaption
                            color: Theme.success
                        }

                        Label {
                            text: modelData
                            font.pixelSize: Theme.fontSizeCaption
                            color: Theme.surfaceVariantForeground
                        }
                    }
                }
            }

            // Button
            Button {
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.buttonHeight
                text: qsTr("Get Started")
                Material.background: isBestValue ? Theme.primary : Theme.surfaceContainer
                Material.foreground: isBestValue ? Theme.primaryForeground : Theme.surfaceForeground
                font.weight: Font.DemiBold
                enabled: !PaymentManager.isProcessing

                onClicked: planCard.selected()
            }
        }
    }
}
