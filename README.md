# Screenshot Tool
[![Translation status](https://l10n.elementary.io/widgets/screenshot-tool/-/svg-badge.svg)](https://l10n.elementary.io/projects/screenshot-tool/?utm_source=widget)

## Building, Testing, and Installation

You'll need the following dependencies:
* cmake
* libcanberra-dev
* libgdk-pixbuf2.0-dev
* libgtk-3-dev
* libgranite-dev
* libnotify
* valac

It's recommended to create a clean build environment

    mkdir build
    cd build/
    
Run `cmake` to configure the build environment and then `make` to build and run automated tests

    cmake -DCMAKE_INSTALL_PREFIX=/usr ..
    make
    
To install, use `make install`, then execute with `screenshot-tool`

    sudo make install
    screenshot-tool
