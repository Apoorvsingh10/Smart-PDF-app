#ifndef FILEUTILS_H
#define FILEUTILS_H

#include <QObject>
#include <QString>
#include <QUrl>
#include <QtQml>

class FileUtils : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    static FileUtils* instance();
    static FileUtils* create(QQmlEngine *qmlEngine, QJSEngine *jsEngine);

    Q_INVOKABLE QString getFileName(const QUrl &url) const;
    Q_INVOKABLE QString getFilePath(const QUrl &url) const;
    Q_INVOKABLE QString formatFileSize(qint64 bytes) const;
    Q_INVOKABLE bool fileExists(const QUrl &url) const;
    Q_INVOKABLE QString getDocumentsPath() const;
    Q_INVOKABLE QString getTempPath() const;
    Q_INVOKABLE QString generateOutputPath(const QString &inputPath, const QString &suffix) const;
    Q_INVOKABLE bool copyFile(const QUrl &source, const QUrl &destination) const;

private:
    explicit FileUtils(QObject *parent = nullptr);
    static FileUtils *s_instance;
};

#endif // FILEUTILS_H
