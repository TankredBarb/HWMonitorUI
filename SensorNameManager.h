#pragma once

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
    struct SensorConfig
    {
        QString customName;
        QString color = "#1A1A1A";
        bool isBold = false;
    };

    explicit SensorNameManager(QObject *parent = nullptr);

    Q_INVOKABLE QString getDisplayName(const QString &sensorId, const QString &defaultName);
    Q_INVOKABLE QString getSensorColor(const QString &sensorId, const QString &defaultColor = "#1A1A1A");
    Q_INVOKABLE bool getSensorBold(const QString &sensorId);
    
    Q_INVOKABLE void saveSensorConfig(const QString &sensorId, const QString &customName, const QString &color, bool isBold);
    
    // Legacy support or internal
    void saveSensorName(const QString &sensorId, const QString &customName);
    
    void loadNames();

signals:
    void namesChanged();

private:
    QString getConfigPath() const;
    bool saveToFile();
    bool loadFromFile();

    QMap<QString, SensorConfig> m_configs;
};

