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
    QString uniqueId = s.deviceId + "::" + s.sensorName;

    map.insert("id", uniqueId);
    map.insert("name", s.sensorName);
    map.insert("value", s.value);
    map.insert("unit", s.unit);
    map.insert("type", s.type);
    map.insert("deviceId", s.deviceId);
    return map;
}

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setApplicationName("QtHwMonitor");
    app.setWindowIcon(QIcon(":/hwmon.png"));

    SensorNameManager nameManager;

    QQmlApplicationEngine engine;

    engine.rootContext()->setContextProperty("sensorNameManager", &nameManager);

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

    engine.load(QUrl(QStringLiteral("qrc:/main.qml")));
    if (engine.rootObjects().isEmpty())
    {
        return -1;
    }

    QObject *rootObject = engine.rootObjects().first();

    auto updateQmlData = [rootObject, &nameManager](const HardwareInfo &hw, const QList<SensorData> &sensors)
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
            QVariantMap map = sensorToMap(s);

            QString uniqueId = s.deviceId + "::" + s.sensorName;

            QString displayName = nameManager.getDisplayName(uniqueId, s.sensorName);

            map.insert("name", displayName);

            sensorList.append(map);
        }
        rootObject->setProperty("sensors", sensorList);
    };

    QObject::connect(provider, &ISensorProvider::dataReady, updateQmlData);

    QObject::connect(provider, &ISensorProvider::error, [](const QString &err)
    {
        qCritical() << "[ERROR]" << err;
    });

    QTimer *timer = new QTimer(&app);
    timer->setInterval(2000);

    QObject::connect(timer, &QTimer::timeout, provider, &ISensorProvider::fetchData);

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

    QObject::connect(rootObject, SIGNAL(reconnectClicked()), provider, SLOT(reconnect()));

    provider->fetchData();

    return app.exec();
}