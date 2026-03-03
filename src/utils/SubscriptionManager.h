#ifndef SUBSCRIPTIONMANAGER_H
#define SUBSCRIPTIONMANAGER_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QDateTime>
#include <QtQml>

class SubscriptionManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(QString plan READ plan NOTIFY subscriptionChanged)
    Q_PROPERTY(QString status READ status NOTIFY subscriptionChanged)
    Q_PROPERTY(bool isPremium READ isPremium NOTIFY subscriptionChanged)
    Q_PROPERTY(bool isFreeTrial READ isFreeTrial NOTIFY subscriptionChanged)
    Q_PROPERTY(int aiRequestsUsed READ aiRequestsUsed NOTIFY subscriptionChanged)
    Q_PROPERTY(int aiRequestsLimit READ aiRequestsLimit NOTIFY subscriptionChanged)
    Q_PROPERTY(QString expiresAt READ expiresAt NOTIFY subscriptionChanged)
    Q_PROPERTY(QString resetDate READ resetDate NOTIFY subscriptionChanged)
    Q_PROPERTY(bool isLoading READ isLoading NOTIFY loadingChanged)

public:
    static SubscriptionManager* instance();
    static SubscriptionManager* create(QQmlEngine *qmlEngine, QJSEngine *jsEngine);

    QString plan() const;
    QString status() const;
    bool isPremium() const;
    bool isFreeTrial() const;
    int aiRequestsUsed() const;
    int aiRequestsLimit() const;
    QString expiresAt() const;
    QString resetDate() const;
    bool isLoading() const;

    Q_INVOKABLE void fetchSubscription();
    Q_INVOKABLE bool canMakeAIRequest();
    Q_INVOKABLE void incrementUsage();
    Q_INVOKABLE void applyPurchase(const QString &planId, const QString &orderId, const QString &paymentId);

signals:
    void subscriptionChanged();
    void loadingChanged();
    void errorOccurred(const QString &error);
    void subscriptionFetched();

private:
    explicit SubscriptionManager(QObject *parent = nullptr);
    static SubscriptionManager *s_instance;

    void createDefaultSubscription();
    void updateFirestoreField(const QString &fieldPath, const QVariant &value);
    void parseFirestoreDocument(const QJsonObject &doc);
    QString firestoreUrl() const;
    QDateTime parseFirestoreTimestamp(const QJsonObject &obj) const;
    QJsonObject toFirestoreTimestamp(const QDateTime &dt) const;

    QNetworkAccessManager *m_networkManager;

    // Subscription data
    QString m_plan;
    QString m_status;
    QDateTime m_startDate;
    QDateTime m_expiresAt;
    int m_aiRequestsUsed;
    int m_aiRequestsLimit;
    QDateTime m_aiRequestsResetDate;
    QString m_razorpayOrderId;
    QString m_razorpayPaymentId;
    bool m_isLoading;
    bool m_waitingForToken = false;

    // Plan limits
    static const int FREE_TRIAL_LIMIT = 999;  // TODO: Change back to 2 for production
    static const int PAID_MONTHLY_LIMIT = 15;
};

#endif // SUBSCRIPTIONMANAGER_H
