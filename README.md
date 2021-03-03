# Screenshot
[![Translation status](https://l10n.elementary.io/widgets/screenshot/-/svg-badge.svg)](https://l10n.elementary.io/engage/screenshot/?utm_source=widget)

![Screenshot](data/screenshot.png?raw=true)

## Building, Testing, and Installation

You'll need the following dependencies:

* meson >= 0.43.0
* libcanberra-dev
* libgdk-pixbuf2.0-dev
* libgranite-dev >= 6.0.0
* libhandy-1 >= 0.83.0
* valac

Run `meson` to configure the build environment and then `ninja` to build and run automated tests

    meson build --prefix=/usr
    cd build
    ninja

To install, use `ninja install`, then execute with `io.elementary.screenshot`

    sudo ninja install
    io.elementary.screenshot
