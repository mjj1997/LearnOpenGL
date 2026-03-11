include(cmake/SystemLink.cmake)
include(cmake/LibFuzzer.cmake)
include(CMakeDependentOption)
include(CheckCXXCompilerFlag)


include(CheckCXXSourceCompiles)


macro(LearnOpenGL_supports_sanitizers)
  # Emscripten doesn't support sanitizers
  if(EMSCRIPTEN)
    set(SUPPORTS_UBSAN OFF)
    set(SUPPORTS_ASAN OFF)
  elseif((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND NOT WIN32)

    message(STATUS "Sanity checking UndefinedBehaviorSanitizer, it should be supported on this platform")
    set(TEST_PROGRAM "int main() { return 0; }")

    # Check if UndefinedBehaviorSanitizer works at link time
    set(CMAKE_REQUIRED_FLAGS "-fsanitize=undefined")
    set(CMAKE_REQUIRED_LINK_OPTIONS "-fsanitize=undefined")
    check_cxx_source_compiles("${TEST_PROGRAM}" HAS_UBSAN_LINK_SUPPORT)

    if(HAS_UBSAN_LINK_SUPPORT)
      message(STATUS "UndefinedBehaviorSanitizer is supported at both compile and link time.")
      set(SUPPORTS_UBSAN ON)
    else()
      message(WARNING "UndefinedBehaviorSanitizer is NOT supported at link time.")
      set(SUPPORTS_UBSAN OFF)
    endif()
  else()
    set(SUPPORTS_UBSAN OFF)
  endif()

  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND WIN32)
    set(SUPPORTS_ASAN OFF)
  else()
    if (NOT WIN32)
      message(STATUS "Sanity checking AddressSanitizer, it should be supported on this platform")
      set(TEST_PROGRAM "int main() { return 0; }")

      # Check if AddressSanitizer works at link time
      set(CMAKE_REQUIRED_FLAGS "-fsanitize=address")
      set(CMAKE_REQUIRED_LINK_OPTIONS "-fsanitize=address")
      check_cxx_source_compiles("${TEST_PROGRAM}" HAS_ASAN_LINK_SUPPORT)

      if(HAS_ASAN_LINK_SUPPORT)
        message(STATUS "AddressSanitizer is supported at both compile and link time.")
        set(SUPPORTS_ASAN ON)
      else()
        message(WARNING "AddressSanitizer is NOT supported at link time.")
        set(SUPPORTS_ASAN OFF)
      endif()
    else()
      set(SUPPORTS_ASAN ON)
    endif()
  endif()
endmacro()

macro(LearnOpenGL_setup_options)
  option(LearnOpenGL_ENABLE_HARDENING "Enable hardening" ON)
  option(LearnOpenGL_ENABLE_COVERAGE "Enable coverage reporting" OFF)
  cmake_dependent_option(
    LearnOpenGL_ENABLE_GLOBAL_HARDENING
    "Attempt to push hardening options to built dependencies"
    ON
    LearnOpenGL_ENABLE_HARDENING
    OFF)

  LearnOpenGL_supports_sanitizers()

  if(NOT PROJECT_IS_TOP_LEVEL OR LearnOpenGL_PACKAGING_MAINTAINER_MODE)
    option(LearnOpenGL_ENABLE_IPO "Enable IPO/LTO" OFF)
    option(LearnOpenGL_WARNINGS_AS_ERRORS "Treat Warnings As Errors" OFF)
    option(LearnOpenGL_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" OFF)
    option(LearnOpenGL_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(LearnOpenGL_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" OFF)
    option(LearnOpenGL_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(LearnOpenGL_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(LearnOpenGL_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(LearnOpenGL_ENABLE_CLANG_TIDY "Enable clang-tidy" OFF)
    option(LearnOpenGL_ENABLE_CPPCHECK "Enable cpp-check analysis" OFF)
    option(LearnOpenGL_ENABLE_PCH "Enable precompiled headers" OFF)
    option(LearnOpenGL_ENABLE_CACHE "Enable ccache" OFF)
  else()
    option(LearnOpenGL_ENABLE_IPO "Enable IPO/LTO" ON)
    option(LearnOpenGL_WARNINGS_AS_ERRORS "Treat Warnings As Errors" ON)
    option(LearnOpenGL_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" ${SUPPORTS_ASAN})
    option(LearnOpenGL_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(LearnOpenGL_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" ${SUPPORTS_UBSAN})
    option(LearnOpenGL_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(LearnOpenGL_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(LearnOpenGL_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(LearnOpenGL_ENABLE_CLANG_TIDY "Enable clang-tidy" ON)
    option(LearnOpenGL_ENABLE_CPPCHECK "Enable cpp-check analysis" ON)
    option(LearnOpenGL_ENABLE_PCH "Enable precompiled headers" OFF)
    option(LearnOpenGL_ENABLE_CACHE "Enable ccache" ON)
  endif()

  if(NOT PROJECT_IS_TOP_LEVEL)
    mark_as_advanced(
      LearnOpenGL_ENABLE_IPO
      LearnOpenGL_WARNINGS_AS_ERRORS
      LearnOpenGL_ENABLE_SANITIZER_ADDRESS
      LearnOpenGL_ENABLE_SANITIZER_LEAK
      LearnOpenGL_ENABLE_SANITIZER_UNDEFINED
      LearnOpenGL_ENABLE_SANITIZER_THREAD
      LearnOpenGL_ENABLE_SANITIZER_MEMORY
      LearnOpenGL_ENABLE_UNITY_BUILD
      LearnOpenGL_ENABLE_CLANG_TIDY
      LearnOpenGL_ENABLE_CPPCHECK
      LearnOpenGL_ENABLE_COVERAGE
      LearnOpenGL_ENABLE_PCH
      LearnOpenGL_ENABLE_CACHE)
  endif()

  LearnOpenGL_check_libfuzzer_support(LIBFUZZER_SUPPORTED)
  if(LIBFUZZER_SUPPORTED AND (LearnOpenGL_ENABLE_SANITIZER_ADDRESS OR LearnOpenGL_ENABLE_SANITIZER_THREAD OR LearnOpenGL_ENABLE_SANITIZER_UNDEFINED))
    set(DEFAULT_FUZZER ON)
  else()
    set(DEFAULT_FUZZER OFF)
  endif()

  option(LearnOpenGL_BUILD_FUZZ_TESTS "Enable fuzz testing executable" ${DEFAULT_FUZZER})

endmacro()

macro(LearnOpenGL_global_options)
  if(LearnOpenGL_ENABLE_IPO)
    include(cmake/InterproceduralOptimization.cmake)
    LearnOpenGL_enable_ipo()
  endif()

  LearnOpenGL_supports_sanitizers()

  if(LearnOpenGL_ENABLE_HARDENING AND LearnOpenGL_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR LearnOpenGL_ENABLE_SANITIZER_UNDEFINED
       OR LearnOpenGL_ENABLE_SANITIZER_ADDRESS
       OR LearnOpenGL_ENABLE_SANITIZER_THREAD
       OR LearnOpenGL_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    message("${LearnOpenGL_ENABLE_HARDENING} ${ENABLE_UBSAN_MINIMAL_RUNTIME} ${LearnOpenGL_ENABLE_SANITIZER_UNDEFINED}")
    LearnOpenGL_enable_hardening(LearnOpenGL_options ON ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()
endmacro()

macro(LearnOpenGL_local_options)
  if(PROJECT_IS_TOP_LEVEL)
    include(cmake/StandardProjectSettings.cmake)
  endif()

  add_library(LearnOpenGL_warnings INTERFACE)
  add_library(LearnOpenGL_options INTERFACE)

  include(cmake/CompilerWarnings.cmake)
  LearnOpenGL_set_project_warnings(
    LearnOpenGL_warnings
    ${LearnOpenGL_WARNINGS_AS_ERRORS}
    ""
    ""
    ""
    "")

  include(cmake/Linker.cmake)
  # Must configure each target with linker options, we're avoiding setting it globally for now

  if(NOT EMSCRIPTEN)
    include(cmake/Sanitizers.cmake)
    LearnOpenGL_enable_sanitizers(
      LearnOpenGL_options
      ${LearnOpenGL_ENABLE_SANITIZER_ADDRESS}
      ${LearnOpenGL_ENABLE_SANITIZER_LEAK}
      ${LearnOpenGL_ENABLE_SANITIZER_UNDEFINED}
      ${LearnOpenGL_ENABLE_SANITIZER_THREAD}
      ${LearnOpenGL_ENABLE_SANITIZER_MEMORY})
  endif()

  set_target_properties(LearnOpenGL_options PROPERTIES UNITY_BUILD ${LearnOpenGL_ENABLE_UNITY_BUILD})

  if(LearnOpenGL_ENABLE_PCH)
    target_precompile_headers(
      LearnOpenGL_options
      INTERFACE
      <vector>
      <string>
      <utility>)
  endif()

  if(LearnOpenGL_ENABLE_CACHE)
    include(cmake/Cache.cmake)
    LearnOpenGL_enable_cache()
  endif()

  include(cmake/StaticAnalyzers.cmake)
  if(LearnOpenGL_ENABLE_CLANG_TIDY)
    LearnOpenGL_enable_clang_tidy(LearnOpenGL_options ${LearnOpenGL_WARNINGS_AS_ERRORS})
  endif()

  if(LearnOpenGL_ENABLE_CPPCHECK)
    LearnOpenGL_enable_cppcheck(${LearnOpenGL_WARNINGS_AS_ERRORS} "" # override cppcheck options
    )
  endif()

  if(LearnOpenGL_ENABLE_COVERAGE)
    include(cmake/Tests.cmake)
    LearnOpenGL_enable_coverage(LearnOpenGL_options)
  endif()

  if(LearnOpenGL_WARNINGS_AS_ERRORS)
    check_cxx_compiler_flag("-Wl,--fatal-warnings" LINKER_FATAL_WARNINGS)
    if(LINKER_FATAL_WARNINGS)
      # This is not working consistently, so disabling for now
      # target_link_options(LearnOpenGL_options INTERFACE -Wl,--fatal-warnings)
    endif()
  endif()

  if(LearnOpenGL_ENABLE_HARDENING AND NOT LearnOpenGL_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR LearnOpenGL_ENABLE_SANITIZER_UNDEFINED
       OR LearnOpenGL_ENABLE_SANITIZER_ADDRESS
       OR LearnOpenGL_ENABLE_SANITIZER_THREAD
       OR LearnOpenGL_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    LearnOpenGL_enable_hardening(LearnOpenGL_options OFF ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()

endmacro()
