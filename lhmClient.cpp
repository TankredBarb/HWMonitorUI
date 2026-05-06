#include "lhmClient.h"
#include <QNetworkRequest>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QRegularExpression>
#include <QDebug>
#include <QTimer>

LhmClient::LhmClient(QObject *parent) : ISensorProvider(parent)
{
    connect(&m_networkManager, &QNetworkAccessManager::finished,
            this, &LhmClient::onNetworkReply);
    updateConnectionState(ConnectionState::Disconnected);
}

void LhmClient::fetchData()
{
    updateConnectionState(ConnectionState::Connecting);
    QNetworkRequest request(QUrl("http://127.0.0.1:8085/data.json"));
    request.setHeader(QNetworkRequest::UserAgentHeader, "QtHwMonitor/1.0");
    m_networkManager.get(request);
}

void LhmClient::reconnect()
{
    m_retryCount = 0;
    m_networkManager.clearAccessCache();
    updateConnectionState(ConnectionState::Connecting);
    fetchData();
}

void LhmClient::updateConnectionState(ConnectionState newState)
{
    if (m_connectionState != newState)
    {
        m_connectionState = newState;
        emit connectionStateChanged(newState);
    }
}

void LhmClient::onNetworkReply(QNetworkReply *reply)
{
    if (!reply)
    {
        return;
    }

    if (reply->error() != QNetworkReply::NoError)
    {
        m_retryCount++;

        // Check if hwmon is not running (connection refused)
        if (reply->error() == QNetworkReply::ConnectionRefusedError)
        {
            emit error("Hardware Monitor service is not running. Please start hwmonitor and try again.");
        }
        else if (reply->error() == QNetworkReply::TimeoutError)
        {
            emit error("Connection timeout. Please check your network settings.");
        }
        else
        {
            emit error(reply->errorString());
        }

        // No auto-retry - wait for user to click Reconnect button
        updateConnectionState(ConnectionState::Error);

        reply->deleteLater();
        return;
    }

    // Success - reset retry count and update state
    m_retryCount = 0;
    updateConnectionState(ConnectionState::Connected);

    parseJson(reply->readAll());
    reply->deleteLater();
}

bool LhmClient::isKeySensor(const QString &sensorId, const QString &type, const QString &text, const QString &devId)
{
    if (type != "Temperature" && type != "Clock")
    {
        return false;
    }

    // 1. CPU Metrics
    if (devId.contains("cpu", Qt::CaseInsensitive))
    {
        if (type == "Temperature")
        {
            return text.contains("Core", Qt::CaseInsensitive) ||
                   text.contains("Package", Qt::CaseInsensitive) ||
                   text.contains("Tctl", Qt::CaseInsensitive);
        }
        if (type == "Clock")
        {
            return text.contains("Average", Qt::CaseInsensitive) &&
                   !text.contains("Effective", Qt::CaseInsensitive);
        }
    }

    // 2. Motherboard Metrics
    if (devId.contains("lpc", Qt::CaseInsensitive) || devId.contains("motherboard", Qt::CaseInsensitive))
    {
        if (type == "Temperature")
        {
            return text.contains("Temperature #1") ||
                   text.contains("System", Qt::CaseInsensitive) ||
                   text.contains("MB", Qt::CaseInsensitive);
        }
    }

    // 3. GPU Metrics
    if (devId.contains("gpu", Qt::CaseInsensitive))
    {
        if (type == "Temperature")
        {
            return text.contains("GPU Core", Qt::CaseInsensitive) ||
                   text.contains("Edge", Qt::CaseInsensitive);
        }
    }

    return false;
}

void LhmClient::parseJson(const QByteArray &data)
{
    QJsonParseError err;
    QJsonDocument doc = QJsonDocument::fromJson(data, &err);
    if (err.error != QJsonParseError::NoError)
    {
        emit error("JSON parse error: " + err.errorString());
        return;
    }

    QList<SensorData> sensors;
    HardwareInfo hw;
    QJsonObject root = doc.object();
    if (root.contains("Children") && root["Children"].isArray())
    {
        traverseJson(root["Children"].toArray(), sensors, hw);
    }

    emit dataReady(hw, sensors);
}

void LhmClient::traverseJson(const QJsonArray &arr, QList<SensorData> &out, HardwareInfo &hw,
                             const QString &currentDevId, const QString &currentDevName)
{
    for (const QJsonValue &val : arr)
    {
        QJsonObject obj = val.toObject();

        QString devId = obj.value("HardwareId").toString();
        QString devName = obj.value("Text").toString();

        QString activeDevId = devId.isEmpty() ? currentDevId : devId;
        QString activeDevName = devName.isEmpty() ? currentDevName : devName;

        if (!devId.isEmpty())
        {
            if (devId.contains("cpu", Qt::CaseInsensitive))
            {
                hw.cpuModel = devName;
            }
            else if (devId.contains("gpu", Qt::CaseInsensitive))
            {
                hw.gpuModel = devName;
            }
            else if (devId.contains("motherboard", Qt::CaseInsensitive))
            {
                hw.motherboardModel = devName;
            }
        }

        if (obj.contains("Children") && obj["Children"].isArray())
        {
            traverseJson(obj["Children"].toArray(), out, hw, activeDevId, activeDevName);
        }

        QString sensorId = obj.value("SensorId").toString();
        if (!sensorId.isEmpty())
        {
            QString type = obj.value("Type").toString();
            QString text = obj.value("Text").toString();
            QString rawValue = obj.value("RawValue").toString();

            if (isKeySensor(sensorId, type, text, activeDevId))
            {
                double value = 0.0;
                QString unit;

                // Clean number string: keep only digits, dot, comma
                QString cleanNum = rawValue;
                cleanNum.remove(QRegularExpression("[^\\d,\\.]"));
                cleanNum.replace(',', '.');

                bool ok;
                value = cleanNum.toDouble(&ok);
                if (ok)
                {
                    // Hardcode units based on type to avoid encoding issues with '°' symbol
                    if (type == "Temperature")
                    {
                        unit = "C"; // Simple ASCII 'C' instead of '°C'
                    }
                    else if (type == "Clock")
                    {
                        unit = "MHz";
                    }
                    else
                    {
                        unit = "";
                    }

                    out.append({activeDevId, activeDevName, text, type, value, unit});
                }
            }
        }
    }
}