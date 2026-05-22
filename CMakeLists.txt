cmake_minimum_required(VERSION 3.16)
project(occt-viewer-qt LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

find_package(Qt6 REQUIRED COMPONENTS Widgets OpenGLWidgets)
find_package(OpenGL REQUIRED)

set(OCCT_DIR "${CMAKE_SOURCE_DIR}/.local" CACHE PATH "OCCT install prefix")
set(OpenCASCADE_INCLUDE_DIR "${OCCT_DIR}/include/opencascade")

set(OpenCASCADE_LIBS
    TKOpenGl TKV3d TKService
    TKernel TKMath TKG2d TKG3d TKBRep TKPrim TKTopAlgo
    TKGeomAlgo TKGeomBase TKShHealing TKHLR TKMesh
)

# Create imported targets for OCCT shared libs
foreach(lib ${OpenCASCADE_LIBS})
    if(NOT TARGET OCC_${lib})
        add_library(OCC_${lib} SHARED IMPORTED)
        set_target_properties(OCC_${lib} PROPERTIES
            IMPORTED_LOCATION "${OCCT_DIR}/lib/lib${lib}.so"
            INTERFACE_INCLUDE_DIRECTORIES "${OpenCASCADE_INCLUDE_DIR}")
    endif()
endforeach()

set(SOURCES
    wrap/occt_viewer.cpp
    wrap/viewer_window.cpp
    wrap/viewer_widget.cpp
    wrap/repl_panel.cpp
    wrap/scene_tree_panel.cpp
    wrap/OcctQtTools.cpp
    wrap/OcctGlTools.cpp
)

# Derive ClotCAD version from git tags
execute_process(COMMAND git describe --tags --dirty --always
                OUTPUT_VARIABLE CLOTCAD_VERSION_RAW
                OUTPUT_STRIP_TRAILING_WHITESPACE
                WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
string(REGEX REPLACE "^v" "" CLOTCAD_VERSION "${CLOTCAD_VERSION_RAW}")

# Get SBCL version at configure time
execute_process(COMMAND sbcl --version
                OUTPUT_VARIABLE SBCL_VERSION_RAW
                OUTPUT_STRIP_TRAILING_WHITESPACE)
string(STRIP "${SBCL_VERSION_RAW}" SBCL_VERSION)

add_library(occtviewer SHARED ${SOURCES})

target_compile_definitions(occtviewer PRIVATE
    CLOTCAD_VERSION="${CLOTCAD_VERSION}"
    SBCL_VERSION="${SBCL_VERSION}")

set_source_files_properties(${CMAKE_CURRENT_SOURCE_DIR}/share/icons/ClotCAD-logo.svg PROPERTIES
    QT_RESOURCE_ALIAS "icons/ClotCAD-logo.svg"
)
qt6_add_resources(occtviewer "app_resources"
    PREFIX "/"
    FILES
        ${CMAKE_CURRENT_SOURCE_DIR}/share/icons/ClotCAD-logo.svg
)
target_include_directories(occtviewer PRIVATE
    ${CMAKE_SOURCE_DIR}/wrap
    ${OpenCASCADE_INCLUDE_DIR}
)
target_link_libraries(occtviewer PRIVATE
    Qt6::Widgets
    Qt6::OpenGLWidgets
    OpenGL::GL
    OCC_TKOpenGl OCC_TKV3d OCC_TKService
    OCC_TKernel OCC_TKMath OCC_TKG2d OCC_TKG3d
    OCC_TKBRep OCC_TKPrim OCC_TKTopAlgo
    OCC_TKGeomAlgo OCC_TKGeomBase OCC_TKShHealing
    OCC_TKHLR OCC_TKMesh
)

install(TARGETS occtviewer
    LIBRARY DESTINATION lib
)
