#pragma once

#include <QObject>
#include <QList>
#include <QString>

struct SensorData
{
    QString deviceId;
    QString deviceName;
    QString sensorName;
    QString type;
    double value = 0.0;
    QString unit;
};

struct HardwareInfo
{
    QString cpuModel;
    QString gpuModel;
    QString motherboardModel;
};

class ISensorProvider : public QObject
{
    Q_OBJECT

public:
    explicit ISensorProvider(QObject *parent = nullptr) : QObject(parent) {}
    virtual ~ISensorProvider() = default;

    virtual void fetchData() = 0;

signals:
    void dataReady(const HardwareInfo &hardware, const QList<SensorData> &sensors);
    void error(const QString &message);
};