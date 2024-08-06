# Screenshot
[![Translation status](https://l10n.elementary.io/widgets/screenshot/-/svg-badge.svg)](https://l10n.elementary.io/engage/screenshot/?utm_source=widget)

![Screenshot](data/screenshot.png?raw=true)

## Building, Testing, and Installation

Run `flatpak-builder` to configure the build environment, download dependencies, build, and install

```bash
    flatpak-builder build io.elementary.screenshot.yml --user --install --force-clean --install-deps-from=appcenter
```

Then execute with

```bash
    flatpak run io.elementary.screenshot
```
