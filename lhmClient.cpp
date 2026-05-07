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
    if (m_connectionState != ConnectionState::Connected)
    {
        updateConnectionState(ConnectionState::Connecting);
    }
    
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

        updateConnectionState(ConnectionState::Error);
        reply->deleteLater();
        return;
    }

    m_retryCount = 0;
    updateConnectionState(ConnectionState::Connected);
    QByteArray data = reply->readAll();
    emit rawDataReceived(QString::fromUtf8(data));
    parseJson(data);
    reply->deleteLater();
}

bool LhmClient::isKeySensor(const QString &sensorId, const QString &type, const QString &text, const QString &devId)
{
    if (type != "Temperature" && type != "Clock")
    {
        return false;
    }

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

    if (devId.contains("lpc", Qt::CaseInsensitive) || devId.contains("motherboard", Qt::CaseInsensitive))
    {
        if (type == "Temperature")
        {
            return text.contains("Temperature #1") ||
                   text.contains("System", Qt::CaseInsensitive) ||
                   text.contains("MB", Qt::CaseInsensitive);
        }
    }

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
        traverseJson(root["Children"].toArray(), sensors, hw, QString(), QString(), QString());
    }

    emit dataReady(hw, sensors);
}

void LhmClient::traverseJson(const QJsonArray &arr, QList<SensorData> &out, HardwareInfo &hw,
                             const QString &currentDevId, const QString &currentDevName,
                             const QString &ramSectionName)
{
    for (const QJsonValue &val : arr)
    {
        QJsonObject obj = val.toObject();

        QString devId = obj.value("HardwareId").toString();
        QString devName = obj.value("Text").toString();
        QString text = obj.value("Text").toString();
        QString type = obj.value("Type").toString();
        QString rawValue = obj.value("RawValue").toString();
        QString sensorId = obj.value("SensorId").toString();

        QString activeDevId = devId.isEmpty() ? currentDevId : devId;
        QString activeDevName = devName.isEmpty() ? currentDevName : devName;

        // Memory context logic: track "Total Memory" or "Virtual Memory" sections
        // These are inside devices with ID "/ram" or "/vram", have Children but no SensorId
        // Important: don't overwrite context if we've gone deeper (into "Load" or "Data")
        QString activeRamSectionName = ramSectionName;

        if (activeDevId.contains("ram", Qt::CaseInsensitive))
        {
            // If element has children, no SensorId, and name matches - this is our memory container
            if (obj.contains("Children") && obj["Children"].isArray() && sensorId.isEmpty())
            {
                if (text == "Total Memory" || text == "Virtual Memory")
                {
                    activeRamSectionName = text;
                }
            }
        }

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

        // Helper lambda to parse value
        auto parseValue = [](const QString &raw) -> double {
            QString cleanNum = raw;
            cleanNum.remove(QRegularExpression("[^\\d,\\.]"));
            cleanNum.replace(',', '.');
            bool ok;
            return cleanNum.toDouble(&ok);
        };

        // CPU Package Power
        if (text == "Package" && type == "Power" && activeDevId.contains("cpu", Qt::CaseInsensitive))
        {
            double value = parseValue(rawValue);
            out.append({activeDevId, "CPU Package", "Power", "Power", value, "W"});
        }

        // CPU Total Load
        if (text == "CPU Total" && type == "Load")
        {
            double value = parseValue(rawValue);
            out.append({activeDevId, "CPU Total", "Load", "Load", value, "%"});
        }

        // GPU Package Power
        if (text == "GPU Package" && type == "Power" && activeDevId.contains("gpu", Qt::CaseInsensitive))
        {
            double value = parseValue(rawValue);
            out.append({activeDevId, "GPU Package", "Power", "Power", value, "W"});
        }

        // Memory Load (ONLY from "Total Memory")
        if (text == "Memory" && type == "Load")
        {
            if (activeRamSectionName == "Total Memory")
            {
                double value = parseValue(rawValue);
                out.append({activeDevId, "Memory", "Load", "Load", value, "%"});
            }
        }

        if (obj.contains("Children") && obj["Children"].isArray())
        {
            traverseJson(obj["Children"].toArray(), out, hw, activeDevId, activeDevName, activeRamSectionName);
        }

        if (!sensorId.isEmpty())
        {
            if (isKeySensor(sensorId, type, text, activeDevId))
            {
                double value = 0.0;
                QString unit;

                QString cleanNum = rawValue;
                cleanNum.remove(QRegularExpression("[^\\d,\\.]"));
                cleanNum.replace(',', '.');

                bool ok;
                value = cleanNum.toDouble(&ok);
                if (ok)
                {
                    if (type == "Temperature")
                    {
                        unit = "C";
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