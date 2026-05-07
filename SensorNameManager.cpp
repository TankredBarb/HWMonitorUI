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
    emit namesChanged();
}

void SensorNameManager::loadNames()
{
    loadFromFile();
}

bool SensorNameManager::loadFromFile()
{
    QFile file(getConfigPath());
    if (!file.exists()) {
        return false;
    }

    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qWarning() << "SensorNameManager: Failed to open config file for reading:" << getConfigPath();
        return false;
    }

    QByteArray jsonData = file.readAll();
    file.close();

    QJsonParseError parseError;
    QJsonDocument doc = QJsonDocument::fromJson(jsonData, &parseError);

    if (parseError.error != QJsonParseError::NoError) {
        qWarning() << "SensorNameManager: Failed to parse JSON config:" << parseError.errorString();
        return false;
    }

    if (!doc.isObject()) {
        qWarning() << "SensorNameManager: Config file is not a valid JSON object";
        return false;
    }

    QJsonObject obj = doc.object();
    m_customNames.clear();

    for (auto it = obj.begin(); it != obj.end(); ++it) {
        if (it.value().isString()) {
            m_customNames[it.key()] = it.value().toString();
        }
    }

    return true;
}

bool SensorNameManager::saveToFile()
{
    QFile file(getConfigPath());

    if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        qWarning() << "SensorNameManager: Failed to open config file for writing:" << getConfigPath();
        return false;
    }

    QJsonObject obj;
    for (auto it = m_customNames.begin(); it != m_customNames.end(); ++it) {
        obj[it.key()] = it.value();
    }

    QJsonDocument doc(obj);
    file.write(doc.toJson(QJsonDocument::Indented));
    file.close();

    return true;
}

QString SensorNameManager::getConfigPath() const
{
    return QCoreApplication::applicationDirPath() + "/sensor_names.json";
}