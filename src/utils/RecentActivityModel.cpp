#include "RecentActivityModel.h"
#include <QSettings>
#include <QDebug>

RecentActivityModel *RecentActivityModel::s_instance = nullptr;

RecentActivityModel::RecentActivityModel(QObject *parent)
    : QAbstractListModel(parent)
{
    s_instance = this;
    loadActivities();
}

RecentActivityModel *RecentActivityModel::create(QQmlEngine *qmlEngine, QJSEngine *jsEngine)
{
    Q_UNUSED(qmlEngine)
    Q_UNUSED(jsEngine)
    
    if (!s_instance) {
        s_instance = new RecentActivityModel();
    }
    return s_instance;
}

RecentActivityModel *RecentActivityModel::instance()
{
    if (!s_instance) {
        s_instance = new RecentActivityModel();
    }
    return s_instance;
}

int RecentActivityModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) {
        return 0;
    }
    return m_activities.count();
}

QVariant RecentActivityModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_activities.count()) {
        return QVariant();
    }

    const RecentActivity &activity = m_activities.at(index.row());

    switch (role) {
    case FileNameRole:
        return activity.fileName;
    case ActionRole:
        return activity.action;
    case FilePathRole:
        return activity.filePath;
    case TimestampRole:
        return formatTimestamp(activity.timestamp);
    default:
        return QVariant();
    }
}

QHash<int, QByteArray> RecentActivityModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[FileNameRole] = "fileName";
    roles[ActionRole] = "action";
    roles[FilePathRole] = "filePath";
    roles[TimestampRole] = "timestamp";
    return roles;
}

int RecentActivityModel::count() const
{
    return m_activities.count();
}

void RecentActivityModel::addActivity(const QString &fileName, const QString &action, const QString &filePath)
{
    // Only track saved files (merged, split, compressed), ignore 'viewed'
    if (action == "viewed") {
        return;
    }

    RecentActivity activity;
    activity.fileName = fileName;
    activity.action = action;
    activity.filePath = filePath;
    activity.timestamp = QDateTime::currentDateTime();

    // Remove duplicate if exists (same file, same action)
    for (int i = 0; i < m_activities.count(); ++i) {
        if (m_activities[i].filePath == filePath && m_activities[i].action == action) {
            beginRemoveRows(QModelIndex(), i, i);
            m_activities.removeAt(i);
            endRemoveRows();
            break;
        }
    }

    // Add to beginning
    beginInsertRows(QModelIndex(), 0, 0);
    m_activities.prepend(activity);
    endInsertRows();

    // Limit to MAX_ACTIVITIES
    while (m_activities.count() > MAX_ACTIVITIES) {
        beginRemoveRows(QModelIndex(), m_activities.count() - 1, m_activities.count() - 1);
        m_activities.removeLast();
        endRemoveRows();
    }

    saveActivities();
    emit countChanged();

    qDebug() << "RecentActivityModel: Added activity -" << action << fileName;
}

void RecentActivityModel::clearAll()
{
    beginResetModel();
    m_activities.clear();
    endResetModel();
    
    saveActivities();
    emit countChanged();
}

void RecentActivityModel::removeActivity(int index)
{
    if (index < 0 || index >= m_activities.count()) {
        return;
    }

    beginRemoveRows(QModelIndex(), index, index);
    m_activities.removeAt(index);
    endRemoveRows();

    saveActivities();
    emit countChanged();
}

void RecentActivityModel::loadActivities()
{
    QSettings settings;
    int size = settings.beginReadArray("recentActivities");
    
    for (int i = 0; i < size && i < MAX_ACTIVITIES; ++i) {
        settings.setArrayIndex(i);
        
        RecentActivity activity;
        activity.fileName = settings.value("fileName").toString();
        activity.action = settings.value("action").toString();
        activity.filePath = settings.value("filePath").toString();
        activity.timestamp = settings.value("timestamp").toDateTime();
        
        if (!activity.fileName.isEmpty() && activity.action != "viewed") {
            m_activities.append(activity);
        }
    }
    
    settings.endArray();
    
    qDebug() << "RecentActivityModel: Loaded" << m_activities.count() << "activities";
}

void RecentActivityModel::saveActivities()
{
    QSettings settings;
    settings.beginWriteArray("recentActivities");
    
    for (int i = 0; i < m_activities.count(); ++i) {
        settings.setArrayIndex(i);
        settings.setValue("fileName", m_activities[i].fileName);
        settings.setValue("action", m_activities[i].action);
        settings.setValue("filePath", m_activities[i].filePath);
        settings.setValue("timestamp", m_activities[i].timestamp);
    }
    
    settings.endArray();
}

QString RecentActivityModel::formatTimestamp(const QDateTime &dt) const
{
    QDateTime now = QDateTime::currentDateTime();
    qint64 secs = dt.secsTo(now);
    
    if (secs < 60) {
        return tr("Just now");
    } else if (secs < 3600) {
        int mins = secs / 60;
        return tr("%1 min ago").arg(mins);
    } else if (secs < 86400) {
        int hours = secs / 3600;
        return tr("%1 hour ago").arg(hours);
    } else if (secs < 604800) {
        int days = secs / 86400;
        return tr("%1 day ago").arg(days);
    } else {
        return dt.toString("MMM d");
    }
}
