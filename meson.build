project(
    'io.elementary.screenshot-tool', 'vala', 'c',
    meson_version : '>= 0.43',
    version: '1.6.0'
)

gnome = import('gnome')
i18n = import('i18n')

add_global_arguments('-DGETTEXT_PACKAGE="io.elementary.screenshot-tool"', language:'c')

icon_res = gnome.compile_resources(
    'screenshot-icon-resources',
    'data/' + meson.project_name() + '.gresource.xml',
    source_dir: 'data'
)

executable(
    meson.project_name(),
    icon_res,
    'src/Application.vala',
    'src/ScreenshotWindow.vala',
    'src/Widgets/SelectionArea.vala',
    'src/Widgets/TimersList.vala',
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
