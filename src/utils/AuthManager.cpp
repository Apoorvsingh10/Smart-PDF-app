#include "AuthManager.h"
#include <QTimer>
#include <QDebug>

#ifdef Q_OS_ANDROID
#include <QJniObject>
#include <QJniEnvironment>
#include <QCoreApplication>
#endif

AuthManager* AuthManager::s_instance = nullptr;

#ifdef Q_OS_ANDROID
// JNI callback functions - called from Java
static void onAuthSuccessCallback(JNIEnv *env, jobject /*thiz*/, jstring jUserId, jstring jUserName, jstring jUserEmail, jstring jPhotoUrl)
{
    QString userId = QJniObject(jUserId).toString();
    QString userName = QJniObject(jUserName).toString();
    QString userEmail = QJniObject(jUserEmail).toString();
    QString photoUrl = QJniObject(jPhotoUrl).toString();

    qDebug() << "AuthManager: Auth success -" << userName << userEmail;

    QMetaObject::invokeMethod(AuthManager::instance(), [=]() {
        AuthManager::instance()->handleAuthSuccess(userId, userName, userEmail, photoUrl);
    }, Qt::QueuedConnection);
}

static void onAuthErrorCallback(JNIEnv *env, jobject /*thiz*/, jstring jErrorMessage)
{
    QString errorMessage = QJniObject(jErrorMessage).toString();
    qDebug() << "AuthManager: Auth error -" << errorMessage;

    QMetaObject::invokeMethod(AuthManager::instance(), [=]() {
        AuthManager::instance()->handleAuthError(errorMessage);
    }, Qt::QueuedConnection);
}

static void onIdTokenCallback(JNIEnv *env, jobject /*thiz*/, jstring jIdToken)
{
    QString idToken = QJniObject(jIdToken).toString();
    qDebug() << "AuthManager: ID token received, length:" << idToken.length();

    QMetaObject::invokeMethod(AuthManager::instance(), [=]() {
        AuthManager::instance()->handleIdToken(idToken);
    }, Qt::QueuedConnection);
}

// Register native methods with Java
static bool registerNativeMethods()
{
    JNINativeMethod methods[] = {
        {"onAuthSuccess", "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V", reinterpret_cast<void *>(onAuthSuccessCallback)},
        {"onAuthError", "(Ljava/lang/String;)V", reinterpret_cast<void *>(onAuthErrorCallback)},
        {"onIdToken", "(Ljava/lang/String;)V", reinterpret_cast<void *>(onIdTokenCallback)}
    };

    QJniEnvironment env;
    jclass clazz = env.findClass("io/smartpdf/app/FBAuth");
    if (clazz == nullptr) {
        qWarning() << "AuthManager: Could not find FBAuth class";
        return false;
    }

    if (env->RegisterNatives(clazz, methods, sizeof(methods) / sizeof(methods[0])) < 0) {
        qWarning() << "AuthManager: Failed to register native methods";
        return false;
    }

    qDebug() << "AuthManager: Native methods registered successfully";
    return true;
}
#endif

AuthManager::AuthManager(QObject *parent)
    : QObject(parent)
    , m_isAuthenticated(false)
    , m_userId("")
    , m_userName("")
    , m_userEmail("")
    , m_userPhotoUrl("")
    , m_idToken("")
{
    // JNI initialization moved to initializeNative() to avoid re-entrancy issues
}

AuthManager* AuthManager::instance()
{
    static bool s_initialized = false;
    if (!s_instance) {
        s_instance = new AuthManager();
        // Initialize JNI AFTER s_instance is set to prevent re-entrancy loop
        if (!s_initialized) {
            s_initialized = true;
#ifdef Q_OS_ANDROID
            // Register JNI callbacks first
            registerNativeMethods();

            // Tell Java that native is now ready to receive callbacks
            QJniObject::callStaticMethod<void>(
                "io/smartpdf/app/FBAuth",
                "setNativeReady",
                "()V"
            );
            qDebug() << "AuthManager: Native ready signal sent";
#endif
        }
    }
    return s_instance;
}

AuthManager* AuthManager::create(QQmlEngine *qmlEngine, QJSEngine *jsEngine)
{
    Q_UNUSED(jsEngine)
    AuthManager *inst = instance();
    QJSEngine::setObjectOwnership(inst, QJSEngine::CppOwnership);
    if (qmlEngine) {
        qmlEngine->setObjectOwnership(inst, QQmlEngine::CppOwnership);
    }
    return inst;
}

bool AuthManager::isAuthenticated() const
{
    return m_isAuthenticated;
}

QString AuthManager::userId() const
{
    return m_userId;
}

QString AuthManager::userName() const
{
    return m_userName;
}

QString AuthManager::userEmail() const
{
    return m_userEmail;
}

QString AuthManager::userPhotoUrl() const
{
    return m_userPhotoUrl;
}

QString AuthManager::idToken() const
{
    return m_idToken;
}

void AuthManager::refreshIdToken()
{
    // Prevent duplicate refresh requests
    if (m_tokenRefreshInProgress) {
        return; // Silent skip - this is expected behavior
    }
    m_tokenRefreshInProgress = true;
    qDebug() << "AuthManager: Requesting ID token refresh...";

#ifdef Q_OS_ANDROID
    QJniObject::callStaticMethod<void>(
        "io/smartpdf/app/FBAuth",
        "getIdToken",
        "()V"
    );

#else
    // Desktop fallback - emit dummy token
    handleIdToken("desktop_test_token");
#endif
}

void AuthManager::loginWithGoogle()
{
    qDebug() << "AuthManager: Starting Google Sign-In...";

#ifdef Q_OS_ANDROID
    QJniObject::callStaticMethod<void>(
        "io/smartpdf/app/FBAuth",
        "signInWithGoogle",
        "()V"
    );
#else
    // Desktop fallback - simulate for testing
    QTimer::singleShot(1000, this, [this]() {
        handleAuthSuccess("desktop_user", "Desktop User", "test@example.com", "");
    });
#endif
}



void AuthManager::loginAnonymously()
{
    qDebug() << "AuthManager: Starting Guest Sign-In...";

#ifdef Q_OS_ANDROID
    QJniObject::callStaticMethod<void>(
        "io/smartpdf/app/FBAuth",
        "signInAnonymously",
        "()V"
    );
#else
    // Desktop fallback
    QTimer::singleShot(500, this, [this]() {
        handleAuthSuccess("guest", "Guest User", "", "");
    });
#endif
}

void AuthManager::signOut()
{
    qDebug() << "AuthManager: Signing out...";

#ifdef Q_OS_ANDROID
    QJniObject::callStaticMethod<void>(
        "io/smartpdf/app/FBAuth",
        "signOut",
        "()V"
    );
#endif

    m_isAuthenticated = false;
    m_userId = "";
    m_userName = "";
    m_userEmail = "";
    m_userPhotoUrl = "";
    m_idToken = "";

    emit userChanged();
    emit idTokenChanged();
    emit authSuccess("Signed out");
}

void AuthManager::handleAuthSuccess(const QString &userId, const QString &userName, const QString &userEmail, const QString &photoUrl)
{
    m_isAuthenticated = true;
    m_userId = userId;
    m_userName = userName;
    m_userEmail = userEmail;
    m_userPhotoUrl = photoUrl;

    emit userChanged();
    emit authSuccess("Signed in as " + userName);

    // Fetch ID token for API calls
    refreshIdToken();
}

void AuthManager::handleAuthError(const QString &errorMessage)
{
    emit authError(errorMessage);
}

void AuthManager::handleIdToken(const QString &token)
{
    qDebug() << "AuthManager: ID token received, length:" << token.length();
    m_tokenRefreshInProgress = false;
    m_idToken = token;
    emit idTokenChanged();
}
