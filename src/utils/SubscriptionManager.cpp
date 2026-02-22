#include "SubscriptionManager.h"
#include "AuthManager.h"
#include "Settings.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QDebug>
#include <QTimeZone>

SubscriptionManager* SubscriptionManager::s_instance = nullptr;

SubscriptionManager::SubscriptionManager(QObject *parent)
    : QObject(parent)
    , m_networkManager(new QNetworkAccessManager(this))
    , m_plan("free_trial")
    , m_status("active")
    , m_aiRequestsUsed(0)
    , m_aiRequestsLimit(FREE_TRIAL_LIMIT)
    , m_isLoading(false)
{
}

SubscriptionManager* SubscriptionManager::instance()
{
    if (!s_instance) {
        s_instance = new SubscriptionManager();
    }
    return s_instance;
}

SubscriptionManager* SubscriptionManager::create(QQmlEngine *qmlEngine, QJSEngine *jsEngine)
{
    Q_UNUSED(jsEngine)
    SubscriptionManager *inst = instance();
    QJSEngine::setObjectOwnership(inst, QJSEngine::CppOwnership);
    if (qmlEngine) {
        qmlEngine->setObjectOwnership(inst, QQmlEngine::CppOwnership);
    }
    return inst;
}

QString SubscriptionManager::plan() const { return m_plan; }
QString SubscriptionManager::status() const { return m_status; }

bool SubscriptionManager::isPremium() const
{
    return m_status == "active" && (m_plan == "monthly" || m_plan == "quarterly" || m_plan == "lifetime");
}

bool SubscriptionManager::isFreeTrial() const
{
    return m_plan == "free_trial";
}

int SubscriptionManager::aiRequestsUsed() const { return m_aiRequestsUsed; }
int SubscriptionManager::aiRequestsLimit() const { return m_aiRequestsLimit; }

QString SubscriptionManager::expiresAt() const
{
    if (!m_expiresAt.isValid() || m_plan == "lifetime" || m_plan == "free_trial") {
        return m_plan == "lifetime" ? tr("Never") : "";
    }
    return m_expiresAt.toString("MMM d, yyyy");
}

QString SubscriptionManager::resetDate() const
{
    if (!m_aiRequestsResetDate.isValid()) {
        return "";
    }
    return m_aiRequestsResetDate.toString("MMM d, yyyy");
}

bool SubscriptionManager::isLoading() const { return m_isLoading; }

QString SubscriptionManager::firestoreUrl() const
{
    QString projectId = Settings::instance()->property("firebaseProjectId").toString();
    if (projectId.isEmpty()) {
        projectId = "smart-pdf-toolkit"; // Default fallback
    }
    QString userId = AuthManager::instance()->userId();
    return QString("https://firestore.googleapis.com/v1/projects/%1/databases/(default)/documents/users/%2/subscription")
        .arg(projectId, userId);
}

void SubscriptionManager::fetchSubscription()
{
    QString userId = AuthManager::instance()->userId();
    if (userId.isEmpty()) {
        qDebug() << "SubscriptionManager: No user ID, cannot fetch subscription";
        return;
    }

    QString token = AuthManager::instance()->idToken();
    if (token.isEmpty()) {
        // Already waiting for token, don't queue another request
        if (m_waitingForToken) {
            qDebug() << "SubscriptionManager: Already waiting for token, skipping";
            return;
        }

        qDebug() << "SubscriptionManager: No ID token, requesting refresh...";
        m_waitingForToken = true;

        // Connect to idTokenChanged and retry
        connect(AuthManager::instance(), &AuthManager::idTokenChanged, this, [this]() {
            disconnect(AuthManager::instance(), &AuthManager::idTokenChanged, this, nullptr);
            m_waitingForToken = false;
            fetchSubscription();
        }, Qt::SingleShotConnection);
        AuthManager::instance()->refreshIdToken();
        return;
    }

    m_isLoading = true;
    emit loadingChanged();

    QNetworkRequest request{QUrl{firestoreUrl()}};
    request.setRawHeader("Authorization", ("Bearer " + token).toUtf8());
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

    qDebug() << "SubscriptionManager: Fetching subscription from Firestore...";

    QNetworkReply *reply = m_networkManager->get(request);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        m_isLoading = false;
        emit loadingChanged();

        if (reply->error() == QNetworkReply::ContentNotFoundError) {
            // Document doesn't exist, create default
            qDebug() << "SubscriptionManager: No subscription found, creating default...";
            createDefaultSubscription();
            reply->deleteLater();
            return;
        }

        if (reply->error() != QNetworkReply::NoError) {
            qDebug() << "SubscriptionManager: Error fetching subscription:" << reply->errorString();
            emit errorOccurred(tr("Failed to load subscription: ") + reply->errorString());
            reply->deleteLater();
            return;
        }

        QByteArray data = reply->readAll();
        QJsonDocument doc = QJsonDocument::fromJson(data);

        if (doc.isObject()) {
            parseFirestoreDocument(doc.object());
            emit subscriptionFetched();
        }

        reply->deleteLater();
    });
}

void SubscriptionManager::createDefaultSubscription()
{
    QString token = AuthManager::instance()->idToken();
    if (token.isEmpty()) {
        qDebug() << "SubscriptionManager: No token for creating subscription";
        return;
    }

    QDateTime now = QDateTime::currentDateTimeUtc();

    QJsonObject fields;
    fields["plan"] = QJsonObject{{"stringValue", "free_trial"}};
    fields["status"] = QJsonObject{{"stringValue", "active"}};
    fields["startDate"] = toFirestoreTimestamp(now);
    fields["expiresAt"] = QJsonObject{{"nullValue", QJsonValue::Null}};
    fields["aiRequestsUsed"] = QJsonObject{{"integerValue", "0"}};
    fields["aiRequestsLimit"] = QJsonObject{{"integerValue", QString::number(FREE_TRIAL_LIMIT)}};
    fields["aiRequestsResetDate"] = QJsonObject{{"nullValue", QJsonValue::Null}};
    fields["razorpayOrderId"] = QJsonObject{{"nullValue", QJsonValue::Null}};
    fields["razorpayPaymentId"] = QJsonObject{{"nullValue", QJsonValue::Null}};

    QJsonObject body;
    body["fields"] = fields;

    QNetworkRequest request{QUrl{firestoreUrl()}};
    request.setRawHeader("Authorization", ("Bearer " + token).toUtf8());
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

    QNetworkReply *reply = m_networkManager->sendCustomRequest(request, "PATCH", QJsonDocument(body).toJson());
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        if (reply->error() != QNetworkReply::NoError) {
            qDebug() << "SubscriptionManager: Error creating subscription:" << reply->errorString();
            emit errorOccurred(tr("Failed to create subscription"));
        } else {
            qDebug() << "SubscriptionManager: Default subscription created";
            // Set local state
            m_plan = "free_trial";
            m_status = "active";
            m_aiRequestsUsed = 0;
            m_aiRequestsLimit = FREE_TRIAL_LIMIT;
            emit subscriptionChanged();
            emit subscriptionFetched();
        }
        reply->deleteLater();
    });
}

void SubscriptionManager::parseFirestoreDocument(const QJsonObject &doc)
{
    QJsonObject fields = doc["fields"].toObject();

    m_plan = fields["plan"].toObject()["stringValue"].toString("free_trial");
    m_status = fields["status"].toObject()["stringValue"].toString("active");

    // Parse integer value (Firestore returns as string)
    QString usedStr = fields["aiRequestsUsed"].toObject()["integerValue"].toString("0");
    m_aiRequestsUsed = usedStr.toInt();

    QString limitStr = fields["aiRequestsLimit"].toObject()["integerValue"].toString("2");
    m_aiRequestsLimit = limitStr.toInt();

    // Parse timestamps
    if (fields["startDate"].toObject().contains("timestampValue")) {
        m_startDate = parseFirestoreTimestamp(fields["startDate"].toObject());
    }
    if (fields["expiresAt"].toObject().contains("timestampValue")) {
        m_expiresAt = parseFirestoreTimestamp(fields["expiresAt"].toObject());
    }
    if (fields["aiRequestsResetDate"].toObject().contains("timestampValue")) {
        m_aiRequestsResetDate = parseFirestoreTimestamp(fields["aiRequestsResetDate"].toObject());
    }

    m_razorpayOrderId = fields["razorpayOrderId"].toObject()["stringValue"].toString();
    m_razorpayPaymentId = fields["razorpayPaymentId"].toObject()["stringValue"].toString();

    // Check if plan is expired
    if (m_expiresAt.isValid() && m_expiresAt < QDateTime::currentDateTimeUtc()) {
        if (m_plan != "lifetime" && m_plan != "free_trial") {
            m_status = "expired";
        }
    }

    // Check if we need to reset monthly usage
    if (isPremium() && m_aiRequestsResetDate.isValid() && m_aiRequestsResetDate < QDateTime::currentDateTimeUtc()) {
        // Reset the counter
        m_aiRequestsUsed = 0;
        // Set next reset date to 30 days from now
        QDateTime nextReset = QDateTime::currentDateTimeUtc().addDays(30);
        m_aiRequestsResetDate = nextReset;

        // Update Firestore
        updateFirestoreField("aiRequestsUsed", 0);
        updateFirestoreField("aiRequestsResetDate", nextReset);
    }

    qDebug() << "SubscriptionManager: Parsed subscription - plan:" << m_plan
             << "status:" << m_status
             << "used:" << m_aiRequestsUsed << "/" << m_aiRequestsLimit;

    emit subscriptionChanged();
}

QDateTime SubscriptionManager::parseFirestoreTimestamp(const QJsonObject &obj) const
{
    QString timestampStr = obj["timestampValue"].toString();
    if (timestampStr.isEmpty()) {
        return QDateTime();
    }
    return QDateTime::fromString(timestampStr, Qt::ISODate);
}

QJsonObject SubscriptionManager::toFirestoreTimestamp(const QDateTime &dt) const
{
    return QJsonObject{{"timestampValue", dt.toString(Qt::ISODate)}};
}

bool SubscriptionManager::canMakeAIRequest()
{
    // Check plan status
    if (m_status == "expired") {
        return false;
    }

    // Check usage limit
    if (m_aiRequestsUsed >= m_aiRequestsLimit) {
        return false;
    }

    return true;
}

void SubscriptionManager::incrementUsage()
{
    m_aiRequestsUsed++;
    emit subscriptionChanged();

    // Update Firestore
    updateFirestoreField("aiRequestsUsed", m_aiRequestsUsed);
}

void SubscriptionManager::updateFirestoreField(const QString &fieldPath, const QVariant &value)
{
    QString token = AuthManager::instance()->idToken();
    if (token.isEmpty()) return;

    QJsonObject fields;

    if (value.typeId() == QMetaType::Int) {
        fields[fieldPath] = QJsonObject{{"integerValue", QString::number(value.toInt())}};
    } else if (value.typeId() == QMetaType::QString) {
        fields[fieldPath] = QJsonObject{{"stringValue", value.toString()}};
    } else if (value.typeId() == QMetaType::QDateTime) {
        fields[fieldPath] = toFirestoreTimestamp(value.toDateTime());
    }

    QJsonObject body;
    body["fields"] = fields;

    QString url = firestoreUrl() + "?updateMask.fieldPaths=" + fieldPath;
    QNetworkRequest request{QUrl{url}};
    request.setRawHeader("Authorization", ("Bearer " + token).toUtf8());
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

    QNetworkReply *reply = m_networkManager->sendCustomRequest(request, "PATCH", QJsonDocument(body).toJson());
    connect(reply, &QNetworkReply::finished, this, [reply]() {
        if (reply->error() != QNetworkReply::NoError) {
            qDebug() << "SubscriptionManager: Error updating field:" << reply->errorString();
        }
        reply->deleteLater();
    });
}

void SubscriptionManager::applyPurchase(const QString &planId, const QString &orderId, const QString &paymentId)
{
    QString token = AuthManager::instance()->idToken();
    if (token.isEmpty()) {
        emit errorOccurred(tr("Not authenticated"));
        return;
    }

    QDateTime now = QDateTime::currentDateTimeUtc();
    QDateTime expiresAt;
    int durationDays = 0;

    if (planId == "monthly") {
        durationDays = 30;
    } else if (planId == "quarterly") {
        durationDays = 90;
    } else if (planId == "lifetime") {
        durationDays = 0; // Never expires
    }

    if (durationDays > 0) {
        expiresAt = now.addDays(durationDays);
    }

    QJsonObject fields;
    fields["plan"] = QJsonObject{{"stringValue", planId}};
    fields["status"] = QJsonObject{{"stringValue", "active"}};
    fields["startDate"] = toFirestoreTimestamp(now);
    fields["aiRequestsUsed"] = QJsonObject{{"integerValue", "0"}};
    fields["aiRequestsLimit"] = QJsonObject{{"integerValue", QString::number(PAID_MONTHLY_LIMIT)}};
    fields["aiRequestsResetDate"] = toFirestoreTimestamp(now.addDays(30));
    fields["razorpayOrderId"] = QJsonObject{{"stringValue", orderId}};
    fields["razorpayPaymentId"] = QJsonObject{{"stringValue", paymentId}};

    if (expiresAt.isValid()) {
        fields["expiresAt"] = toFirestoreTimestamp(expiresAt);
    } else {
        fields["expiresAt"] = QJsonObject{{"nullValue", QJsonValue::Null}};
    }

    QJsonObject body;
    body["fields"] = fields;

    QNetworkRequest request{QUrl{firestoreUrl()}};
    request.setRawHeader("Authorization", ("Bearer " + token).toUtf8());
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

    m_isLoading = true;
    emit loadingChanged();

    QNetworkReply *reply = m_networkManager->sendCustomRequest(request, "PATCH", QJsonDocument(body).toJson());
    connect(reply, &QNetworkReply::finished, this, [this, reply, planId, expiresAt]() {
        m_isLoading = false;
        emit loadingChanged();

        if (reply->error() != QNetworkReply::NoError) {
            qDebug() << "SubscriptionManager: Error applying purchase:" << reply->errorString();
            emit errorOccurred(tr("Failed to activate subscription"));
        } else {
            qDebug() << "SubscriptionManager: Purchase applied successfully";

            // Update local state
            m_plan = planId;
            m_status = "active";
            m_aiRequestsUsed = 0;
            m_aiRequestsLimit = PAID_MONTHLY_LIMIT;
            m_expiresAt = expiresAt;
            m_aiRequestsResetDate = QDateTime::currentDateTimeUtc().addDays(30);

            emit subscriptionChanged();
        }
        reply->deleteLater();
    });
}
