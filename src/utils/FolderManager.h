#ifndef FOLDERMANAGER_H
#define FOLDERMANAGER_H

#include <QObject>
#include <QStringList>
#include <QDir>
#include <QStandardPaths>
#include <QQmlEngine>

class FolderManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(QStringList folders READ folders NOTIFY foldersChanged)

public:
    explicit FolderManager(QObject *parent = nullptr);

    static FolderManager *create(QQmlEngine *qmlEngine, QJSEngine *jsEngine);
    static FolderManager *instance();

    QStringList folders() const;

    Q_INVOKABLE bool createFolder(const QString &folderName);
    Q_INVOKABLE bool deleteFolder(const QString &folderName);
    Q_INVOKABLE bool renameFolder(const QString &oldName, const QString &newName);
    Q_INVOKABLE int getFileCount(const QString &folderName) const;
    Q_INVOKABLE QStringList getFilesInFolder(const QString &folderName) const;
    Q_INVOKABLE bool moveFileToFolder(const QString &filePath, const QString &folderName);
    Q_INVOKABLE QString getFolderPath(const QString &folderName) const;

signals:
    void foldersChanged();
    void folderCreated(const QString &folderName);
    void folderDeleted(const QString &folderName);

private:
    void ensureDefaultFolder();
    void loadFolders();
    QString basePath() const;

    static FolderManager *s_instance;
    QStringList m_folders;
};

#endif // FOLDERMANAGER_H
