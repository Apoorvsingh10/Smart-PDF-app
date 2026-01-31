#include "ShareUtils.h"
#include <QDebug>
#include <QUrl>
#include <QFile>
#include <QFileInfo>

#ifdef Q_OS_ANDROID
#include <QJniObject>
#include <QJniEnvironment>
#include <QCoreApplication>
#endif

ShareUtils* ShareUtils::s_instance = nullptr;

ShareUtils::ShareUtils(QObject *parent) : QObject(parent)
{
}

ShareUtils* ShareUtils::instance()
{
    if (!s_instance) {
        s_instance = new ShareUtils();
    }
    return s_instance;
}

ShareUtils* ShareUtils::create(QQmlEngine *qmlEngine, QJSEngine *jsEngine)
{
    Q_UNUSED(jsEngine)
    ShareUtils *inst = instance();
    QJSEngine::setObjectOwnership(inst, QJSEngine::CppOwnership);
    if (qmlEngine) {
        qmlEngine->setObjectOwnership(inst, QQmlEngine::CppOwnership);
    }
    return inst;
}

void ShareUtils::shareFile(const QString &filePath, const QString &mimeType)
{
    qDebug() << "ShareUtils::shareFile - Path:" << filePath << "MimeType:" << mimeType;

    if (filePath.isEmpty()) {
        qDebug() << "ShareUtils::shareFile - Empty file path";
        return;
    }

#ifdef Q_OS_ANDROID
    QJniObject jMimeType = QJniObject::fromString(mimeType);

    QJniObject activity = QJniObject::callStaticObjectMethod(
        "org/qtproject/qt/android/QtNative",
        "activity",
        "()Landroid/app/Activity;"
    );

    if (!activity.isValid()) {
        qDebug() << "ShareUtils::shareFile - Could not get activity";
        return;
    }

    QJniObject context = activity.callObjectMethod(
        "getApplicationContext",
        "()Landroid/content/Context;"
    );

    QJniObject uri;

    // Check if it's already a content:// URI
    if (filePath.startsWith("content://")) {
        qDebug() << "ShareUtils::shareFile - Using content URI directly";
        uri = QJniObject::callStaticObjectMethod(
            "android/net/Uri",
            "parse",
            "(Ljava/lang/String;)Landroid/net/Uri;",
            QJniObject::fromString(filePath).object<jstring>()
        );
    } else {
        // It's a file path - convert to local path and use FileProvider
        QString localPath = filePath;
        if (localPath.startsWith("file:///")) {
            localPath = localPath.mid(8);  // Remove file:/// (8 chars on Windows-style paths)
        } else if (localPath.startsWith("file://")) {
            localPath = localPath.mid(7);
        }

        // On Android, paths typically start with /
        if (!localPath.startsWith("/") && localPath.length() > 1 && localPath[1] == ':') {
            // Windows-style path, skip
        }

        qDebug() << "ShareUtils::shareFile - Local path:" << localPath;

        if (!QFile::exists(localPath)) {
            qDebug() << "ShareUtils::shareFile - File does not exist:" << localPath;
            return;
        }

        QJniObject jFilePath = QJniObject::fromString(localPath);
        QJniObject jFile = QJniObject("java/io/File", "(Ljava/lang/String;)V", jFilePath.object<jstring>());

        // Get package name for FileProvider authority
        QJniObject packageName = context.callObjectMethod<jstring>("getPackageName");
        QString authority = packageName.toString() + ".fileprovider";
        QJniObject jAuthority = QJniObject::fromString(authority);

        // Get content URI from FileProvider
        uri = QJniObject::callStaticObjectMethod(
            "androidx/core/content/FileProvider",
            "getUriForFile",
            "(Landroid/content/Context;Ljava/lang/String;Ljava/io/File;)Landroid/net/Uri;",
            context.object(),
            jAuthority.object<jstring>(),
            jFile.object()
        );

        if (!uri.isValid()) {
            qDebug() << "ShareUtils::shareFile - Could not get URI from FileProvider, trying direct file URI";
            // Last resort fallback - may not work on Android 7.0+
            uri = QJniObject::callStaticObjectMethod(
                "android/net/Uri",
                "parse",
                "(Ljava/lang/String;)Landroid/net/Uri;",
                QJniObject::fromString("file://" + localPath).object<jstring>()
            );
        }
    }

    if (!uri.isValid()) {
        qDebug() << "ShareUtils::shareFile - Failed to create URI";
        return;
    }

    // Create share intent
    QJniObject intent("android/content/Intent");
    QJniObject actionSend = QJniObject::getStaticObjectField<jstring>(
        "android/content/Intent",
        "ACTION_SEND"
    );

    intent.callObjectMethod(
        "setAction",
        "(Ljava/lang/String;)Landroid/content/Intent;",
        actionSend.object<jstring>()
    );

    intent.callObjectMethod(
        "setType",
        "(Ljava/lang/String;)Landroid/content/Intent;",
        jMimeType.object<jstring>()
    );

    QJniObject extraStream = QJniObject::getStaticObjectField<jstring>(
        "android/content/Intent",
        "EXTRA_STREAM"
    );

    intent.callObjectMethod(
        "putExtra",
        "(Ljava/lang/String;Landroid/os/Parcelable;)Landroid/content/Intent;",
        extraStream.object<jstring>(),
        uri.object()
    );

    // Add FLAG_GRANT_READ_URI_PERMISSION
    jint readPermission = QJniObject::getStaticField<jint>(
        "android/content/Intent",
        "FLAG_GRANT_READ_URI_PERMISSION"
    );
    intent.callObjectMethod(
        "addFlags",
        "(I)Landroid/content/Intent;",
        readPermission
    );

    // Create chooser
    QJniObject chooserTitle = QJniObject::fromString("Share PDF");
    QJniObject chooser = QJniObject::callStaticObjectMethod(
        "android/content/Intent",
        "createChooser",
        "(Landroid/content/Intent;Ljava/lang/CharSequence;)Landroid/content/Intent;",
        intent.object(),
        chooserTitle.object<jstring>()
    );

    // Start activity
    activity.callMethod<void>(
        "startActivity",
        "(Landroid/content/Intent;)V",
        chooser.object()
    );

    qDebug() << "ShareUtils::shareFile - Share intent launched";
#else
    qDebug() << "ShareUtils::shareFile - Sharing not supported on this platform";
#endif
}

void ShareUtils::shareText(const QString &text)
{
    qDebug() << "ShareUtils::shareText - Text:" << text;

#ifdef Q_OS_ANDROID
    QJniObject jText = QJniObject::fromString(text);

    QJniObject activity = QJniObject::callStaticObjectMethod(
        "org/qtproject/qt/android/QtNative",
        "activity",
        "()Landroid/app/Activity;"
    );

    if (!activity.isValid()) {
        qDebug() << "ShareUtils::shareText - Could not get activity";
        return;
    }

    QJniObject intent("android/content/Intent");
    QJniObject actionSend = QJniObject::getStaticObjectField<jstring>(
        "android/content/Intent",
        "ACTION_SEND"
    );

    intent.callObjectMethod(
        "setAction",
        "(Ljava/lang/String;)Landroid/content/Intent;",
        actionSend.object<jstring>()
    );

    intent.callObjectMethod(
        "setType",
        "(Ljava/lang/String;)Landroid/content/Intent;",
        QJniObject::fromString("text/plain").object<jstring>()
    );

    QJniObject extraText = QJniObject::getStaticObjectField<jstring>(
        "android/content/Intent",
        "EXTRA_TEXT"
    );

    intent.callObjectMethod(
        "putExtra",
        "(Ljava/lang/String;Ljava/lang/String;)Landroid/content/Intent;",
        extraText.object<jstring>(),
        jText.object<jstring>()
    );

    QJniObject chooserTitle = QJniObject::fromString("Share");
    QJniObject chooser = QJniObject::callStaticObjectMethod(
        "android/content/Intent",
        "createChooser",
        "(Landroid/content/Intent;Ljava/lang/CharSequence;)Landroid/content/Intent;",
        intent.object(),
        chooserTitle.object<jstring>()
    );

    activity.callMethod<void>(
        "startActivity",
        "(Landroid/content/Intent;)V",
        chooser.object()
    );
#else
    qDebug() << "ShareUtils::shareText - Sharing not supported on this platform";
#endif
}
