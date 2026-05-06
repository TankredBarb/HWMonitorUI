#include <QCoreApplication>
#include <QDebug>
#include <iostream>
#include <iomanip>
#include "iSensorProvider.h"

#ifdef Q_OS_WIN
    #include "lhmClient.h"
#elif defined(Q_OS_LINUX)
    #include "linuxSysfsProvider.h"
#endif

void printConsole(const HardwareInfo &hw, const QList<SensorData> &sensors)
{
    std::cout << "\n";
    std::cout << "========================================================\n";
    std::cout << "                   HARDWARE MONITOR                    \n";
    std::cout << "========================================================\n";

    if (!hw.cpuModel.isEmpty())
    {
        std::cout << "CPU: " << hw.cpuModel.toStdString() << "\n";
    }
    if (!hw.gpuModel.isEmpty())
    {
        std::cout << "GPU: " << hw.gpuModel.toStdString() << "\n";
    }
    if (!hw.motherboardModel.isEmpty())
    {
        std::cout << "MB:  " << hw.motherboardModel.toStdString() << "\n";
    }

    std::cout << "--------------------------------------------------------\n";
    // Widths: Sensor=35, Value=8, Unit=5
    std::cout << std::left << std::setw(35) << "SENSOR"
              << std::right << std::setw(8) << "VALUE"
              << std::setw(5) << "UNIT" << "\n";
    std::cout << "--------------------------------------------------------\n";

    for (const auto &s : sensors)
    {
        std::string sensorName = s.sensorName.toStdString();
        // Truncate long names
        if (sensorName.length() > 35)
        {
            sensorName = sensorName.substr(0, 32) + "...";
        }

        std::cout << std::left << std::setw(35) << sensorName
                  << std::right << std::fixed << std::setprecision(1)
                  << std::setw(8) << s.value
                  << std::setw(5) << s.unit.toStdString() << "\n";
    }

    std::cout << "========================================================\n";
}

int main(int argc, char *argv[])
{
    QCoreApplication app(argc, argv);
    app.setApplicationName("QtHwMonitor");
    app.setOrganizationName("Dev");

    ISensorProvider *provider = nullptr;
#ifdef Q_OS_WIN
    provider = new LhmClient(&app);
#elif defined(Q_OS_LINUX)
    provider = new LinuxSysfsProvider(&app);
#else
    qFatal("Unsupported platform");
#endif

    QObject::connect(provider, &ISensorProvider::dataReady,
                     [&app](const HardwareInfo &hw, const QList<SensorData> &data)
    {
        printConsole(hw, data);
        QCoreApplication::quit();
    });

    QObject::connect(provider, &ISensorProvider::error, [&app](const QString &err)
    {
        qCritical() << "[ERROR] " << err;
        QCoreApplication::quit();
    });

    provider->fetchData();
    return app.exec();
}