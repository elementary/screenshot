# Screenshot Tool
[![Translation status](https://l10n.elementary.io/widgets/screenshot-tool/-/svg-badge.svg)](https://l10n.elementary.io/projects/screenshot-tool/?utm_source=widget)

![Screenshot Tool Screenshot](data/screenshot.png?raw=true)

## Building, Testing, and Installation

You'll need the following dependencies:

* meson >= 0.43.0
* libcanberra-dev
* libgdk-pixbuf2.0-dev
* libgranite-dev >= 5.4.0
* valac

Run `meson` to configure the build environment and then `ninja` to build and run automated tests

    meson build --prefix=/usr
    cd build
    ninja

To install, use `ninja install`, then execute with `io.elementary.screenshot-tool`

    sudo ninja install
    io.elementary.screenshot-tool
