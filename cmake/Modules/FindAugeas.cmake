# Finds augeas and its libraries
# Uses the same semantics as pkg_check_modules, i.e. LIBAUGEAS{_FOUND,_INCLUDE_DIR,_LIBRARIES}
#
# This is an adapted version of FindSystemd.cmake: 
# Copyright: Red Hat, Inc. 2013
# Author: Martin Briza <mbriza@redhat.com>
#
# Distributed under the BSD license. See COPYING-CMAKE-SCRIPTS for details.

if (LIBAUGEAS_INCLUDE_DIR)
  # in cache already
  set (LIBAUGEAS_FOUND TRUE)
else (LIBAUGEAS_INCLUDE_DIR)

  # try to find libaugeas via pkg-config
  find_package(PkgConfig)

  if (PKG_CONFIG_FOUND)
    pkg_check_modules(_LIBAUGEAS_PC QUIET "libaugeas")
  endif (PKG_CONFIG_FOUND)

  find_path (LIBAUGEAS_INCLUDE_DIR augeas.h
    ${_LIBAUGEAS_PC_INCLUDE_DIRS}
    /usr/include
    /usr/local/include
  )

  find_library (LIBAUGEAS_LIBRARIES NAMES augeas
    PATHS
    ${_LIBAUGEAS_PC_LIBDIR}
  )

  if (LIBAUGEAS_INCLUDE_DIR AND LIBAUGEAS_LIBRARIES)
    set (LIBAUGEAS_FOUND TRUE)
  endif (LIBAUGEAS_INCLUDE_DIR AND LIBAUGEAS_LIBRARIES)

  if (LIBAUGEAS_FOUND)
    if (NOT LIBAUGEAS_FIND_QUIETLY)
      message(STATUS "Found augeas: ${LIBAUGEAS_LIBRARIES}")
    endif (NOT LIBAUGEAS_FIND_QUIETLY)
  else (LIBAUGEAS_FOUND)
    if (LIBAUGEAS_FIND_REQUIRED)
      message(FATAL_ERROR "Could NOT find augeas")
    endif (LIBAUGEAS_FIND_REQUIRED)
  endif (LIBAUGEAS_FOUND)

  mark_as_advanced(LIBAUGEAS_INCLUDE_DIR LIBAUGEAS_LIBRARIES)

endif (LIBAUGEAS_INCLUDE_DIR)
