#ifndef PAYMENTMANAGER_H
#define PAYMENTMANAGER_H

#include <QObject>
#include <QMap>
#include <QtQml>

class PaymentManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(bool isProcessing READ isProcessing NOTIFY processingChanged)
    Q_PROPERTY(QString currentPlan READ currentPlan NOTIFY currentPlanChanged)

public:
    static PaymentManager* instance();
    static PaymentManager* create(QQmlEngine *qmlEngine, QJSEngine *jsEngine);

    bool isProcessing() const;
    QString currentPlan() const;

    Q_INVOKABLE void startPayment(const QString &planId);
    Q_INVOKABLE QString getPlanPrice(const QString &planId) const;
    Q_INVOKABLE QString getPlanLabel(const QString &planId) const;

    // Google Play Billing helpers
    QString getGooglePlayProductId(const QString &planId) const;
    void updateProductPrice(const QString &productId, const QString &price);

signals:
    void processingChanged();
    void currentPlanChanged();
    void paymentSuccess(const QString &paymentId, const QString &orderId, const QString &plan);
    void paymentFailed(const QString &errorCode, const QString &errorDesc);
    void purchaseComplete();
    void pricesUpdated();
    void purchasePending();

public slots:
    void handlePaymentSuccess(const QString &purchaseToken, const QString &orderId);
    void handlePaymentFailed(const QString &errorCode, const QString &errorDesc);

private:
    explicit PaymentManager(QObject *parent = nullptr);
    static PaymentManager *s_instance;

    bool m_isProcessing;
    QString m_currentPlan;

    // Cached prices from Google Play
    QMap<QString, QString> m_productPrices;
};

#endif // PAYMENTMANAGER_H
