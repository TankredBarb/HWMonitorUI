#pragma once

#include "iSensorProvider.h"

class LinuxSysfsProvider : public ISensorProvider
{
    Q_OBJECT

public:
    explicit LinuxSysfsProvider(QObject *parent = nullptr);

    void fetchData() override;

private:
    void readCpuInfo(HardwareInfo &hw);
    void readCpuTemperatures(QList<SensorData> &out);
    void readCpuFrequencies(QList<SensorData> &out);
};