project (screenshot-tool)
cmake_minimum_required (VERSION 2.8)

list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake/vala)

#
# Base
#
set (DATADIR "${CMAKE_INSTALL_PREFIX}/share")
set (PKGDATADIR "${DATADIR}/${CMAKE_PROJECT_NAME}")
set (GETTEXT_PACKAGE "${CMAKE_PROJECT_NAME}")
set (RELEASE_NAME "Just a photogram.")
set (VERSION "0.1.3.1")
set (VERSION_INFO "Development")

list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

#
# Niceties
#
set (ARCHIVE_NAME ${CMAKE_PROJECT_NAME}-${VERSION})
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
# data
#
add_subdirectory(data)

#
# Agenda
#
find_package(PkgConfig)

pkg_check_modules(DEPS REQUIRED
        gtk+-3.0>=3.12
        granite
        gdk-pixbuf-2.0
        libcanberra)

add_definitions(${DEPS_CFLAGS} -w)

link_libraries(${DEPS_LIBRARIES})
link_directories(${DEPS_LIBRARY_DIRS})

find_package(Vala REQUIRED)

include(ValaVersion)
ensure_vala_version("0.24.0" MINIMUM)

include(ValaPrecompile)
vala_precompile(VALA_C ${CMAKE_PROJECT_NAME}
        src/Screenshot.vala
        src/ScreenshotWindow.vala
        src/Widgets/SelectionArea.vala
        src/Widgets/SaveDialog.vala
PACKAGES
        gtk+-3.0
        granite
        libcanberra
CUSTOM_VAPIS
        vapi/config.vapi
OPTIONS
        --thread
)

add_executable(${CMAKE_PROJECT_NAME} ${VALA_C})

install (TARGETS ${CMAKE_PROJECT_NAME} RUNTIME DESTINATION bin)

option (ICON_UPDATE "Run gtk-update-icon-cache after the install." ON)
if (ICON_UPDATE)
  install (CODE "message(\"-- Updating icon cache...\")")
  install (CODE "execute_process(COMMAND gtk-update-icon-cache -f -t ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor)")
endif (ICON_UPDATE)
