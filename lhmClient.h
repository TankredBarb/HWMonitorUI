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

private slots:
    void onNetworkReply(QNetworkReply *reply);

private:
    QNetworkAccessManager m_networkManager;
    void parseJson(const QByteArray &data);
    void traverseJson(const QJsonArray &arr, QList<SensorData> &out, HardwareInfo &hw,
                      const QString &currentDevId = {}, const QString &currentDevName = {});
    bool isKeySensor(const QString &sensorId, const QString &type, const QString &text, const QString &devId);
};