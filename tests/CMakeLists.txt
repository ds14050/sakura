cmake_minimum_required(VERSION 3.6)
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_CURRENT_LIST_DIR}/../cmake)
include(${CMAKE_SOURCE_DIR}/runtime.cmake)

project (sakura-unittest)

option(BUILD_GTEST "Build GoogleTest." OFF)
option(BUILD_SHARED_LIBS "Build shared libraries (DLLs)." OFF)

# switch DLL or static libary by specifying by command line
set (LIB_TYPE STATIC)
if (BUILD_SHARED_LIBS)
  # User wants to build Dynamic Libraries, so change the LIB_TYPE variable to CMake keyword 'SHARED'
  set (LIB_TYPE SHARED)
endif (BUILD_SHARED_LIBS)

# set Target Directories
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

if (NOT BUILD_GTEST)
	if (MSVC)
		find_package (NuGetGTest)
		set (GTEST      NuGetGTest::GTest)
		set (GTEST_MAIN NuGetGTest::Main)
	else()
		find_package (GTest)
		set (GTEST      GTest::GTest)
		set (GTEST_MAIN GTest::Main)
	endif()
endif()
if (NOT NUGET_GTEST_FOUND AND NOT GTEST_FOUND)
	set (BUILD_GTEST ON)
endif()
if (BUILD_GTEST)
	add_subdirectory (googletest)
	set (GTEST      gtest)
	set (GTEST_MAIN gtest_main)
endif()
add_subdirectory(unittests)

# turn on solution folder
set_property(GLOBAL PROPERTY USE_FOLDERS ON)

# create solution folder
set_target_properties(${GTEST}      PROPERTIES FOLDER GoogleTest)
set_target_properties(${GTEST_MAIN} PROPERTIES FOLDER GoogleTest)
set_target_properties(tests1        PROPERTIES FOLDER Tests)

# specify startup project
set_property(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY VS_STARTUP_PROJECT tests1)

# enable testing
enable_testing()

# add test
add_test(NAME unitTest1 COMMAND tests1)
