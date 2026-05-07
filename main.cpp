#include <QGuiApplication>
#include <QIcon>
#include "ApplicationController.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    ApplicationController controller;
    if (!controller.initialize())
    {
        return -1;
    }

    return controller.exec();
}