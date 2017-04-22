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
    
Run `cmake` to configure the build environment and then `make all test` to build and run automated tests

    cmake -DCMAKE_INSTALL_PREFIX=/usr ..
    make all test
    
To install, use `make install`, then execute with `screenshot-tool`

    sudo make install
    screenshot-tool
