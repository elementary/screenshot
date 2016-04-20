include (Translations)

configure_file_translation (${CMAKE_CURRENT_SOURCE_DIR}/${CMAKE_PROJECT_NAME}.appdata.xml.in ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}.appdata.xml ${CMAKE_SOURCE_DIR}/po/)
configure_file_translation (${CMAKE_CURRENT_SOURCE_DIR}/${CMAKE_PROJECT_NAME}.desktop.in ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}.desktop ${CMAKE_SOURCE_DIR}/po/)
install (FILES ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}.appdata.xml DESTINATION share/appdata)
install (FILES ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}.desktop DESTINATION share/applications)
