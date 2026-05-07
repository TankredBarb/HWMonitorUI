#ifndef SENSORNAMEMANAGER_H
#define SENSORNAMEMANAGER_H

#include <QObject>
#include <QString>
#include <QMap>
#include <QJsonDocument>
#include <QJsonObject>
#include <QFile>
#include <QDir>
#include <QCoreApplication>

class SensorNameManager : public QObject
{
    Q_OBJECT
public:
    explicit SensorNameManager(QObject *parent = nullptr);

    Q_INVOKABLE QString getDisplayName(const QString &sensorId, const QString &defaultName);
    Q_INVOKABLE void saveSensorName(const QString &sensorId, const QString &customName);
    void loadNames();

private:
    QString getConfigPath() const;
    void saveToFile();

    QMap<QString, QString> m_customNames;
};

#endif // SENSORNAMEMANAGER_H