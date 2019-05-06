# Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
# file Copyright.txt or https://cmake.org/licensing for details.

#[=======================================================================[.rst:
FindNuGetGTest
-----------

Find the GoogleTest from NuGet repository.

Imported Targets
^^^^^^^^^^^^^^^^

This module defines two :ref:`Imported Targets <Imported Targets>`.

``NuGetGTest::GTest``

``NuGetGTest::Main ``

Result Variables
^^^^^^^^^^^^^^^^

This module will set the following variable in your project
(see :ref:`Standard Variable Names <CMake Developer Standard Variable Names>`):

``NUGET_GTEST_FOUND``
  System has the NuGet GoogleTest package.

Hints
^^^^^

``NUGET_PACKAGES_DIR``
  Define the root directory of NuGet packages.

#]=======================================================================]

cmake_minimum_required(VERSION 3.12)

# define variables for NuGet package of GoogleTest.
if(NOT NUGET_PACKAGES_DIR)
  set(NUGET_PACKAGES_DIR ${CMAKE_CURRENT_SOURCE_DIR}/packages)
endif()
set(NuGet_GTest_Name		Microsoft.googletest)
set(NuGet_GTest_Id			Microsoft.googletest.v140.windesktop.msvcstl.static.rt-static)
set(NuGet_GTest_Version		1.8.0)
set(NuGet_GTest_Framework	native)
set(NuGet_GTest_Root		${NUGET_PACKAGES_DIR}/${NuGet_GTest_Id}.${NuGet_GTest_Version})

# find a NuGet.targets in the standard native NuGet package structure.
find_path(GTEST_TARGET ${NuGet_GTest_Id}.targets
              HINTS ${NuGet_GTest_Root}
      PATH_SUFFIXES /build/${NuGet_GTest_Framework})

find_package(PackageHandleStandardArgs QUIET)
find_package_handle_standard_args(NuGet_GTest
                                  REQUIRED_VARS	GTEST_TARGET)

add_library (NuGetGTest::GTest STATIC IMPORTED)
add_library (NuGetGTest::Main  STATIC IMPORTED)
set_target_properties (NuGetGTest::GTest NuGetGTest::Main PROPERTIES
	IMPORTED_LOCATION "${NuGet_GTest_Root}/build/${NuGet_GTest_Framework}/${NuGet_GTest_Id}.targets"
	INTERFACE_COMPILE_DEFINITIONS _SILENCE_TR1_NAMESPACE_DEPRECATION_WARNING
)
target_link_libraries (NuGetGTest::Main INTERFACE NuGetGTest::GTest)
