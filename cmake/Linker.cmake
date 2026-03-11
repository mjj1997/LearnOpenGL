macro(LearnOpenGL_configure_linker project_name)
  set(LearnOpenGL_USER_LINKER_OPTION
    "DEFAULT"
      CACHE STRING "Linker to be used")
    set(LearnOpenGL_USER_LINKER_OPTION_VALUES "DEFAULT" "SYSTEM" "LLD" "GOLD" "BFD" "MOLD" "SOLD" "APPLE_CLASSIC" "MSVC")
  set_property(CACHE LearnOpenGL_USER_LINKER_OPTION PROPERTY STRINGS ${LearnOpenGL_USER_LINKER_OPTION_VALUES})
  list(
    FIND
    LearnOpenGL_USER_LINKER_OPTION_VALUES
    ${LearnOpenGL_USER_LINKER_OPTION}
    LearnOpenGL_USER_LINKER_OPTION_INDEX)

  if(${LearnOpenGL_USER_LINKER_OPTION_INDEX} EQUAL -1)
    message(
      STATUS
        "Using custom linker: '${LearnOpenGL_USER_LINKER_OPTION}', explicitly supported entries are ${LearnOpenGL_USER_LINKER_OPTION_VALUES}")
  endif()

  set_target_properties(${project_name} PROPERTIES LINKER_TYPE "${LearnOpenGL_USER_LINKER_OPTION}")
endmacro()
