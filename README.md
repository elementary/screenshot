# Screenshot Tool
[![Translation status](https://l10n.elementary.io/widgets/screenshot-tool/-/svg-badge.svg)](https://l10n.elementary.io/projects/screenshot-tool/?utm_source=widget)

## Building, Testing, and Installation

You'll need the following dependencies:
* cmake
* libcanberra-dev
* libgdk-pixbuf2.0-dev
* libgranite-dev
* valac

It's recommended to create a clean build environment

    mkdir build
    cd build/
    
Run `cmake` to configure the build environment and then `make` to build and run automated tests

    cmake -DCMAKE_INSTALL_PREFIX=/usr ..
    make
    
To install, use `make install`, then execute with `io.elementary.screenshot-tool`

    sudo make install
    io.elementary.screenshot-tool
