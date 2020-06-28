project(
    'io.elementary.screenshot-tool', 'vala', 'c',
    meson_version : '>= 0.46',
    version: '1.7.1'
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
    'src/CaptureType.vala',
    'src/ScreenshotBackend.vala',
    'src/ScreenshotProxy.vala',
    'src/ScreenshotWindow.vala',
    'src/Widgets/SaveDialog.vala',
    dependencies: [
        dependency('gdk-pixbuf-2.0'),
        dependency('glib-2.0'),
        dependency('gobject-2.0'),
        dependency('gtk+-3.0'),
        dependency('granite', version: '>=5.4.0'),
        dependency('libcanberra'),
        meson.get_compiler('vala').find_library('posix'),
    ],
    install : true
)

meson.add_install_script('meson/post_install.py')

subdir('data')
subdir('po')
