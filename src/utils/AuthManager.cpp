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

// Register native methods with Java
static bool registerNativeMethods()
{
    JNINativeMethod methods[] = {
        {"onAuthSuccess", "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V", reinterpret_cast<void *>(onAuthSuccessCallback)},
        {"onAuthError", "(Ljava/lang/String;)V", reinterpret_cast<void *>(onAuthErrorCallback)}
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
    , m_userName("")
    , m_userEmail("")
    , m_userPhotoUrl("")
{
#ifdef Q_OS_ANDROID
    // Register JNI callbacks
    registerNativeMethods();

    // Initialize Firebase Auth Helper
    QJniObject activity = QJniObject::callStaticObjectMethod(
        "org/qtproject/qt/android/QtNative",
        "activity",
        "()Landroid/app/Activity;"
    );

    if (activity.isValid()) {
        QJniObject::callStaticMethod<void>(
            "io/smartpdf/app/FBAuth",
            "initialize",
            "(Landroid/app/Activity;)V",
            activity.object()
        );
        qDebug() << "AuthManager: Firebase initialized";
    } else {
        qWarning() << "AuthManager: Could not get activity for Firebase initialization";
    }
#endif
}

AuthManager* AuthManager::instance()
{
    if (!s_instance) {
        s_instance = new AuthManager();
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
    m_userName = "";
    m_userEmail = "";
    m_userPhotoUrl = "";

    emit userChanged();
    emit authSuccess("Signed out");
}

void AuthManager::handleAuthSuccess(const QString &userId, const QString &userName, const QString &userEmail, const QString &photoUrl)
{
    Q_UNUSED(userId)
    m_isAuthenticated = true;
    m_userName = userName;
    m_userEmail = userEmail;
    m_userPhotoUrl = photoUrl;

    emit userChanged();
    emit authSuccess("Signed in as " + userName);
}

void AuthManager::handleAuthError(const QString &errorMessage)
{
    emit authError(errorMessage);
}
