project (screenshot)
cmake_minimum_required (VERSION 2.8)

list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake/vala)

#
# Base
#
set (DATADIR "${CMAKE_INSTALL_PREFIX}/share")
set (PKGDATADIR "${DATADIR}/screenshot")
set (GETTEXT_PACKAGE "screenshot")
set (RELEASE_NAME "Just a photogram.")
set (VERSION "0.1")
set (VERSION_INFO "Development")

list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

#
# Niceties
#
set (ARCHIVE_NAME screenshot-${VERSION})
add_custom_target (dist
    COMMAND bzr export --root=${ARCHIVE_NAME} ${CMAKE_BINARY_DIR}/${ARCHIVE_NAME}.tar.bz2
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)

add_custom_target (distcheck
    COMMAND cd ${CMAKE_BINARY_DIR}
    && rm -rf ${ARCHIVE_NAME}
    && tar xf ${ARCHIVE_NAME}.tar.bz2
    && mkdir ${ARCHIVE_NAME}/build
    && cd ${ARCHIVE_NAME}/build
    && cmake -DCMAKE_INSTALL_PREFIX=../install -DGSETTINGS_LOCALINSTALL=ON .. -DCMAKE_MODULE_PATH=/usr/share/cmake
    && make -j8
    && make -j8 install
    && make check
)
add_dependencies (distcheck dist)

add_custom_target (uninstall "${CMAKE_COMMAND}" -P
    "${CMAKE_SOURCE_DIR}/cmake/uninstall.cmake")

#
# config.h
#
configure_file (${CMAKE_SOURCE_DIR}/config.h.cmake ${CMAKE_BINARY_DIR}/config.h)
add_definitions(-include config.h)

#
# i18n
#
add_subdirectory(po)

#
# dconf
#
add_subdirectory(schemas)

#
# Agenda
#
find_package(PkgConfig)

pkg_check_modules(DEPS REQUIRED
        gtk+-3.0>=3.12
        granite
        libnotify
        gdk-pixbuf-2.0)

add_definitions(${DEPS_CFLAGS} -w)

link_libraries(${DEPS_LIBRARIES})
link_directories(${DEPS_LIBRARY_DIRS})

find_package(Vala REQUIRED)

include(ValaVersion)
ensure_vala_version("0.24.0" MINIMUM)

pkg_check_modules(GTK314_MIN QUIET gtk+-3.0>=3.14.0)
if (GTK314_MIN_FOUND)
    set(EXTRA_VALA_OPTS ${EXTRA_VALA_OPTS} -D HAS_GTK314_MIN)
endif()

include(ValaPrecompile)
vala_precompile(VALA_C ${CMAKE_PROJECT_NAME}
        src/Screenshot.vala
        src/ScreenshotWindow.vala
        src/Widgets/SelectionArea.vala
        src/Widgets/SaveDialog.vala
        src/Translations.vala
        src/Utils.vala
PACKAGES
        gtk+-3.0
        granite
        libnotify
CUSTOM_VAPIS
        vapi/config.vapi
OPTIONS
        --thread
)

add_executable(screenshot ${VALA_C})

install (TARGETS screenshot RUNTIME DESTINATION bin)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/screenshot.desktop DESTINATION share/applications)

option (ICON_UPDATE "Run gtk-update-icon-cache after the install." ON)
if (ICON_UPDATE)
  install (CODE "message(\"-- Updating icon cache...\")")
  install (CODE "execute_process(COMMAND gtk-update-icon-cache -f -t ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor)")
endif (ICON_UPDATE)
