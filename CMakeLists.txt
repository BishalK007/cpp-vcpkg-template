cmake_minimum_required(VERSION 3.10)

# ----------------------------
# Set Toolchain File
# ----------------------------
# Specify the path to the vcpkg toolchain file
set(CMAKE_TOOLCHAIN_FILE "${CMAKE_SOURCE_DIR}/vcpkg/scripts/buildsystems/vcpkg.cmake" CACHE STRING "Path to the vcpkg toolchain file")

# ----------------------------
# Set Default Variables
# ----------------------------

# **PROJECT_NAME**
set(PROJECT_NAME "MyProject" CACHE STRING "Name of the project")

# **EXECUTABLE_NAME**
set(EXECUTABLE_NAME "MyExecutable" CACHE STRING "Name of the executable")

# **PROJECT_VERSION**
set(PROJECT_VERSION "1.0" CACHE STRING "Version of Project")


# **SOURCE_FILES**
# Automatically find all .cpp files in the src directory recursively
# Automatically find all .cpp files in the src directory recursively
file(GLOB_RECURSE SOURCE_FILES
    "${CMAKE_SOURCE_DIR}/src/*.cpp"
)
# set(SOURCE_FILES src/main.cpp src/math/math.cpp src/util/util.cpp)

# ----------------------------
# Project Configuration
# ----------------------------

# Set the project name and version (optional)
project(${PROJECT_NAME} VERSION ${PROJECT_VERSION})

# Specify the C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED True)

# ----------------------------
# Package Management
# ----------------------------

# Find Packages and Components
find_package(Boost REQUIRED COMPONENTS math)
find_package(fmt REQUIRED)

# ----------------------------
# Include Directories
# ----------------------------

# Include directories for the project
include_directories(${CMAKE_SOURCE_DIR}/include)

# ----------------------------
# Add Executable
# ----------------------------

# Add the executable with the specified source files
add_executable(${EXECUTABLE_NAME} ${SOURCE_FILES})

# ----------------------------
# Link Libraries
# ----------------------------

# Link Boost::math and fmt::fmt to the executable
target_link_libraries(${EXECUTABLE_NAME} PRIVATE Boost::math fmt::fmt)

# ----------------------------
# Optional: Print Configuration (Useful for Debugging)
# ----------------------------

# Display the configuration in the CMake output
message(STATUS "Project Name: ${PROJECT_NAME}")
message(STATUS "Executable Name: ${EXECUTABLE_NAME}")
message(STATUS "Source Files: ${SOURCE_FILES}")
