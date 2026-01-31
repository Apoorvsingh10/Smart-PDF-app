#ifndef SHAREUTILS_H
#define SHAREUTILS_H

#include <QObject>
#include <QString>
#include <QtQml>

class ShareUtils : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    static ShareUtils* instance();
    static ShareUtils* create(QQmlEngine *qmlEngine, QJSEngine *jsEngine);

    Q_INVOKABLE void shareFile(const QString &filePath, const QString &mimeType = "application/pdf");
    Q_INVOKABLE void shareText(const QString &text);

private:
    explicit ShareUtils(QObject *parent = nullptr);
    static ShareUtils *s_instance;
};

#endif // SHAREUTILS_H
