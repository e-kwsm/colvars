# General build script suitable for cross-platform CI tests

get_filename_component(COLVARS_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR} DIRECTORY)

set(COLVARS_LEPTON ON)
if(NOT DEFINED CMAKE_CXX_STANDARD)
  set(CMAKE_CXX_STANDARD 11)
else()
  if(${CMAKE_CXX_STANDARD} GREATER 70)
    set(COLVARS_LEPTON OFF)
  endif()
endif()

if(DEFINED CMAKE_SYSTEM_NAME)

  # Download OS-specific pre-built TCL

  if(${CMAKE_SYSTEM_NAME} STREQUAL "Linux")
    file(DOWNLOAD
      "https://www.ks.uiuc.edu/Research/namd/libraries/tcl8.5.9-linux-x86_64.tar.gz"
      ./tcl.tar.gz SHOW_PROGRESS)
    execute_process(COMMAND ${CMAKE_COMMAND} -E tar xvf ./tcl.tar.gz)
    set(DEFINE_TCL_DIR "-DTCL_DIR=${COLVARS_SOURCE_DIR}/tcl8.5.9-linux-x86_64")
    set(DEFINE_TCL_LIBRARY "-DTCL_LIBRARY=tcl8.5")
  endif()

  if(${CMAKE_SYSTEM_NAME} STREQUAL "Windows")
    file(DOWNLOAD
      "https://www.ks.uiuc.edu/Research/namd/libraries/tcl8.5.9-win64.zip"
      ./tcl.zip SHOW_PROGRESS)
    execute_process(COMMAND ${CMAKE_COMMAND} -E tar xvf ./tcl.zip)
    set(DEFINE_TCL_DIR "-DTCL_DIR=${COLVARS_SOURCE_DIR}/tcl8.5.9-win64")
    set(DEFINE_TCL_LIBRARY "-DTCL_LIBRARY=tcl8.5")
  endif()

endif()

if(NOT DEFINED LEPTON_DIR)
  set(LEPTON_DIR "${COLVARS_SOURCE_DIR}/openmm-source/libraries/lepton")
  if(NOT EXISTS ${LEPTON_DIR})
    execute_process(COMMAND git clone --depth=1 https://github.com/openmm/openmm.git "${COLVARS_SOURCE_DIR}/openmm-source")
  endif()
  message(STATUS "Using Lepton library from: ${LEPTON_DIR}")
endif()

# Many compilers test
if(DEFINED ENV{CXX_VERSION})
  set(BUILD_DIR build_$ENV{CXX}$ENV{CXX_VERSION}_C++${CMAKE_CXX_STANDARD})
else()
  set(BUILD_DIR build)
endif()

if(DEFINED ENV{CCACHE})
  set(DEFINE_CC_CCACHE "-DCMAKE_C_COMPILER_LAUNCHER=$ENV{CCACHE}")
  set(DEFINE_CXX_CCACHE "-DCMAKE_CXX_COMPILER_LAUNCHER=$ENV{CCACHE}")
endif()

execute_process(
  COMMAND ${CMAKE_COMMAND}
  -S cmake
  -B ${BUILD_DIR}
  -D CMAKE_BUILD_TYPE=RelWithDebinfo
  -D WARNINGS_ARE_ERRORS=ON
  -D CMAKE_VERBOSE_MAKEFILE=ON
  -D CMAKE_CXX_STANDARD=${CMAKE_CXX_STANDARD}
  ${DEFINE_CC_CCACHE}
  ${DEFINE_CXX_CCACHE}
  -D COLVARS_TCL=ON
  ${DEFINE_TCL_DIR}
  ${DEFINE_TCL_LIBRARY}
  -D COLVARS_LEPTON=${COLVARS_LEPTON}
  -D LEPTON_DIR=${LEPTON_DIR}
  RESULT_VARIABLE result
  )

if(NOT result EQUAL 0)
  message(FATAL_ERROR "Error generating CMake buildsystem.")
endif()

execute_process(
  COMMAND ${CMAKE_COMMAND}
  --build ${BUILD_DIR}
  --parallel
  RESULT_VARIABLE result
  )

if(NOT result EQUAL 0)
  message(FATAL_ERROR "Error building library.")
endif()
