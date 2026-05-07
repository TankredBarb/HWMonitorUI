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
    if (m_customNames.contains(sensorId)) {
        return m_customNames[sensorId];
    }
    return defaultName;
}

void SensorNameManager::saveSensorName(const QString &sensorId, const QString &customName)
{
    if (customName.trimmed().isEmpty()) {
        m_customNames.remove(sensorId);
    } else {
        m_customNames[sensorId] = customName;
    }
    saveToFile();
}

void SensorNameManager::loadNames()
{
    QFile file(getConfigPath());
    if (file.open(QIODevice::ReadOnly)) {
        QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
        QJsonObject obj = doc.object();
        m_customNames.clear();
        for (auto it = obj.begin(); it != obj.end(); ++it) {
            m_customNames[it.key()] = it.value().toString();
        }
        file.close();
    }
}

void SensorNameManager::saveToFile()
{
    QFile file(getConfigPath());
    if (file.open(QIODevice::WriteOnly)) {
        QJsonObject obj;
        for (auto it = m_customNames.begin(); it != m_customNames.end(); ++it) {
            obj[it.key()] = it.value();
        }
        file.write(QJsonDocument(obj).toJson());
        file.close();
    }
}

QString SensorNameManager::getConfigPath() const
{
    return QCoreApplication::applicationDirPath() + "/sensor_names.json";
}