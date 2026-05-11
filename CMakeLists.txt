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

set(PROJECT_SOURCES
    src/main.cpp
    src/lhmClient.cpp
    include/lhmClient.h
    include/iSensorProvider.h
    src/linuxSysfsProvider.cpp
    include/linuxSysfsProvider.h
    include/SensorNameManager.h
    src/SensorNameManager.cpp
    include/SensorModel.h
    src/SensorModel.cpp
    include/ProcessMonitor.h
    src/ProcessMonitor.cpp
    include/ProcessIconProvider.h
    src/ProcessIconProvider.cpp
    include/ApplicationController.h
    src/ApplicationController.cpp
    qml.qrc
)

if(WIN32)
    list(APPEND PROJECT_SOURCES
        resources/resources.rc
        resources/app.ico
    )
endif()

add_executable(qthwmon ${PROJECT_SOURCES})

target_include_directories(qthwmon PRIVATE include)
target_link_libraries(qthwmon PRIVATE ${QT_LIBS})

if(WIN32)
    set_target_properties(qthwmon PROPERTIES WIN32_EXECUTABLE ON)
    target_link_libraries(qthwmon PRIVATE psapi)
endif()
