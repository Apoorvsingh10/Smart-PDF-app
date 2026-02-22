#ifndef FILERECEIVER_H
#define FILERECEIVER_H

#include <QObject>
#include <QtQml>

class FileReceiver : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(QString pendingFile READ pendingFile NOTIFY pendingFileChanged)

public:
    static FileReceiver* instance();
    static FileReceiver* create(QQmlEngine *qmlEngine, QJSEngine *jsEngine);

    QString pendingFile() const;

    Q_INVOKABLE void checkPendingFile();
    Q_INVOKABLE void clearPendingFile();

    // Called from JNI
    void handleFileReceived(const QString &fileUri);

signals:
    void pendingFileChanged();
    void fileReceived(const QString &fileUri);

private:
    explicit FileReceiver(QObject *parent = nullptr);
    static FileReceiver *s_instance;

    QString m_pendingFile;
};

#endif // FILERECEIVER_H
