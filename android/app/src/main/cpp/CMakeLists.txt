cmake_minimum_required(VERSION 3.22.1)

project(inference LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

set(LLM_GPU_BACKEND "CPU" CACHE STRING "GPU backend to build into llama.cpp")
set_property(CACHE LLM_GPU_BACKEND PROPERTY STRINGS CPU OPENCL VULKAN)

file(REAL_PATH ${CMAKE_CURRENT_LIST_DIR}/../../../../../third_party/llama.cpp LLAMA_ROOT)
file(REAL_PATH ${CMAKE_CURRENT_LIST_DIR}/../../../../../third_party/OpenCL-Headers OPENCL_HEADERS_ROOT)
file(REAL_PATH ${CMAKE_CURRENT_LIST_DIR}/../../../../../third_party/OpenCL-ICD-Loader OPENCL_ROOT)

set(GGML_OPENMP OFF CACHE BOOL "" FORCE)
set(GGML_LLAMAFILE OFF CACHE BOOL "" FORCE)
set(BUILD_SHARED_LIBS ON CACHE BOOL "" FORCE)

if (LLM_GPU_BACKEND STREQUAL "VULKAN")
    set(GGML_VULKAN ON CACHE BOOL "" FORCE)
    set(GGML_OPENCL OFF CACHE BOOL "" FORCE)
elseif (LLM_GPU_BACKEND STREQUAL "OPENCL")
    set(GGML_VULKAN OFF CACHE BOOL "" FORCE)
    set(GGML_OPENCL ON CACHE BOOL "" FORCE)
else()
    set(GGML_VULKAN OFF CACHE BOOL "" FORCE)
    set(GGML_OPENCL OFF CACHE BOOL "" FORCE)
endif()

if (EXISTS ${LLAMA_ROOT}/CMakeLists.txt)
    add_subdirectory(${LLAMA_ROOT} third_party/llama.cpp)
endif()

if (EXISTS ${OPENCL_ROOT}/CMakeLists.txt)
    set(OPENCL_ICD_LOADER_HEADERS_DIR ${OPENCL_HEADERS_ROOT} CACHE PATH "Path to OpenCL headers" FORCE)
    add_subdirectory(${OPENCL_ROOT} third_party/OpenCL-ICD-Loader)
elseif (NOT TARGET OpenCL)
    add_library(OpenCL INTERFACE)
endif()

add_library(inference SHARED inference.cpp)
target_include_directories(inference PRIVATE
  ${CMAKE_CURRENT_LIST_DIR}
  ${LLAMA_ROOT}/include
  ${LLAMA_ROOT}/ggml/include
  ${LLAMA_ROOT}/common
)
target_link_libraries(inference PRIVATE llama)
if (TARGET OpenCL)
    target_link_libraries(inference PRIVATE OpenCL)
endif()