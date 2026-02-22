#include "PaymentManager.h"
#include "Settings.h"
#include "AuthManager.h"
#include "SubscriptionManager.h"
#include <QDebug>
#include <QUuid>

#ifdef Q_OS_ANDROID
#include <QJniObject>
#include <QJniEnvironment>
#include <QCoreApplication>
#endif

PaymentManager* PaymentManager::s_instance = nullptr;

#ifdef Q_OS_ANDROID
// JNI callback functions - called from Java
static void onPaymentSuccessCallback(JNIEnv *env, jobject /*thiz*/, jstring jPaymentId, jstring jOrderId)
{
    QString paymentId = QJniObject(jPaymentId).toString();
    QString orderId = QJniObject(jOrderId).toString();

    qDebug() << "PaymentManager: Payment success - paymentId:" << paymentId << "orderId:" << orderId;

    QMetaObject::invokeMethod(PaymentManager::instance(), [=]() {
        PaymentManager::instance()->handlePaymentSuccess(paymentId, orderId);
    }, Qt::QueuedConnection);
}

static void onPaymentFailedCallback(JNIEnv *env, jobject /*thiz*/, jstring jErrorCode, jstring jErrorDesc)
{
    QString errorCode = QJniObject(jErrorCode).toString();
    QString errorDesc = QJniObject(jErrorDesc).toString();

    qDebug() << "PaymentManager: Payment failed - code:" << errorCode << "desc:" << errorDesc;

    QMetaObject::invokeMethod(PaymentManager::instance(), [=]() {
        PaymentManager::instance()->handlePaymentFailed(errorCode, errorDesc);
    }, Qt::QueuedConnection);
}

// Register native methods with Java
static bool registerNativeMethods()
{
    JNINativeMethod methods[] = {
        {"onPaymentSuccess", "(Ljava/lang/String;Ljava/lang/String;)V", reinterpret_cast<void *>(onPaymentSuccessCallback)},
        {"onPaymentFailed", "(Ljava/lang/String;Ljava/lang/String;)V", reinterpret_cast<void *>(onPaymentFailedCallback)}
    };

    QJniEnvironment env;
    jclass clazz = env.findClass("io/smartpdf/app/RazorpayHelper");
    if (clazz == nullptr) {
        qWarning() << "PaymentManager: Could not find RazorpayHelper class";
        return false;
    }

    if (env->RegisterNatives(clazz, methods, sizeof(methods) / sizeof(methods[0])) < 0) {
        qWarning() << "PaymentManager: Failed to register native methods";
        return false;
    }

    qDebug() << "PaymentManager: Native methods registered successfully";
    return true;
}
#endif

PaymentManager::PaymentManager(QObject *parent)
    : QObject(parent)
    , m_isProcessing(false)
{
#ifdef Q_OS_ANDROID
    registerNativeMethods();
#endif
}

PaymentManager* PaymentManager::instance()
{
    if (!s_instance) {
        s_instance = new PaymentManager();
    }
    return s_instance;
}

PaymentManager* PaymentManager::create(QQmlEngine *qmlEngine, QJSEngine *jsEngine)
{
    Q_UNUSED(jsEngine)
    PaymentManager *inst = instance();
    QJSEngine::setObjectOwnership(inst, QJSEngine::CppOwnership);
    if (qmlEngine) {
        qmlEngine->setObjectOwnership(inst, QQmlEngine::CppOwnership);
    }
    return inst;
}

bool PaymentManager::isProcessing() const { return m_isProcessing; }
QString PaymentManager::currentPlan() const { return m_currentPlan; }

int PaymentManager::getPlanAmountPaise(const QString &planId) const
{
    if (planId == "monthly") return MONTHLY_PRICE;
    if (planId == "quarterly") return QUARTERLY_PRICE;
    if (planId == "lifetime") return LIFETIME_PRICE;
    return 0;
}

QString PaymentManager::getPlanPrice(const QString &planId) const
{
    int paise = getPlanAmountPaise(planId);
    int rupees = paise / 100;
    return QString::fromUtf8("₹") + QString::number(rupees);
}

QString PaymentManager::getPlanLabel(const QString &planId) const
{
    if (planId == "monthly") return tr("Monthly");
    if (planId == "quarterly") return tr("Quarterly");
    if (planId == "lifetime") return tr("Early Bird Lifetime");
    return planId;
}

QString PaymentManager::generateOrderId() const
{
    // Generate a UUID-based order ID for MVP
    // In production, this should come from your backend
    return "order_" + QUuid::createUuid().toString(QUuid::Id128).left(16);
}

void PaymentManager::startPayment(const QString &planId)
{
    if (m_isProcessing) {
        qDebug() << "PaymentManager: Payment already in progress";
        return;
    }

    int amount = getPlanAmountPaise(planId);
    if (amount == 0) {
        emit paymentFailed("INVALID_PLAN", "Invalid plan selected");
        return;
    }

    m_currentPlan = planId;
    m_currentOrderId = generateOrderId();
    m_isProcessing = true;
    emit processingChanged();
    emit currentPlanChanged();

    QString description = getPlanLabel(planId) + " - Smart PDF AI";
    QString email = AuthManager::instance()->userEmail();
    if (email.isEmpty()) {
        email = "user@smartpdf.app";
    }

#ifdef Q_OS_ANDROID
    QString razorpayKey = Settings::instance()->property("razorpayKeyId").toString();
    if (razorpayKey.isEmpty()) {
        qWarning() << "PaymentManager: Razorpay key not configured";
        m_isProcessing = false;
        emit processingChanged();
        emit paymentFailed("CONFIG_ERROR", "Payment not configured");
        return;
    }

    qDebug() << "PaymentManager: Starting Razorpay payment - amount:" << amount << "plan:" << planId;

    QJniObject jOrderId = QJniObject::fromString(m_currentOrderId);
    QJniObject jDescription = QJniObject::fromString(description);
    QJniObject jEmail = QJniObject::fromString(email);
    QJniObject jKey = QJniObject::fromString(razorpayKey);

    QJniObject activity = QJniObject::callStaticObjectMethod(
        "org/qtproject/qt/android/QtNative",
        "activity",
        "()Landroid/app/Activity;"
    );

    if (activity.isValid()) {
        QJniObject::callStaticMethod<void>(
            "io/smartpdf/app/RazorpayHelper",
            "startPayment",
            "(Landroid/app/Activity;Ljava/lang/String;ILjava/lang/String;Ljava/lang/String;Ljava/lang/String;)V",
            activity.object(),
            jKey.object<jstring>(),
            amount,
            jOrderId.object<jstring>(),
            jDescription.object<jstring>(),
            jEmail.object<jstring>()
        );
    } else {
        qWarning() << "PaymentManager: Could not get activity";
        m_isProcessing = false;
        emit processingChanged();
        emit paymentFailed("SYSTEM_ERROR", "Could not start payment");
    }
#else
    // Desktop fallback - simulate successful payment for testing
    qDebug() << "PaymentManager: Desktop mode - simulating payment success";
    QMetaObject::invokeMethod(this, [this]() {
        handlePaymentSuccess("pay_test_" + QUuid::createUuid().toString(QUuid::Id128).left(16), m_currentOrderId);
    }, Qt::QueuedConnection);
#endif
}

void PaymentManager::handlePaymentSuccess(const QString &paymentId, const QString &orderId)
{
    qDebug() << "PaymentManager: Processing successful payment";

    m_isProcessing = false;
    emit processingChanged();

    // Apply purchase to subscription
    SubscriptionManager::instance()->applyPurchase(m_currentPlan, orderId, paymentId);

    emit paymentSuccess(paymentId, orderId, m_currentPlan);
    emit purchaseComplete();
}

void PaymentManager::handlePaymentFailed(const QString &errorCode, const QString &errorDesc)
{
    m_isProcessing = false;
    emit processingChanged();

    emit paymentFailed(errorCode, errorDesc);
}
