#include "FolderManager.h"
#include <QSettings>
#include <QFileInfo>
#include <QDebug>
#include <QRegularExpression>

FolderManager *FolderManager::s_instance = nullptr;

FolderManager::FolderManager(QObject *parent)
    : QObject(parent)
{
    s_instance = this;
    ensureDefaultFolder();
    loadFolders();
}

FolderManager *FolderManager::create(QQmlEngine *qmlEngine, QJSEngine *jsEngine)
{
    Q_UNUSED(qmlEngine)
    Q_UNUSED(jsEngine)
    
    if (!s_instance) {
        s_instance = new FolderManager();
    }
    return s_instance;
}

FolderManager *FolderManager::instance()
{
    if (!s_instance) {
        s_instance = new FolderManager();
    }
    return s_instance;
}

QString FolderManager::basePath() const
{
    return QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation) + "/PDF_ToolKit";
}

void FolderManager::ensureDefaultFolder()
{
    QDir dir(basePath());
    if (!dir.exists()) {
        dir.mkpath(".");
    }
    
    // Create default "Documents" folder
    QString defaultFolder = basePath() + "/Documents";
    QDir defaultDir(defaultFolder);
    if (!defaultDir.exists()) {
        defaultDir.mkpath(".");
        qDebug() << "FolderManager: Created default Documents folder at" << defaultFolder;
    }
}

void FolderManager::loadFolders()
{
    m_folders.clear();
    
    QDir baseDir(basePath());
    QStringList dirs = baseDir.entryList(QDir::Dirs | QDir::NoDotAndDotDot, QDir::Name);
    
    // Ensure Documents is always first
    if (dirs.contains("Documents")) {
        dirs.removeAll("Documents");
        m_folders.append("Documents");
    }
    
    m_folders.append(dirs);
    emit foldersChanged();
}

QStringList FolderManager::folders() const
{
    return m_folders;
}

bool FolderManager::createFolder(const QString &folderName)
{
    if (folderName.isEmpty()) {
        return false;
    }
    
    QString sanitized = folderName.trimmed();
    sanitized.replace(QRegularExpression("[<>:\"/\\\\|?*]"), "_");
    
    QString folderPath = basePath() + "/" + sanitized;
    QDir dir(folderPath);
    
    if (dir.exists()) {
        qDebug() << "FolderManager: Folder already exists:" << sanitized;
        return false;
    }
    
    if (dir.mkpath(".")) {
        qDebug() << "FolderManager: Created folder:" << sanitized;
        loadFolders();
        emit folderCreated(sanitized);
        return true;
    }
    
    return false;
}

bool FolderManager::deleteFolder(const QString &folderName)
{
    if (folderName == "Documents") {
        qDebug() << "FolderManager: Cannot delete default Documents folder";
        return false;
    }
    
    QString folderPath = basePath() + "/" + folderName;
    QDir dir(folderPath);
    
    if (!dir.exists()) {
        return false;
    }
    
    if (dir.removeRecursively()) {
        qDebug() << "FolderManager: Deleted folder:" << folderName;
        loadFolders();
        emit folderDeleted(folderName);
        return true;
    }
    
    return false;
}

bool FolderManager::renameFolder(const QString &oldName, const QString &newName)
{
    if (oldName == "Documents") {
        qDebug() << "FolderManager: Cannot rename default Documents folder";
        return false;
    }
    
    QString oldPath = basePath() + "/" + oldName;
    QString sanitized = newName.trimmed();
    sanitized.replace(QRegularExpression("[<>:\"/\\\\|?*]"), "_");
    QString newPath = basePath() + "/" + sanitized;
    
    QDir dir;
    if (dir.rename(oldPath, newPath)) {
        qDebug() << "FolderManager: Renamed folder from" << oldName << "to" << sanitized;
        loadFolders();
        return true;
    }
    
    return false;
}

int FolderManager::getFileCount(const QString &folderName) const
{
    QString folderPath = basePath() + "/" + folderName;
    QDir dir(folderPath);
    
    if (!dir.exists()) {
        return 0;
    }
    
    QStringList filters;
    filters << "*.pdf" << "*.PDF";
    return dir.entryList(filters, QDir::Files).count();
}

QStringList FolderManager::getFilesInFolder(const QString &folderName) const
{
    QStringList files;
    QString folderPath = basePath() + "/" + folderName;
    QDir dir(folderPath);
    
    if (!dir.exists()) {
        return files;
    }
    
    QStringList filters;
    filters << "*.pdf" << "*.PDF";
    QStringList entries = dir.entryList(filters, QDir::Files, QDir::Time);
    
    for (const QString &entry : entries) {
        files.append(folderPath + "/" + entry);
    }
    
    return files;
}

bool FolderManager::moveFileToFolder(const QString &filePath, const QString &folderName)
{
    QFileInfo fileInfo(filePath);
    if (!fileInfo.exists()) {
        return false;
    }
    
    QString destPath = basePath() + "/" + folderName + "/" + fileInfo.fileName();
    
    // Ensure destination folder exists
    QDir destDir(basePath() + "/" + folderName);
    if (!destDir.exists()) {
        destDir.mkpath(".");
    }
    
    if (QFile::copy(filePath, destPath)) {
        qDebug() << "FolderManager: Moved file to" << destPath;
        loadFolders(); // Refresh counts
        return true;
    }
    
    return false;
}

QString FolderManager::getFolderPath(const QString &folderName) const
{
    return basePath() + "/" + folderName;
}
