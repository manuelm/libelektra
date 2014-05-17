include (${SWIG_USE_FILE})
include(LibAddMacros)

find_package (PythonInterp 3 REQUIRED)
find_package (PythonLibs 3 REQUIRED)

add_headers (HDR_FILES)
add_cppheaders (HDR_FILES)

include_directories (${PYTHON_INCLUDE_PATH})
include_directories (${CMAKE_CURRENT_SOURCE_DIR})

set (CMAKE_SWIG_OUTDIR ${CMAKE_CURRENT_BINARY_DIR})
set (CMAKE_SWIG_FLAGS "-O")

set_source_files_properties (../kdb.i PROPERTIES CPLUSPLUS ON)
set_source_files_properties (../kdb.i PROPERTIES SWIG_FLAGS "-py3;-extranative")
swig_add_module (kdb python ../kdb.i)
swig_link_libraries(kdb elektra ${PYTHON_LIBRARIES})

set (PYTHON_GET_MODULES_DIR_COMMAND "from distutils import sysconfig; print(sysconfig.get_python_lib(True, False))")
execute_process (COMMAND ${PYTHON_EXECUTABLE} -c "${PYTHON_GET_MODULES_DIR_COMMAND}" OUTPUT_VARIABLE PYTHON_SITE_PACKAGES OUTPUT_STRIP_TRAILING_WHITESPACE)

install (
	FILES ${CMAKE_CURRENT_BINARY_DIR}/kdb.py
	DESTINATION ${PYTHON_SITE_PACKAGES}
)

INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR})
INCLUDE_DIRECTORIES(${CMAKE_SOURCE_DIR}/src/swig/)
