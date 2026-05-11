cmake_minimum_required(VERSION 3.16)
project(QtHwMonitor LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

find_package(QT NAMES Qt6 Qt5 REQUIRED COMPONENTS Core Qml Quick Network)
find_package(Qt${QT_VERSION_MAJOR} REQUIRED COMPONENTS Core Qml Quick Network)

set(QT_LIBS
    Qt${QT_VERSION_MAJOR}::Core
    Qt${QT_VERSION_MAJOR}::Qml
    Qt${QT_VERSION_MAJOR}::Quick
    Qt${QT_VERSION_MAJOR}::Network
)

set(QML_SOURCES
    main.qml
    HardwareInfoCard.qml
    SensorCard.qml
    SensorEditorPopup.qml
    SensorGauge.qml
    StatusFooter.qml
    TransparencyMenu.qml
    ExpertJsonView.qml
)

set(PROJECT_SOURCES
    main.cpp
    lhmClient.cpp
    lhmClient.h
    iSensorProvider.h
    linuxSysfsProvider.cpp
    linuxSysfsProvider.h
    qml.qrc
    SensorNameManager.h
    SensorNameManager.cpp
    SensorModel.h
    SensorModel.cpp
    ProcessMonitor.h
    ProcessMonitor.cpp
    ProcessIconProvider.h
    ProcessIconProvider.cpp
    ApplicationController.h
    ApplicationController.cpp
    ${QML_SOURCES}
)


if(WIN32)
    list(APPEND PROJECT_SOURCES
        resources.rc
        app.ico
    )
endif()

add_executable(qthwmon ${PROJECT_SOURCES})

target_link_libraries(qthwmon PRIVATE ${QT_LIBS})

if(WIN32)
    set_target_properties(qthwmon PROPERTIES WIN32_EXECUTABLE ON)
    target_link_libraries(qthwmon PRIVATE psapi)
endif()
