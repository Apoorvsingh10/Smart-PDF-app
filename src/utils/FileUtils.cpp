#include "FileUtils.h"
#include <QFileInfo>
#include <QFile>
#include <QStandardPaths>
#include <QDir>
#include <QQmlEngine>

FileUtils* FileUtils::s_instance = nullptr;

FileUtils::FileUtils(QObject *parent) : QObject(parent)
{
}

FileUtils* FileUtils::instance()
{
    if (!s_instance) {
        s_instance = new FileUtils();
    }
    return s_instance;
}

FileUtils* FileUtils::create(QQmlEngine *qmlEngine, QJSEngine *jsEngine)
{
    Q_UNUSED(jsEngine)
    FileUtils *inst = instance();
    QJSEngine::setObjectOwnership(inst, QJSEngine::CppOwnership);
    if (qmlEngine) {
        qmlEngine->setObjectOwnership(inst, QQmlEngine::CppOwnership);
    }
    return inst;
}

QString FileUtils::getFileName(const QUrl &url) const
{
    QString path = url.toLocalFile();
    if (path.isEmpty()) {
        path = url.toString();
    }
    return QFileInfo(path).fileName();
}

QString FileUtils::getFilePath(const QUrl &url) const
{
    return url.toLocalFile();
}

QString FileUtils::formatFileSize(qint64 bytes) const
{
    if (bytes < 1024) {
        return QString("%1 B").arg(bytes);
    } else if (bytes < 1024 * 1024) {
        return QString("%1 KB").arg(bytes / 1024.0, 0, 'f', 1);
    } else if (bytes < 1024 * 1024 * 1024) {
        return QString("%1 MB").arg(bytes / (1024.0 * 1024.0), 0, 'f', 1);
    } else {
        return QString("%1 GB").arg(bytes / (1024.0 * 1024.0 * 1024.0), 0, 'f', 1);
    }
}

bool FileUtils::fileExists(const QUrl &url) const
{
    return QFile::exists(url.toLocalFile());
}

QString FileUtils::getDocumentsPath() const
{
    return QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation);
}

QString FileUtils::getTempPath() const
{
    return QStandardPaths::writableLocation(QStandardPaths::TempLocation);
}

QString FileUtils::generateOutputPath(const QString &inputPath, const QString &suffix) const
{
    QFileInfo info(inputPath);
    QString baseName = info.completeBaseName();
    QString dir = info.absolutePath();
    return QDir(dir).filePath(baseName + suffix + ".pdf");
}

bool FileUtils::copyFile(const QUrl &source, const QUrl &destination) const
{
    qDebug() << "FileUtils::copyFile - Source:" << source << "Destination:" << destination;

    // Determine source path
    QString srcPath = source.toLocalFile();
    if (srcPath.isEmpty()) {
        // Handle file:// URLs that toLocalFile might not parse
        QString srcStr = source.toString();
        if (srcStr.startsWith("file:///")) {
            srcPath = srcStr.mid(7); // Keep one slash for absolute path
        } else if (srcStr.startsWith("file://")) {
            srcPath = srcStr.mid(7);
        } else {
            srcPath = srcStr;
        }
    }

    qDebug() << "FileUtils::copyFile - Resolved source path:" << srcPath;

    // Open source file
    QFile srcFile(srcPath);
    if (!srcFile.open(QIODevice::ReadOnly)) {
        qDebug() << "FileUtils::copyFile - Failed to open source:" << srcFile.errorString();
        return false;
    }

    // For destination, handle both file:// and content:// URIs
    // Qt 6 on Android can open content:// URIs directly with QFile
    QString destPath;
    bool useContentUri = false;

    if (destination.scheme() == "content") {
        // Android content:// URI - use the full URL string
        destPath = destination.toString();
        useContentUri = true;
        qDebug() << "FileUtils::copyFile - Using content URI for destination";
    } else {
        destPath = destination.toLocalFile();
        if (destPath.isEmpty()) {
            QString destStr = destination.toString();
            if (destStr.startsWith("file:///")) {
                destPath = destStr.mid(7);
            } else if (destStr.startsWith("file://")) {
                destPath = destStr.mid(7);
            } else {
                destPath = destStr;
            }
        }
    }

    qDebug() << "FileUtils::copyFile - Resolved dest path:" << destPath << "useContentUri:" << useContentUri;

    // For regular file paths, remove existing file first
    if (!useContentUri && QFile::exists(destPath)) {
        QFile::remove(destPath);
    }

    // Open destination file
    QFile destFile(destPath);
    if (!destFile.open(QIODevice::WriteOnly)) {
        qDebug() << "FileUtils::copyFile - Failed to open destination:" << destFile.errorString();
        srcFile.close();
        return false;
    }

    // Copy data in chunks
    const qint64 bufferSize = 64 * 1024; // 64KB chunks
    QByteArray buffer;
    qint64 totalWritten = 0;

    while (!srcFile.atEnd()) {
        buffer = srcFile.read(bufferSize);
        qint64 written = destFile.write(buffer);
        if (written < 0) {
            qDebug() << "FileUtils::copyFile - Write error:" << destFile.errorString();
            srcFile.close();
            destFile.close();
            return false;
        }
        totalWritten += written;
    }

    srcFile.close();
    destFile.close();

    qDebug() << "FileUtils::copyFile - Success! Copied" << totalWritten << "bytes";
    return true;
}
