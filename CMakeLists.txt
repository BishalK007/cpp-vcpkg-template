cmake_minimum_required(VERSION 3.10)

# ----------------------------
# Set Default Variables
# ----------------------------

# **PROJECT_NAME**
set(PROJECT_NAME "MyProject" CACHE STRING "Name of the project")

# **EXECUTABLE_NAME**
set(EXECUTABLE_NAME "MyExecutable" CACHE STRING "Name of the executable")

# **PROJECT_VERSION**
if(NOT DEFINED PROJECT_VERSION)
    # Read version from VERSION file
    file(STRINGS "${CMAKE_SOURCE_DIR}/VERSION" PROJECT_VERSION)
endif()


# ----------------------------
# Optional: Print Configuration (Useful for Debugging)
# ----------------------------

# Display the configuration in the CMake output
message(STATUS "Initial Project Configuration:")
message(STATUS "  Project Name: ${PROJECT_NAME}")
message(STATUS "  Executable Name: ${EXECUTABLE_NAME}")
# PROJECT_VERSION will be printed after it's determined
if(NOT DEFINED PROJECT_VERSION)
    message(STATUS "Read version from VERSION file: ${PROJECT_VERSION}")
else()
    message(STATUS "Using provided PROJECT_VERSION: ${PROJECT_VERSION}")
endif()



# ----------------------------
# Option to Use Vcpkg
# ----------------------------

option(USE_VCPKG "Use Vcpkg for dependency management" ON)


# ----------------------------
# Optionally Set the Vcpkg Toolchain File
# ----------------------------

if(USE_VCPKG)
    # Specify the path to the vcpkg toolchain file
    set(CMAKE_TOOLCHAIN_FILE "${CMAKE_SOURCE_DIR}/vcpkg/scripts/buildsystems/vcpkg.cmake" CACHE STRING "Path to the vcpkg toolchain file" FORCE)
    message(STATUS "Using Vcpkg for dependency management.")
else()
    # Disable Vcpkg integration
    set(CMAKE_TOOLCHAIN_FILE "" CACHE STRING "Disable Vcpkg toolchain file" FORCE)
    set(CMAKE_DISABLE_VCPKG_INTEGRATION ON CACHE BOOL "Disable Vcpkg integration")
    message(STATUS "Not using Vcpkg. Dependencies should be provided by the system or Nix.")
endif()

# ----------------------------
# Project Configuration
# ----------------------------

project(${PROJECT_NAME} VERSION ${PROJECT_VERSION})

# Specify the C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED True)


# ----------------------------
# Source Files
# ----------------------------

# Automatically find all .cpp files in the src directory recursively
file(GLOB_RECURSE SOURCE_FILES
    "${CMAKE_SOURCE_DIR}/src/*.cpp"
)

# ----------------------------
# Package Management
# ----------------------------

# Find Packages and Components
if(USE_VCPKG)
    find_package(fmt REQUIRED)
    find_package(Boost REQUIRED COMPONENTS math)
else()
    find_package(fmt REQUIRED)
    find_package(Boost REQUIRED)
endif()

# Add any other packages your project requires

# ----------------------------
# Include Directories
# ----------------------------

# Include directories for the project
include_directories(${CMAKE_SOURCE_DIR}/include)

# Add the build directory's include directory for generated headers
include_directories(${CMAKE_BINARY_DIR}/include) 


# ----------------------------
# Generate version.hpp
# ----------------------------

# Generate version.hpp from version.hpp.in
configure_file(
    "${CMAKE_SOURCE_DIR}/include/utils/version.hpp.in"
    "${CMAKE_BINARY_DIR}/include/utils/version.hpp"
    @ONLY
)


# ----------------------------
# Add Executable
# ----------------------------

add_executable(${EXECUTABLE_NAME} ${SOURCE_FILES})


# ----------------------------
# Link Libraries
# ----------------------------

if(USE_VCPKG)
    target_link_libraries(${EXECUTABLE_NAME} PRIVATE Boost::math fmt::fmt)
else()
    target_link_libraries(${EXECUTABLE_NAME} PRIVATE Boost::boost fmt::fmt)
endif()


# ----------------------------
# Optional: Print Configuration (Useful for Debugging)
# ----------------------------

message(STATUS "Final Project Configuration:")
message(STATUS "  Project Name: ${PROJECT_NAME}")
message(STATUS "  Executable Name: ${EXECUTABLE_NAME}")
message(STATUS "  Project Version: ${PROJECT_VERSION}")
message(STATUS "  Use Vcpkg: ${USE_VCPKG}")