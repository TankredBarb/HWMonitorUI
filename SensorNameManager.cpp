#include "SensorNameManager.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QFile>
#include <QDir>
#include <QDebug>

SensorNameManager::SensorNameManager(QObject *parent) : QObject(parent)
{
    loadNames();
}

QString SensorNameManager::getDisplayName(const QString &sensorId, const QString &defaultName)
{
    if (m_configs.contains(sensorId))
    {
        return m_configs[sensorId].customName;
    }
    return defaultName;
}

QString SensorNameManager::getSensorColor(const QString &sensorId, const QString &defaultColor)
{
    if (m_configs.contains(sensorId))
    {
        return m_configs[sensorId].color;
    }
    return defaultColor;
}

bool SensorNameManager::getSensorBold(const QString &sensorId)
{
    if (m_configs.contains(sensorId))
    {
        return m_configs[sensorId].isBold;
    }
    return false;
}

void SensorNameManager::saveSensorConfig(const QString &sensorId, const QString &customName, const QString &color, bool isBold)
{
    SensorConfig config;
    config.customName = customName;
    config.color = color;
    config.isBold = isBold;
    
    m_configs[sensorId] = config;
    saveToFile();
    emit namesChanged();
}

void SensorNameManager::saveSensorName(const QString &sensorId, const QString &customName)
{
    SensorConfig config = m_configs.value(sensorId);
    config.customName = customName;
    m_configs[sensorId] = config;
    saveToFile();
    emit namesChanged();
}

void SensorNameManager::loadNames()
{
    loadFromFile();
}

bool SensorNameManager::loadFromFile()
{
    QFile file(getConfigPath());
    if (!file.exists())
    {
        return false;
    }

    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
    {
        return false;
    }

    QByteArray jsonData = file.readAll();
    file.close();

    QJsonDocument doc = QJsonDocument::fromJson(jsonData);
    if (doc.isNull() || !doc.isObject())
    {
        return false;
    }

    QJsonObject root = doc.object();
    m_configs.clear();

    for (auto it = root.begin(); it != root.end(); ++it)
    {
        SensorConfig config;
        if (it.value().isObject()) {
            QJsonObject sObj = it.value().toObject();
            config.customName = sObj["name"].toString();
            config.color = sObj["color"].toString("#1A1A1A");
            config.isBold = sObj["isBold"].toBool(false);
        } else if (it.value().isString()) {
            // Support legacy format
            config.customName = it.value().toString();
            config.color = "#1A1A1A";
            config.isBold = false;
        }
        m_configs[it.key()] = config;
    }

    return true;
}

bool SensorNameManager::saveToFile()
{
    QFile file(getConfigPath());
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text))
    {
        return false;
    }

    QJsonObject root;
    for (auto it = m_configs.begin(); it != m_configs.end(); ++it)
    {
        QJsonObject sObj;
        sObj["name"] = it.value().customName;
        sObj["color"] = it.value().color;
        sObj["isBold"] = it.value().isBold;
        root[it.key()] = sObj;
    }

    QJsonDocument doc(root);
    file.write(doc.toJson(QJsonDocument::Indented));
    file.close();

    return true;
}

QString SensorNameManager::getConfigPath() const
{
    return QCoreApplication::applicationDirPath() + "/sensor_names.json";
}
