include(LLVMParseArguments)
include(LLVMProcessSources)
include(LLVM-Config)

option(BUILD_OBJECT_LIBS "Use object libraries instead of static ones (Enables MSVC to link dynamically)" OFF)

if (BUILD_OBJECT_LIBS)


function(resolve_indirect _varname)
  set(_libs ${ARGN})
message("Search indirect: ${_libs}")
  set(${_varname} PARENT_SCOPE)
  set(_done)
  list(LENGTH _libs _len)
  while( _len GREATER 0 )
    list(GET _libs 0 _front)
    list(REMOVE_AT _libs 0)
    
    get_target_property(${_front} _libdeps "INDIRECT_DEPS")
    list(APPEND _done ${_front})
#message("Found indirect: ${_libdeps}")
    
    foreach ( _libdep in LISTS _libdeps )
      list(FIND _done ${_libdep} _found)
      if (NOT _found)
        list(APPEND ${_varname} ${_libdep})
        list(APPEND _libs ${_libdep})
      endif ()
    endforeach ()
    list(LENGTH _libs _len)
  endwhile ()
message("Search indirect: ${${_varname}}")
endfunction ()


function(resolve_libs _lib_objects_name _lib_static_name _link_libs _link_components _indirect )
  explicit_map_components_to_libraries(_resolved_components ${_link_components})
message("_resolved_components: ${_resolved_components}")

  set(_indirect_libs)
  if (_indirect)
    resolve_indirect(_indirect_libs ${_link_libs} ${_resolved_components})
  endif ()

  set(${_lib_objects_name} PARENT_SCOPE)
  set(${_lib_static_name} PARENT_SCOPE)
  foreach(_lib IN LISTS _link_libs _resolved_components _indirect_libs)
    get_target_property(_target_type ${_lib} "TYPE")
    
    if (_target_type STREQUAL "OBJECT_LIBRARY")
message("_OBJECT_LIBRARY: ${_lib}")
      list(APPEND ${_lib_objects_name} $<TARGET_OBJECTS:${_lib}>)
    else ()
message("${_target_type}: ${_lib}")
       list(APPEND ${_lib_static_name} ${_lib})
    endif ()
  endforeach ()
  set(${_lib_objects_name} ${${_lib_objects_name}} PARENT_SCOPE)
  set(${_lib_static_name} ${${_lib_static_name}} PARENT_SCOPE)
endfunction()




function(add_llvm_library name)
  parse_arguments(PARM "LINK_LIBS" "EXCLUDE_FROM_ALL;MODULE;SHARED;STATIC" ${ARGN})
#message("DEFARG: ${PARM_DEFAULT_ARGS}")
  llvm_process_sources( ALL_FILES ${PARM_DEFAULT_ARGS} )
  
  if (PARM_MODULE)
    resolve_libs( _lib_objects _lib_static "${PARM_LINK_LIBS}" "${LLVM_LINK_COMPONENTS}" TRUE )
    add_library( ${name} MODULE ${ALL_FILES} ${_lib_objects} )
  elseif (PARM_SHARED)
    resolve_libs( _lib_objects _lib_static "${PARM_LINK_LIBS}" "${LLVM_LINK_COMPONENTS}" TRUE )
    add_library( ${name} SHARED ${ALL_FILES} ${_lib_objects} )
    target_link_libraries(${name} ${_lib_static})
  elseif (BUILD_OBJECT_LIBS)
message("${name}: libs=${PARM_LINK_LIBS} comps=${LLVM_LINK_COMPONENTS}")
    resolve_libs( _lib_objects _lib_static "${PARM_LINK_LIBS}" "${LLVM_LINK_COMPONENTS}" FALSE )
message("${name}: obj=${_lib_objects} stat=${_lib_static}")
#message("OBJECTLIB: ${name}=${ALL_FILES}")
    add_library( ${name} OBJECT ${ALL_FILES} )
    set_property(TARGET ${name} PROPERTY "INDIRECT_DEPS" ${_lib_objects} ${_lib_static})
    message("Set indirect: ${name}->${_lib_objects} ${_lib_static}")
  elseif (PARM_STATIC)
    resolve_libs( _lib_objects _lib_static "${PARM_LINK_LIBS}" "${LLVM_LINK_COMPONENTS}" TRUE )
    add_library( ${name} STATIC ${ALL_FILES} )
    target_link_libraries(${name} ${_lib_static})
  else()
    # STATIC OR SHARED
    resolve_libs( _lib_objects _lib_static "${PARM_LINK_LIBS}" "${LLVM_LINK_COMPONENTS}" TRUE )
    add_library( ${name} STATIC ${ALL_FILES} )
    target_link_libraries(${name} ${_lib_static})
  endif()

  if( LLVM_COMMON_DEPENDS )
    add_dependencies( ${name} ${LLVM_COMMON_DEPENDS} )
  endif( LLVM_COMMON_DEPENDS )

  set_property( GLOBAL APPEND PROPERTY LLVM_LIBS ${name} )
  set_target_properties(${name} PROPERTIES FOLDER "Libraries")
endfunction(add_llvm_library name)

macro (add_llvm_executable name)
  parse_arguments(PARM "LINK_LIBS" "EXCLUDE_FROM_ALL" ${ARGN})
  llvm_process_sources( ALL_FILES ${PARM_DEFAULT_ARGS} )
  
  resolve_libs(_lib_objects _lib_static "${PARM_LINK_LIBS}" "${LLVM_LINK_COMPONENTS}" TRUE)

  if (PARM_EXCLUDE_FROM_ALL OR EXCLUDE_FROM_ALL)
    add_executable(${name} EXCLUDE_FROM_ALL ${ALL_FILES} ${_lib_objects})
  else ()
    add_executable(${name} ${ALL_FILES} ${_lib_objects})
  endif ()
  set(EXCLUDE_FROM_ALL OFF)
  #llvm_config( ${name} ${LLVM_LINK_COMPONENTS} )
  if( LLVM_COMMON_DEPENDS )
    add_dependencies( ${name} ${LLVM_COMMON_DEPENDS} )
  endif( LLVM_COMMON_DEPENDS )
  target_link_libraries(${name} ${_lib_static})
endmacro (add_llvm_executable)


else (BUILD_OBJECT_LIBS)


macro(add_llvm_library name)
  llvm_process_sources( ALL_FILES ${ARGN} )
  add_library( ${name} ${ALL_FILES} )
  set_property( GLOBAL APPEND PROPERTY LLVM_LIBS ${name} )
  if( LLVM_COMMON_DEPENDS )
    add_dependencies( ${name} ${LLVM_COMMON_DEPENDS} )
  endif( LLVM_COMMON_DEPENDS )

  if( BUILD_SHARED_LIBS )
    llvm_config( ${name} ${LLVM_LINK_COMPONENTS} )
  endif()

  # Ensure that the system libraries always comes last on the
  # list. Without this, linking the unit tests on MinGW fails.
  link_system_libs( ${name} )

  if( EXCLUDE_FROM_ALL )
    set_target_properties( ${name} PROPERTIES EXCLUDE_FROM_ALL ON)
  else()
    install(TARGETS ${name}
      LIBRARY DESTINATION lib${LLVM_LIBDIR_SUFFIX}
      ARCHIVE DESTINATION lib${LLVM_LIBDIR_SUFFIX})
  endif()
  set_target_properties(${name} PROPERTIES FOLDER "Libraries")

  # Add the explicit dependency information for this library.
  #
  # It would be nice to verify that we have the dependencies for this library
  # name, but using get_property(... SET) doesn't suffice to determine if a
  # property has been set to an empty value.
  get_property(lib_deps GLOBAL PROPERTY LLVMBUILD_LIB_DEPS_${name})
  target_link_libraries(${name} ${lib_deps})
endmacro(add_llvm_library name)

macro(add_llvm_executable name)
  parse_arguments(PARM "LINK_LIBS" "EXCLUDE_FROM_ALL" ${ARGN})
  llvm_process_sources( ALL_FILES ${PARM_DEFAULT_ARGS} )
  if( PARM_EXCLUDE_FROM_ALL OR EXCLUDE_FROM_ALL )
    add_executable(${name} EXCLUDE_FROM_ALL ${ALL_FILES})
  else()
    add_executable(${name} ${ALL_FILES})
  endif()
  set(EXCLUDE_FROM_ALL OFF)
  llvm_config( ${name} ${LLVM_LINK_COMPONENTS} )
  if( LLVM_COMMON_DEPENDS )
    add_dependencies( ${name} ${LLVM_COMMON_DEPENDS} )
  endif( LLVM_COMMON_DEPENDS )
  link_system_libs( ${name} )
  target_link_libraries(${name} ${PARM_LINK_LIBS})
endmacro(add_llvm_executable name)


endif (BUILD_OBJECT_LIBS)



macro(add_llvm_loadable_module name)
  if( NOT LLVM_ON_UNIX OR CYGWIN )
    message(STATUS "Loadable modules not supported on this platform.
${name} ignored.")
    # Add empty "phony" target
    add_custom_target(${name})
  else()
    llvm_process_sources( ALL_FILES ${ARGN} )
    if (MODULE)
      set(libkind MODULE)
    else()
      set(libkind SHARED)
    endif()

    add_library( ${name} ${libkind} ${ALL_FILES} )
    set_target_properties( ${name} PROPERTIES PREFIX "" )

    llvm_config( ${name} ${LLVM_LINK_COMPONENTS} )
    link_system_libs( ${name} )

    if (APPLE)
      # Darwin-specific linker flags for loadable modules.
      set_target_properties(${name} PROPERTIES
        LINK_FLAGS "-Wl,-flat_namespace -Wl,-undefined -Wl,suppress")
    endif()

    if( EXCLUDE_FROM_ALL )
      set_target_properties( ${name} PROPERTIES EXCLUDE_FROM_ALL ON)
    else()
      install(TARGETS ${name}
        LIBRARY DESTINATION lib${LLVM_LIBDIR_SUFFIX}
        ARCHIVE DESTINATION lib${LLVM_LIBDIR_SUFFIX})
    endif()
  endif()

  set_target_properties(${name} PROPERTIES FOLDER "Loadable modules")
endmacro(add_llvm_loadable_module name)


macro(add_llvm_tool name)
  set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${LLVM_TOOLS_BINARY_DIR})
  if( NOT LLVM_BUILD_TOOLS )
    set(EXCLUDE_FROM_ALL ON)
  endif()
  add_llvm_executable(${name} ${ARGN})
  if( LLVM_BUILD_TOOLS )
    install(TARGETS ${name} RUNTIME DESTINATION bin)
  endif()
  set_target_properties(${name} PROPERTIES FOLDER "Tools")
endmacro(add_llvm_tool name)


macro(add_llvm_example name)
#  set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${LLVM_EXAMPLES_BINARY_DIR})
  if( NOT LLVM_BUILD_EXAMPLES )
    set(EXCLUDE_FROM_ALL ON)
  endif()
  add_llvm_executable(${name} ${ARGN})
  if( LLVM_BUILD_EXAMPLES )
    install(TARGETS ${name} RUNTIME DESTINATION examples)
  endif()
  set_target_properties(${name} PROPERTIES FOLDER "Examples")
endmacro(add_llvm_example name)


macro(add_llvm_utility name)
  add_llvm_executable(${name} ${ARGN})
  set_target_properties(${name} PROPERTIES FOLDER "Utils")
endmacro(add_llvm_utility name)


macro(add_llvm_target target_name)
  include_directories(BEFORE
    ${CMAKE_CURRENT_BINARY_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR})
  add_llvm_library(LLVM${target_name} ${ARGN} ${TABLEGEN_OUTPUT})
  set( CURRENT_LLVM_TARGET LLVM${target_name} )
endmacro(add_llvm_target)

# Add external project that may want to be built as part of llvm such as Clang,
# lld, and Polly. This adds two options. One for the source directory of the
# project, which defaults to ${CMAKE_CURRENT_SOURCE_DIR}/${name}. Another to
# enable or disable building it with everthing else.
# Additional parameter can be specified as the name of directory.
macro(add_llvm_external_project name)
  set(add_llvm_external_dir "${ARGN}")
  if("${add_llvm_external_dir}" STREQUAL "")
    set(add_llvm_external_dir ${name})
  endif()
  string(REPLACE "-" "_" nameUNDERSCORE ${name})
  string(TOUPPER ${nameUNDERSCORE} nameUPPER)
  set(LLVM_EXTERNAL_${nameUPPER}_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/${add_llvm_external_dir}"
      CACHE PATH "Path to ${name} source directory")
  if (NOT ${LLVM_EXTERNAL_${nameUPPER}_SOURCE_DIR} STREQUAL ""
      AND EXISTS ${LLVM_EXTERNAL_${nameUPPER}_SOURCE_DIR}/CMakeLists.txt)
    option(LLVM_EXTERNAL_${nameUPPER}_BUILD
           "Whether to build ${name} as part of LLVM" ON)
    if (LLVM_EXTERNAL_${nameUPPER}_BUILD)
      add_subdirectory(${LLVM_EXTERNAL_${nameUPPER}_SOURCE_DIR} ${add_llvm_external_dir})
    endif()
  endif()
endmacro(add_llvm_external_project)

# Generic support for adding a unittest.
function(add_unittest test_suite test_name)
  set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})
  if( NOT LLVM_BUILD_TESTS )
    set(EXCLUDE_FROM_ALL ON)
  endif()

  add_llvm_executable(${test_name} ${ARGN})
  target_link_libraries(${test_name}
    gtest
    gtest_main
    LLVMSupport # gtest needs it for raw_ostream.
    )

  add_dependencies(${test_suite} ${test_name})
  get_target_property(test_suite_folder ${test_suite} FOLDER)
  if (NOT ${test_suite_folder} STREQUAL "NOTFOUND")
    set_property(TARGET ${test_name} PROPERTY FOLDER "${test_suite_folder}")
  endif ()

  # Visual Studio 2012 only supports up to 8 template parameters in
  # std::tr1::tuple by default, but gtest requires 10
  if (MSVC AND MSVC_VERSION EQUAL 1700)
    set_property(TARGET ${test_name} APPEND PROPERTY COMPILE_DEFINITIONS _VARIADIC_MAX=10)
  endif ()

  include_directories(${LLVM_MAIN_SRC_DIR}/utils/unittest/googletest/include)
  set_property(TARGET ${test_name} APPEND PROPERTY COMPILE_DEFINITIONS GTEST_HAS_RTTI=0)
  if (NOT LLVM_ENABLE_THREADS)
    set_property(TARGET ${test_name} APPEND PROPERTY COMPILE_DEFINITIONS GTEST_HAS_PTHREAD=0)
  endif ()

  get_property(target_compile_flags TARGET ${test_name} PROPERTY COMPILE_FLAGS)
  if (LLVM_COMPILER_IS_GCC_COMPATIBLE)
    set(target_compile_flags "${target_compile_flags} -fno-rtti")
  elseif (MSVC)
    set(target_compile_flags "${target_compile_flags} /GR-")
  endif ()

  if (SUPPORTS_NO_VARIADIC_MACROS_FLAG)
    set(target_compile_flags "${target_compile_flags} -Wno-variadic-macros")
  endif ()
  set_property(TARGET ${test_name} PROPERTY COMPILE_FLAGS "${target_compile_flags}")
endfunction()

# This function provides an automatic way to 'configure'-like generate a file
# based on a set of common and custom variables, specifically targetting the
# variables needed for the 'lit.site.cfg' files. This function bundles the
# common variables that any Lit instance is likely to need, and custom
# variables can be passed in.
function(configure_lit_site_cfg input output)
  foreach(c ${LLVM_TARGETS_TO_BUILD})
    set(TARGETS_BUILT "${TARGETS_BUILT} ${c}")
  endforeach(c)
  set(TARGETS_TO_BUILD ${TARGETS_BUILT})

  set(SHLIBEXT "${LTDL_SHLIB_EXT}")
  set(SHLIBDIR "${LLVM_BINARY_DIR}/lib/${CMAKE_CFG_INTDIR}")

  if(BUILD_SHARED_LIBS)
    set(LLVM_SHARED_LIBS_ENABLED "1")
  else()
    set(LLVM_SHARED_LIBS_ENABLED "0")
  endif(BUILD_SHARED_LIBS)

  if(${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
    set(SHLIBPATH_VAR "DYLD_LIBRARY_PATH")
  else() # Default for all other unix like systems.
    # CMake hardcodes the library locaction using rpath.
    # Therefore LD_LIBRARY_PATH is not required to run binaries in the
    # build dir. We pass it anyways.
    set(SHLIBPATH_VAR "LD_LIBRARY_PATH")
  endif()

  # Configuration-time: See Unit/lit.site.cfg.in
  set(LLVM_BUILD_MODE "%(build_mode)s")

  set(LLVM_SOURCE_DIR ${LLVM_MAIN_SRC_DIR})
  set(LLVM_BINARY_DIR ${LLVM_BINARY_DIR})
  set(LLVM_TOOLS_DIR "${LLVM_TOOLS_BINARY_DIR}/%(build_mode)s")
  set(LLVM_LIBS_DIR "${LLVM_BINARY_DIR}/lib/%(build_mode)s")
  set(PYTHON_EXECUTABLE ${PYTHON_EXECUTABLE})
  set(ENABLE_SHARED ${LLVM_SHARED_LIBS_ENABLED})
  set(SHLIBPATH_VAR ${SHLIBPATH_VAR})

  if(LLVM_ENABLE_ASSERTIONS AND NOT MSVC_IDE)
    set(ENABLE_ASSERTIONS "1")
  else()
    set(ENABLE_ASSERTIONS "0")
  endif()

  set(HOST_OS ${CMAKE_SYSTEM_NAME})
  set(HOST_ARCH ${CMAKE_SYSTEM_PROCESSOR})

  configure_file(${input} ${output} @ONLY)
endfunction()

# A raw function to create a lit target. This is used to implement the testuite
# management functions.
function(add_lit_target target comment)
  parse_arguments(ARG "PARAMS;DEPENDS;ARGS" "" ${ARGN})
  set(LIT_ARGS "${ARG_ARGS} ${LLVM_LIT_ARGS}")
  separate_arguments(LIT_ARGS)
  set(LIT_COMMAND
    ${PYTHON_EXECUTABLE}
    ${LLVM_MAIN_SRC_DIR}/utils/lit/lit.py
    --param build_mode=${CMAKE_CFG_INTDIR}
    ${LIT_ARGS}
    )
  foreach(param ${ARG_PARAMS})
    list(APPEND LIT_COMMAND --param ${param})
  endforeach()
  if( ARG_DEPENDS )
    add_custom_target(${target}
      COMMAND ${LIT_COMMAND} ${ARG_DEFAULT_ARGS}
      COMMENT "${comment}"
      )
    add_dependencies(${target} ${ARG_DEPENDS})
  else()
    add_custom_target(${target}
      COMMAND cmake -E echo "${target} does nothing, no tools built.")
    message(STATUS "${target} does nothing.")
  endif()
endfunction()

# A function to add a set of lit test suites to be driven through 'check-*' targets.
function(add_lit_testsuite target comment)
  parse_arguments(ARG "PARAMS;DEPENDS;ARGS" "" ${ARGN})

  # EXCLUDE_FROM_ALL excludes the test ${target} out of check-all.
  if(NOT EXCLUDE_FROM_ALL)
    # Register the testsuites, params and depends for the global check rule.
    set_property(GLOBAL APPEND PROPERTY LLVM_LIT_TESTSUITES ${ARG_DEFAULT_ARGS})
    set_property(GLOBAL APPEND PROPERTY LLVM_LIT_PARAMS ${ARG_PARAMS})
    set_property(GLOBAL APPEND PROPERTY LLVM_LIT_DEPENDS ${ARG_DEPENDS})
    set_property(GLOBAL APPEND PROPERTY LLVM_LIT_EXTRA_ARGS ${ARG_ARGS})
  endif()

  # Produce a specific suffixed check rule.
  add_lit_target(${target} ${comment}
    ${ARG_DEFAULT_ARGS}
    PARAMS ${ARG_PARAMS}
    DEPENDS ${ARG_DEPENDS}
    ARGS ${ARG_ARGS}
    )
endfunction()
