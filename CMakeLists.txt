cmake_minimum_required(VERSION 3.12 FATAL_ERROR)
project(imgdecode)

file(GLOB imgdecode_stb_backend CONFIGURE_DEPENDS "${C_SRC}/imgdecode_stb.cpp" "${C_SRC}/nif_utils.hpp")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fPIC -I${ERTS_INCLUDE_DIR} -I${STB_INCLUDE_DIR} -O3 -Wall -Wextra -Wno-unused-parameter -Wno-missing-field-initializers")

add_library(imgdecode SHARED ${imgdecode_stb_backend})
set_property(TARGET imgdecode PROPERTY CXX_STANDARD 14)
set_target_properties(imgdecode PROPERTIES PREFIX "")
set_target_properties(imgdecode PROPERTIES SUFFIX ".so")
target_compile_definitions(imgdecode PRIVATE STBI_WINDOWS_UTF8=1)

set_target_properties(imgdecode PROPERTIES
    INSTALL_RPATH_USE_LINK_PATH TRUE
    BUILD_WITH_INSTALL_RPATH TRUE
)

if(APPLE)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -undefined dynamic_lookup")
    set(CMAKE_SHARED_LINKER_FLAGS "-flat_namespace -undefined suppress")
endif()
