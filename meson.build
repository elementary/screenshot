project(
    'io.elementary.screenshot', 'vala', 'c',
    meson_version : '>= 0.57',
    version: '6.0.4'
)

gnome = import('gnome')
i18n = import('i18n')
vala = meson.get_compiler('vala')

add_global_arguments(
    '-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name()),
    '-DHANDY_USE_UNSTABLE_API',
    language:'c'
)

icon_res = gnome.compile_resources(
    'screenshot-icon-resources',
    join_paths('data', 'gresource.xml'),
    source_dir: 'data'
)

config_data = configuration_data()
config_data.set_quoted('LOCALEDIR', join_paths(get_option('prefix'), get_option('localedir')))
config_data.set_quoted('GETTEXT_PACKAGE', meson.project_name())
config_file = configure_file(
    input: 'src/Config.vala.in',
    output: '@BASENAME@',
    configuration: config_data
)

subdir('protocol')

executable(
    meson.project_name(),
    icon_res,
    'src/Application.vala',
    'src/CaptureType.vala',
    'src/ScreenshotBackend.vala',
    'src/ScreenshotProxy.vala',
    'src/ScreenshotWindow.vala',
    'src/Widgets/SaveDialog.vala',
    config_file,
    dependencies: [
        dependency('gdk-pixbuf-2.0'),
        dependency('glib-2.0'),
        dependency('gobject-2.0'),
        dependency('gtk4'),
        dependency('gtk4-wayland'),
        dependency('wayland-client'),
        dependency('granite-7', version: '>=7.0.0'),
        meson.get_compiler('vala').find_library('posix'),
        pantheon_desktop_shell_dep,
    ],
    install : true
)

gnome.post_install(glib_compile_schemas: true)

subdir('data')
subdir('po')
