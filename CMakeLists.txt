cmake_minimum_required(VERSION 3.16)
project(QtHwMonitor LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

# Resolve Qt dependencies (Qt6 -> Qt5.15 fallback)
find_package(Qt6 COMPONENTS Core Network QUIET)
if (NOT Qt6_FOUND)
    find_package(Qt5 5.15 COMPONENTS Core Network REQUIRED)
    set(QT_TARGETS Qt5::Core Qt5::Network)
else()
    set(QT_TARGETS Qt6::Core Qt6::Network)
endif()

add_executable(qthwmon
    main.cpp
    lhmClient.cpp
    lhmClient.h
    iSensorProvider.h
    linuxSysfsProvider.cpp
    linuxSysfsProvider.h
)

target_link_libraries(qthwmon PRIVATE ${QT_TARGETS})