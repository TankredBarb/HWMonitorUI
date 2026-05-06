#pragma once

#include "iSensorProvider.h"
#include <QNetworkAccessManager>
#include <QNetworkReply>

class LhmClient : public ISensorProvider
{
    Q_OBJECT

public:
    explicit LhmClient(QObject *parent = nullptr);

    void fetchData() override;

public slots:
    void reconnect() override;

private slots:
    void onNetworkReply(QNetworkReply *reply);

private:
    QNetworkAccessManager m_networkManager;
    ConnectionState m_connectionState = ConnectionState::Disconnected;
    int m_retryCount = 0;
    static const int MAX_RETRIES = 3;

    void parseJson(const QByteArray &data);
    void traverseJson(const QJsonArray &arr, QList<SensorData> &out, HardwareInfo &hw,
                      const QString &currentDevId = {}, const QString &currentDevName = {},
                      const QString &parentText = {});
    bool isKeySensor(const QString &sensorId, const QString &type, const QString &text, const QString &devId);
    void updateConnectionState(ConnectionState newState);
};