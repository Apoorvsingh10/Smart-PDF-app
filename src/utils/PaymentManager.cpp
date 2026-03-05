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
// JNI callback functions - called from Java BillingHelper

static void onBillingConnectedCallback(JNIEnv *env, jobject /*thiz*/)
{
    qDebug() << "PaymentManager: Google Play Billing connected";
}

static void onBillingDisconnectedCallback(JNIEnv *env, jobject /*thiz*/)
{
    qDebug() << "PaymentManager: Google Play Billing disconnected";
}

static void onProductDetailsLoadedCallback(JNIEnv *env, jobject /*thiz*/,
                                            jstring jProductId, jstring jPrice, jstring jTitle)
{
    QString productId = QJniObject(jProductId).toString();
    QString price = QJniObject(jPrice).toString();
    QString title = QJniObject(jTitle).toString();

    qDebug() << "PaymentManager: Product loaded -" << productId << "price:" << price;

    // Store price for later use (could emit signal to update UI)
    QMetaObject::invokeMethod(PaymentManager::instance(), [=]() {
        PaymentManager::instance()->updateProductPrice(productId, price);
    }, Qt::QueuedConnection);
}

static void onPurchaseSuccessCallback(JNIEnv *env, jobject /*thiz*/,
                                       jstring jProductId, jstring jPurchaseToken, jstring jOrderId)
{
    QString productId = QJniObject(jProductId).toString();
    QString purchaseToken = QJniObject(jPurchaseToken).toString();
    QString orderId = QJniObject(jOrderId).toString();

    qDebug() << "PaymentManager: Purchase success - productId:" << productId << "orderId:" << orderId;

    QMetaObject::invokeMethod(PaymentManager::instance(), [=]() {
        PaymentManager::instance()->handlePaymentSuccess(purchaseToken, orderId);
    }, Qt::QueuedConnection);
}

static void onPurchaseFailedCallback(JNIEnv *env, jobject /*thiz*/,
                                      jstring jErrorCode, jstring jErrorMessage)
{
    QString errorCode = QJniObject(jErrorCode).toString();
    QString errorMessage = QJniObject(jErrorMessage).toString();

    qDebug() << "PaymentManager: Purchase failed - code:" << errorCode << "msg:" << errorMessage;

    QMetaObject::invokeMethod(PaymentManager::instance(), [=]() {
        PaymentManager::instance()->handlePaymentFailed(errorCode, errorMessage);
    }, Qt::QueuedConnection);
}

static void onPurchasePendingCallback(JNIEnv *env, jobject /*thiz*/, jstring jProductId)
{
    QString productId = QJniObject(jProductId).toString();
    qDebug() << "PaymentManager: Purchase pending -" << productId;

    QMetaObject::invokeMethod(PaymentManager::instance(), [=]() {
        emit PaymentManager::instance()->purchasePending();
    }, Qt::QueuedConnection);
}

// Register native methods with Java
static bool registerNativeMethods()
{
    JNINativeMethod methods[] = {
        {"onBillingConnected", "()V", reinterpret_cast<void *>(onBillingConnectedCallback)},
        {"onBillingDisconnected", "()V", reinterpret_cast<void *>(onBillingDisconnectedCallback)},
        {"onProductDetailsLoaded", "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V",
            reinterpret_cast<void *>(onProductDetailsLoadedCallback)},
        {"onPurchaseSuccess", "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V",
            reinterpret_cast<void *>(onPurchaseSuccessCallback)},
        {"onPurchaseFailed", "(Ljava/lang/String;Ljava/lang/String;)V",
            reinterpret_cast<void *>(onPurchaseFailedCallback)},
        {"onPurchasePending", "(Ljava/lang/String;)V",
            reinterpret_cast<void *>(onPurchasePendingCallback)}
    };

    QJniEnvironment env;
    jclass clazz = env.findClass("io/smartpdf/app/BillingHelper");
    if (clazz == nullptr) {
        qWarning() << "PaymentManager: Could not find BillingHelper class";
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

QString PaymentManager::getGooglePlayProductId(const QString &planId) const
{
    // Map internal plan IDs to Google Play product IDs
    if (planId == "monthly") return "smartpdf_monthly";
    if (planId == "quarterly") return "smartpdf_quarterly";
    if (planId == "lifetime") return "smartpdf_lifetime";
    return "";
}

QString PaymentManager::getPlanPrice(const QString &planId) const
{
    // Return cached price from Google Play, or fallback
    QString productId = getGooglePlayProductId(planId);
    if (m_productPrices.contains(productId)) {
        return m_productPrices[productId];
    }

    // Fallback prices (will be overwritten when Google Play responds)
    if (planId == "monthly") return QString::fromUtf8("₹100");
    if (planId == "quarterly") return QString::fromUtf8("₹250");
    if (planId == "lifetime") return QString::fromUtf8("₹1,000");
    return "";
}

QString PaymentManager::getPlanLabel(const QString &planId) const
{
    if (planId == "monthly") return tr("Monthly");
    if (planId == "quarterly") return tr("Quarterly");
    if (planId == "lifetime") return tr("Early Bird Lifetime");
    return planId;
}

void PaymentManager::updateProductPrice(const QString &productId, const QString &price)
{
    m_productPrices[productId] = price;
    emit pricesUpdated();
}

void PaymentManager::startPayment(const QString &planId)
{
    if (m_isProcessing) {
        qDebug() << "PaymentManager: Payment already in progress";
        return;
    }

    QString productId = getGooglePlayProductId(planId);
    if (productId.isEmpty()) {
        emit paymentFailed("INVALID_PLAN", "Invalid plan selected");
        return;
    }

    m_currentPlan = planId;
    m_isProcessing = true;
    emit processingChanged();
    emit currentPlanChanged();

    qDebug() << "PaymentManager: Starting Google Play purchase for:" << productId;

#ifdef Q_OS_ANDROID
    QJniObject jProductId = QJniObject::fromString(productId);

    QJniObject::callStaticMethod<void>(
        "io/smartpdf/app/BillingHelper",
        "launchPurchase",
        "(Ljava/lang/String;)V",
        jProductId.object<jstring>()
    );
#else
    // Desktop fallback - simulate successful payment for testing
    qDebug() << "PaymentManager: Desktop mode - simulating payment success";
    QMetaObject::invokeMethod(this, [this]() {
        handlePaymentSuccess("test_token_" + QUuid::createUuid().toString(QUuid::Id128).left(16),
                             "test_order_" + QUuid::createUuid().toString(QUuid::Id128).left(16));
    }, Qt::QueuedConnection);
#endif
}

void PaymentManager::handlePaymentSuccess(const QString &purchaseToken, const QString &orderId)
{
    qDebug() << "PaymentManager: Processing successful payment";

    m_isProcessing = false;
    emit processingChanged();

    // Apply purchase to subscription
    SubscriptionManager::instance()->applyPurchase(m_currentPlan, orderId, purchaseToken);

    emit paymentSuccess(purchaseToken, orderId, m_currentPlan);
    emit purchaseComplete();
}

void PaymentManager::handlePaymentFailed(const QString &errorCode, const QString &errorDesc)
{
    m_isProcessing = false;
    emit processingChanged();

    emit paymentFailed(errorCode, errorDesc);
}
