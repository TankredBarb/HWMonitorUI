#include "linuxSysfsProvider.h"
#include <QFile>
#include <QDir>
#include <QTextStream>
#include <QRegularExpression>

LinuxSysfsProvider::LinuxSysfsProvider(QObject *parent) : ISensorProvider(parent)
{
}

void LinuxSysfsProvider::fetchData()
{
    QList<SensorData> sensors;
    HardwareInfo hw;

    readCpuInfo(hw);
    readCpuTemperatures(sensors);
    readCpuFrequencies(sensors);

    emit dataReady(hw, sensors);
}

void LinuxSysfsProvider::readCpuInfo(HardwareInfo &hw)
{
    QFile cpuinfo("/proc/cpuinfo");
    if (cpuinfo.open(QIODevice::ReadOnly | QIODevice::Text))
    {
        QTextStream in(&cpuinfo);
        QString content = in.readAll();

        QRegularExpression re("model name\\s*:\\s*(.+)");
        QRegularExpressionMatch match = re.match(content);
        if (match.hasMatch())
        {
            hw.cpuModel = match.captured(1).trimmed();
        }
    }
}

void LinuxSysfsProvider::readCpuTemperatures(QList<SensorData> &out)
{
    QDir dir("/sys/class/thermal");
    for (const QFileInfo &entry : dir.entryInfoList(QDir::Dirs | QDir::NoDotAndDotDot))
    {
        QFile typeFile(entry.filePath() + "/type");
        QFile tempFile(entry.filePath() + "/temp");

        if (typeFile.open(QIODevice::ReadOnly | QIODevice::Text) &&
            tempFile.open(QIODevice::ReadOnly | QIODevice::Text))
        {
            QString type = QTextStream(&typeFile).readAll().trimmed();
            QString rawTemp = QTextStream(&tempFile).readAll().trimmed();
            double temp = rawTemp.toDouble() / 1000.0;

            out.append({"linux_thermal", "Linux Thermal", type, "Temperature", temp, "°C"});
        }
    }
}

void LinuxSysfsProvider::readCpuFrequencies(QList<SensorData> &out)
{
    QDir dir("/sys/devices/system/cpu");
    for (const QFileInfo &entry : dir.entryInfoList(QDir::Dirs | QDir::NoDotAndDotDot))
    {
        if (!entry.fileName().startsWith("cpu"))
        {
            continue;
        }

        QFile freqFile(entry.filePath() + "/cpufreq/scaling_cur_freq");
        if (freqFile.open(QIODevice::ReadOnly | QIODevice::Text))
        {
            QString rawKhz = QTextStream(&freqFile).readAll().trimmed();
            double freq = rawKhz.toDouble() / 1000.0;

            out.append({"linux_cpu", "Linux CPU", entry.fileName(), "Clock", freq, "MHz"});
        }
    }
}