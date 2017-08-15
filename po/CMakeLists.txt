include (Translations)
add_translations_directory (${GETTEXT_PACKAGE})
add_translations_catalog (${GETTEXT_PACKAGE}
    ../src
    DESKTOP_FILES
    ../data/screenshot-tool.desktop.in
    APPDATA_FILES
    ../data/${CMAKE_PROJECT_NAME}.appdata.xml.in
)
