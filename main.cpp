#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QVariantList>
#include <QVariantMap>
#include <QTimer>
#include <QDebug>
#include <QIcon>
#include "iSensorProvider.h"
#include "SensorNameManager.h"

#ifdef Q_OS_WIN
    #include "lhmClient.h"
#elif defined(Q_OS_LINUX)
    #include "linuxSysfsProvider.h"
#endif

// Helper to convert C++ struct to QML-friendly QVariantMap
QVariantMap sensorToMap(const SensorData &s)
{
    QVariantMap map;
    // Создаем уникальный ID: DeviceID::SensorName (например: "cpu::package" или "gpu::package")
    QString uniqueId = s.deviceId + "::" + s.sensorName;

    map.insert("id", uniqueId);
    map.insert("name", s.sensorName); // Пока сырое имя, в QML или здесь заменим на отображаемое
    map.insert("value", s.value);
    map.insert("unit", s.unit);
    map.insert("type", s.type);
    map.insert("deviceId", s.deviceId); // На всякий случай передаем и отдельно
    return map;
}

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setApplicationName("QtHwMonitor");
    app.setWindowIcon(QIcon(":/hwmon.png"));

    // Initialize Sensor Name Manager
    SensorNameManager nameManager;

    QQmlApplicationEngine engine;

    // Expose nameManager to QML
    engine.rootContext()->setContextProperty("sensorNameManager", &nameManager);

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
    auto updateQmlData = [rootObject, &nameManager](const HardwareInfo &hw, const QList<SensorData> &sensors)
    {
        if (!rootObject) return;

        // 1. Update Hardware Info
        QVariantMap hwMap;
        hwMap.insert("cpu", hw.cpuModel);
        hwMap.insert("gpu", hw.gpuModel);
        hwMap.insert("mb", hw.motherboardModel);
        rootObject->setProperty("hardwareInfo", hwMap);

        // 2. Update Sensors List (with custom names applied)
        QVariantList sensorList;
        for (const auto &s : sensors)
        {
            QVariantMap map = sensorToMap(s);

            // Формируем тот же уникальный ключ
            QString uniqueId = s.deviceId + "::" + s.sensorName;

            // Получаем отображаемое имя (кастомное или стандартное)
            QString displayName = nameManager.getDisplayName(uniqueId, s.sensorName);

            // Заменяем имя в мапе на отображаемое
            map.insert("name", displayName);

            sensorList.append(map);
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
    timer->setInterval(2000);

    // Connect Timer Timeout -> Fetch Data
    QObject::connect(timer, &QTimer::timeout, provider, &ISensorProvider::fetchData);

    // Connect Connection State Changed -> Control Timer and Update QML
    QObject::connect(provider, &ISensorProvider::connectionStateChanged, [rootObject, timer](ISensorProvider::ConnectionState state)
    {
        if (!rootObject) return;

        rootObject->setProperty("connectionState", static_cast<int>(state));

        QString statusText;
        switch (state)
        {
            case ISensorProvider::ConnectionState::Disconnected:
                statusText = "Disconnected";
                timer->stop();
                break;
            case ISensorProvider::ConnectionState::Connecting:
                statusText = "Connecting...";
                timer->stop();
                break;
            case ISensorProvider::ConnectionState::Error:
                statusText = "Connection Error";
                timer->stop();
                break;
            case ISensorProvider::ConnectionState::Connected:
                statusText = "Connected";
                timer->start();
                break;
        }
        rootObject->setProperty("connectionStatusText", statusText);
    });

    // Expose provider's reconnect method to QML
    QObject::connect(rootObject, SIGNAL(reconnectClicked()), provider, SLOT(reconnect()));

    // Initial fetch immediately to attempt connection
    provider->fetchData();

    return app.exec();
}