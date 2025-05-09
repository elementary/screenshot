project(
    'io.elementary.screenshot', 'vala', 'c',
    meson_version : '>= 0.57',
    version: '8.0.1'
)

gnome = import('gnome')
i18n = import('i18n')

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

executable(
    meson.project_name(),
    icon_res,
    'src/Application.vala',
    'src/CaptureType.vala',
    'src/SaveDialog.vala',
    'src/ScreenshotBackend.vala',
    'src/ScreenshotProxy.vala',
    config_file,
    dependencies: [
        dependency('gdk-pixbuf-2.0'),
        dependency('glib-2.0'),
        dependency('gobject-2.0'),
        dependency('gtk4', version: '>=4.10'),
        dependency('granite-7', version: '>=7.0.0'),
        dependency('libportal'),
        meson.get_compiler('vala').find_library('posix'),
    ],
    install : true
)

gnome.post_install(glib_compile_schemas: true)

subdir('data')
subdir('po')
