#ifndef RECENTACTIVITYMODEL_H
#define RECENTACTIVITYMODEL_H

#include <QAbstractListModel>
#include <QDateTime>
#include <QQmlEngine>

struct RecentActivity {
    QString fileName;
    QString action;      // "merged", "split", "compressed", "viewed"
    QString filePath;
    QDateTime timestamp;
};

class RecentActivityModel : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(int count READ count NOTIFY countChanged)

public:
    enum Roles {
        FileNameRole = Qt::UserRole + 1,
        ActionRole,
        FilePathRole,
        TimestampRole
    };

    explicit RecentActivityModel(QObject *parent = nullptr);

    static RecentActivityModel *create(QQmlEngine *qmlEngine, QJSEngine *jsEngine);
    static RecentActivityModel *instance();

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    int count() const;

    Q_INVOKABLE void addActivity(const QString &fileName, const QString &action, const QString &filePath);
    Q_INVOKABLE void clearAll();
    Q_INVOKABLE void removeActivity(int index);

signals:
    void countChanged();

private:
    void loadActivities();
    void saveActivities();
    QString formatTimestamp(const QDateTime &dt) const;

    static RecentActivityModel *s_instance;
    QList<RecentActivity> m_activities;
    static const int MAX_ACTIVITIES = 20;
};

#endif // RECENTACTIVITYMODEL_H
