#ifndef PAYMENTMANAGER_H
#define PAYMENTMANAGER_H

#include <QObject>
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

signals:
    void processingChanged();
    void currentPlanChanged();
    void paymentSuccess(const QString &paymentId, const QString &orderId, const QString &plan);
    void paymentFailed(const QString &errorCode, const QString &errorDesc);
    void purchaseComplete();

public slots:
    void handlePaymentSuccess(const QString &paymentId, const QString &orderId);
    void handlePaymentFailed(const QString &errorCode, const QString &errorDesc);

private:
    explicit PaymentManager(QObject *parent = nullptr);
    static PaymentManager *s_instance;

    int getPlanAmountPaise(const QString &planId) const;
    QString generateOrderId() const;

    bool m_isProcessing;
    QString m_currentPlan;
    QString m_currentOrderId;

    // Plan prices in paise (for INR)
    static const int MONTHLY_PRICE = 10000;     // ₹100
    static const int QUARTERLY_PRICE = 25000;   // ₹250
    static const int LIFETIME_PRICE = 100000;   // ₹1,000
};

#endif // PAYMENTMANAGER_H
