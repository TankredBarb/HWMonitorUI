#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QVariantList>
#include <QVariantMap>
#include <QTimer>
#include <QDebug>
#include <QIcon>
#include "iSensorProvider.h"

#ifdef Q_OS_WIN
    #include "lhmClient.h"
#elif defined(Q_OS_LINUX)
    #include "linuxSysfsProvider.h"
#endif

// Helper to convert C++ struct to QML-friendly QVariantMap
QVariantMap sensorToMap(const SensorData &s)
{
    QVariantMap map;
    map.insert("name", s.sensorName);
    map.insert("value", s.value);
    map.insert("unit", s.unit);
    map.insert("type", s.type);
    return map;
}

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setApplicationName("QtHwMonitor");
    app.setWindowIcon(QIcon(":/hwmon.png"));

    QQmlApplicationEngine engine;

    // Initialize Provider
    ISensorProvider *provider = nullptr;
#ifdef Q_OS_WIN
    provider = new LhmClient(&app);
#elif defined(Q_OS_LINUX)
    provider = new LinuxSysfsProvider(&app);
#endif

    if (!provider)
    {
        qFatal("Unsupported platform");
        return -1;
    }

    // Load QML
    engine.load(QUrl(QStringLiteral("qrc:/main.qml")));
    if (engine.rootObjects().isEmpty())
    {
        return -1;
    }

    QObject *rootObject = engine.rootObjects().first();

    // Function to update QML properties with current data
    auto updateQmlData = [rootObject](const HardwareInfo &hw, const QList<SensorData> &sensors)
    {
        if (!rootObject) return;

        // 1. Update Hardware Info
        QVariantMap hwMap;
        hwMap.insert("cpu", hw.cpuModel);
        hwMap.insert("gpu", hw.gpuModel);
        hwMap.insert("mb", hw.motherboardModel);
        rootObject->setProperty("hardwareInfo", hwMap);

        // 2. Update Sensors List
        QVariantList sensorList;
        for (const auto &s : sensors)
        {
            sensorList.append(sensorToMap(s));
        }
        rootObject->setProperty("sensors", sensorList);
    };

    // Connect Signal -> Update QML Properties
    QObject::connect(provider, &ISensorProvider::dataReady, updateQmlData);

    // Connect Error -> Log
    QObject::connect(provider, &ISensorProvider::error, [](const QString &err)
    {
        qCritical() << "[ERROR]" << err;
    });

    // Setup Timer for Live Updates (every 2 seconds)
    QTimer *timer = new QTimer(&app);
    timer->setInterval(2000); // 2000 ms = 2 seconds

    // Connect Timer Timeout -> Fetch Data
    QObject::connect(timer, &QTimer::timeout, provider, &ISensorProvider::fetchData);

    // Connect Connection State Changed -> Control Timer and Update QML
    QObject::connect(provider, &ISensorProvider::connectionStateChanged, [rootObject, timer](ISensorProvider::ConnectionState state)
    {
        if (!rootObject) return;

        // Update QML property
        rootObject->setProperty("connectionState", static_cast<int>(state));

        // Update status text based on state
        QString statusText;
        switch (state)
        {
            case ISensorProvider::ConnectionState::Disconnected:
                statusText = "Disconnected";
                timer->stop(); // STOP updates when disconnected
                break;
            case ISensorProvider::ConnectionState::Connecting:
                statusText = "Connecting...";
                timer->stop(); // Stop updates while connecting
                break;
            case ISensorProvider::ConnectionState::Error:
                statusText = "Connection Error";
                timer->stop(); // STOP updates on error
                break;
            case ISensorProvider::ConnectionState::Connected:
                statusText = "Connected";
                timer->start(); // START updates only when connected
                break;
        }
        rootObject->setProperty("connectionStatusText", statusText);
    });

    // Expose provider's reconnect method to QML
    QObject::connect(rootObject, SIGNAL(reconnectClicked()), provider, SLOT(reconnect()));

    // Initial fetch immediately to attempt connection
    provider->fetchData();

    // Note: The timer will automatically start only when the first "Connected" state is received.
    // If the initial fetch fails, the timer remains stopped until user clicks reconnect.

    return app.exec();
}