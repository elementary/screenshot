project(
    'io.elementary.screenshot-tool', 'vala', 'c',
    meson_version : '>= 0.43',
    version: '0.1.5'
)

i18n = import('i18n')

add_global_arguments('-DGETTEXT_PACKAGE="io.elementary.screenshot-tool"', language:'c')

executable(
    meson.project_name(),
    'src/Application.vala',
    'src/ScreenshotWindow.vala',
    'src/Widgets/SelectionArea.vala',
    'src/Widgets/SaveDialog.vala',
    dependencies: [
        dependency('gdk-pixbuf-2.0'),
        dependency('glib-2.0'),
        dependency('gobject-2.0'),
        dependency('gtk+-3.0'),
        dependency('granite'),
        dependency('libcanberra')
    ],
    install : true
)

meson.add_install_script('meson/post_install.py')

subdir('data')
subdir('po')
