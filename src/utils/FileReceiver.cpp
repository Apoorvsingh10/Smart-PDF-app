#include "FileReceiver.h"
#include <QDebug>

#ifdef Q_OS_ANDROID
#include <QJniObject>
#include <QJniEnvironment>
#include <QCoreApplication>
#endif

FileReceiver* FileReceiver::s_instance = nullptr;

FileReceiver::FileReceiver(QObject *parent)
    : QObject(parent)
{
}

FileReceiver* FileReceiver::instance()
{
    if (!s_instance) {
        s_instance = new FileReceiver();
    }
    return s_instance;
}

FileReceiver* FileReceiver::create(QQmlEngine *qmlEngine, QJSEngine *jsEngine)
{
    Q_UNUSED(jsEngine)
    FileReceiver *inst = instance();
    QJSEngine::setObjectOwnership(inst, QJSEngine::CppOwnership);
    if (qmlEngine) {
        qmlEngine->setObjectOwnership(inst, QQmlEngine::CppOwnership);
    }
    return inst;
}

QString FileReceiver::pendingFile() const
{
    return m_pendingFile;
}

void FileReceiver::checkPendingFile()
{
#ifdef Q_OS_ANDROID
    QJniObject result = QJniObject::callStaticMethod<jstring>(
        "io/smartpdf/app/SmartPdfActivity",
        "getPendingFileUri",
        "()Ljava/lang/String;"
    );

    if (result.isValid()) {
        QString uri = result.toString();
        if (!uri.isEmpty()) {
            qDebug() << "FileReceiver: Got pending file from Java:" << uri;
            handleFileReceived(uri);
        }
    }
#endif
}

void FileReceiver::clearPendingFile()
{
    m_pendingFile.clear();
    emit pendingFileChanged();
}

void FileReceiver::handleFileReceived(const QString &fileUri)
{
    qDebug() << "FileReceiver: File received:" << fileUri;
    m_pendingFile = fileUri;
    emit pendingFileChanged();
    emit fileReceived(fileUri);
}

#ifdef Q_OS_ANDROID
// JNI function called from Java
extern "C" JNIEXPORT void JNICALL
Java_io_smartpdf_app_SmartPdfActivity_onFileReceived(JNIEnv *env, jclass /*clazz*/, jstring fileUri)
{
    const char *uriStr = env->GetStringUTFChars(fileUri, nullptr);
    QString uri = QString::fromUtf8(uriStr);
    env->ReleaseStringUTFChars(fileUri, uriStr);

    qDebug() << "JNI: onFileReceived called with:" << uri;

    // Use queued connection to ensure we're on the main thread
    QMetaObject::invokeMethod(FileReceiver::instance(), "handleFileReceived",
                              Qt::QueuedConnection, Q_ARG(QString, uri));
}
#endif
