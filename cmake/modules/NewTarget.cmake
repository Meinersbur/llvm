

option(BUILD_OBJECT_LIBS "Use object libraries instead of static ones (Enables MSVC to link incrementally)" OFF)
option(BUILD_OBJECT_LIBS_ONLY "If BUILD_OBJECT_LIBS is used, disable creation of static lib targets" OFF)



# Global properties:
#   ALL_TARGETS - anything created with new_library or new_executable

# OBJECT library target properties:
#   LINK_LIBS - Libraries it is supposed to link with, but cannot because it is a abject library


# For an existing static library, also create an object library with the same option
function(new_library ARG_NAME)
message("new_library(${ARG_NAME} ${ARGN})")
  PARSE_FUNCTION_ARGUMENTS("ARG" "MODULE;SHARED;STATIC" "" "SOURCES;LINK_LIBS" ${ARGN})
  
  # additional arguments are probably source files
  list(APPEND ARG_SOURCES ${ARGN})
  
  if(ARG_MODULE)
  elseif(ARG_SHARED)
  else()
    # default
    set(ARG_STATIC STATIC)
  endif()
  
  if (ARG_STATIC)
    if (BUILD_OBJECT_LIBS)
      set(_objlibname "${ARG_NAME}_objs")
    
      # Object files do not allow non-compilable files
      set (_compilable_srcs)
      set (_additional_srcs)
      foreach (_src IN LISTS ARG_SOURCES)
        if (_src MATCHES ".*\\.inc")
          list(APPEND _additional_srcs "${_src}")
        else ()
          list(APPEND _compilable_srcs "${_src}")
        endif ()
      endforeach()
    
      add_library(${_objlibname} OBJECT ${_compilable_srcs} ${ARG_UNPARSED_ARGUMENTS})
      
      # Anything that links this object library also must links its dependencies
      set_property(TARGET ${_objlibname} PROPERTY LINK_LIBS ${ARG_LINK_LIBS})
      
      # Add to list of all object libraries (without suffix) to be postprocessed later
      set_property(GLOBAL APPEND PROPERTY ALL_OBJECT_LIBS ${ARG_NAME})
    endif()
    
    if (NOT BUILD_OBJECT_LIBS_ONLY)
      # also create the static library; properties will be applied on that one
      add_library(${ARG_NAME} STATIC $<TARGET_OBJECTS:${ARG_NAME}_objs> ${_additional_srcs})
      target_link_libraries(${ARG_NAME} ${ARG_LINK_LIBS})
    endif ()
  else ()
    # not applicable
    add_library(${ARG_NAME} ${ARGN})
    target_link_libraries(${ARG_NAME} ${ARG_LINK_LIBS})
  endif ()
  
  # Add to list to be postprocessed
  set_property(GLOBAL APPEND PROPERTY ALL_TARGETS ${ARG_NAME})
endfunction()



function(new_executable ARG_NAME)
message("new_executable(${ARG_NAME} ${ARGN})")
  PARSE_FUNCTION_ARGUMENTS("ARG" "" "" "LINK_LIBS;SOURCES;TARGET_DEPENDS" ${ARGN})
 
  if (BUILD_OBJECT_LIBS)
    # Do build using object libs
    
    # additional arguments are probably source files
    set(_srcs ${ARG_SOURCES} ${ARGN})
    
    objlib_link_libraries(_objlibsources _linklibs ${ARG_LINK_LIBS})
    add_executable(${ARG_NAME} ${_srcs} ${_objlibsources} ${ARG_UNPARSED_ARGUMENTS})
    target_link_libraries(${ARG_NAME} ${_linklibs})
  else ()
    # Do build using static libs
    add_executable(${ARG_NAME} ${ARG_SOURCES} ${ARG_UNPARSED_ARGUMENTS})
  endif ()
  
  if (ARG_TARGET_DEPENDS)
    add_dependencies(${ARG_NAME} ${ARG_TARGET_DEPENDS})
  endif ()
  
  # Add to list to be postprocessed
  set_property(GLOBAL PROPERTY ALL_TARGETS APPEND ${ARG_NAME})
endfunction()





function(new_target_link_libraries ARG_NAME)
message("new_target_link_libraries(${ARG_NAME} ${ARGN})")

  get_target_property(_target_type ${ARG_NAME} TYPE)
  if (_target_type STREQUAL "OBJECT_LIBRARY")
    # Unfortunately, OBJECT libraries cannot have transitive linke dependencies
    # we have to rembember this and add the dependency later ourselves
  else ()
    set(_deplibs)
    foreach (_deplib IN LISTS ARGN)
      get_target_property(_dep_type ${_deplib} TYPE)
      if (_dep_type STREQUAL "OBJECT_LIBRARY")
        # Unfortunately, we cannot add object library dependencies via target_link_libraries
      else ()
        list(APPEND _deplibs "${_deplib}")
      endif ()
    endforeach ()
  
    target_link_libraries(${ARG_NAME} ${_deplibs})
  endif ()
endfunction()


function(new_dependencies ARG_NAME)
message("new_dependencies(${ARG_NAME} ${ARGN})")
  add_dependencies(${ARG_NAME} ${ARGN})
endfunction()



function(new_postprocess_objlib ARG_LIB ARG_OBJLIB)
# Transfer target properties to objectlib
endfunction ()


function(new_postprocess_target ARG_NAME)
# Add transitive library dependencies
endfunction()


# Postprocess
function(new_postprocess)
  message("new_postprocess(${ARGN})")
  
  get_property(GLOBAL PROPERTY ALL_TARGETS _alltargets)
  foreach (_target IN LISTS _alltargets)
     get_target_property(_targettype ${_target} TYPE)
     if (_targettype STREQUAL "OBJECT_LIBRARY")
       # Will be processed when its static library is encountered
     elseif ()
       if (TARGET "${_target}_objs")
          # This is a target library that needs to be postprocessed
         new_postprocess_objlib(${_target} "${_target}_objs")
       endif ()
     endif()
     new_postprocess_target(${_target})
  endforeach ()
endfunction()



# split the link dependencies into the part that needs to be added to the sources list, and the part to be added using target_link_libraries
function(objlib_link_libraries OUTVAR_SOURCES OUTVAR_LINKLIBS)
  set(_result_sources)
  set(_result_linklibs)
  
  set(_closed)
  set(_worklist ${ARGN})
  set(_done)
    
  while (_worklist)
    list(GET _worklist 0 _lib)
    list(REMOVE_AT _worklist 0)

    resolve_libtype(${_dep} _libname _objlibname)
    list(FIND _done "${_libname}" _found)
    
    if (_found EQUAL -1)
      list(APPEND _done ${_libname})
      
      if (_objlibname)
        # it's an object library
        list(APPEND _result_sources "$<TARGET_OBJECTS:${_objlibname}>")
        
        get_target_property(_externallibdeps ${_objlibname} "LINK_LIBS") 
        if (_externallibdeps)
          list(APPEND _worklist ${_externallibdeps})
        endif ()
      else ()
        # link as normal
        list(APPEND _result_linklibs ${_libname})
      endif()
    endif()
  endwhile()
  
  set(${OUTVAR_SOURCES} ${_result_sources} PARENT_SCOPE)
  set(${OUTVAR_LINKLIBS} ${_result_linklibs} PARENT_SCOPE)
endfunction()



# Resolve properties of an object library
# OUTVAR_LIBNAME - receives the name of the static library
# Receives the name of the object library
function (resolve_libtype ARG_NAME OUTVAR_LIBNAME OUTVAR_OBJLIBNAME)
  get_target_property(_type ${_deplib} TYPE)
  if (_type STREQUAL "OBJECT_LIBRARY")
    # It's a object library itself
    string(REGEX REPLACE "_objs" _plainname ${ARG_NAME})
    if (TARGET _plainname)
      set (${OUTVAR_LIBNAME} "${_plainname}" PARENT_SCOPE)
    endif ()
    set (${OUTVAR_OBJLIBNAME} "${ARG_NAME}" PARENT_SCOPE)
    return ()
  endif()
  
  if (TARGET ${ARG_NAME}_objs)
    # There exists a object library version of this
    set (${OUTVAR_LIBNAME} "${ARG_NAME}" PARENT_SCOPE)
    set (${OUTVAR_OBJLIBNAME} "${ARG_NAME}_objs" PARENT_SCOPE)
    return()
  endif ()
  
  # Otherwise...
  set (${OUTVAR_LIBNAME} "${ARG_NAME}" PARENT_SCOPE)
  set (${OUTVAR_OBJLIBNAME} "" PARENT_SCOPE)
endfunction()



# Like CMAKE_PARSE_ARGUMENTS, but allows _multiArgNames specified multiple times, in which case the arguments are appended
function(PARSE_FUNCTION_ARGUMENTS prefix _optionNames _singleArgNames _multiArgNames)
  # first set all result variables to empty/FALSE
  foreach(arg_name IN LISTS _singleArgNames _multiArgNames)
    set(${prefix}_${arg_name})
  endforeach()

  foreach(option IN LISTS _optionNames)
    set(${prefix}_${option} FALSE)
  endforeach()

  set(${prefix}_UNPARSED_ARGUMENTS)

  set(insideValues FALSE)
  set(currentArgName)

  # now iterate over all arguments and fill the result variables
  foreach(currentArg ${ARGN})
    list(FIND _optionNames "${currentArg}" optionIndex)        # ... then this marks the end of the arguments belonging to this keyword
    list(FIND _singleArgNames "${currentArg}" singleArgIndex)  # ... then this marks the end of the arguments belonging to this keyword
    list(FIND _multiArgNames "${currentArg}" multiArgIndex)    # ... then this marks the end of the arguments belonging to this keyword

    if(${optionIndex} EQUAL -1  AND  ${singleArgIndex} EQUAL -1  AND  ${multiArgIndex} EQUAL -1)
      if(insideValues)
        if("${insideValues}" STREQUAL "SINGLE")
          set(${prefix}_${currentArgName} ${currentArg})
          set(insideValues FALSE)
        elseif("${insideValues}" STREQUAL "MULTI")
          list(APPEND ${prefix}_${currentArgName} ${currentArg})
        endif()
      else()
        list(APPEND ${prefix}_UNPARSED_ARGUMENTS ${currentArg})
      endif()
    else()
      if(NOT ${optionIndex} EQUAL -1)
        set(${prefix}_${currentArg} TRUE)
        set(insideValues FALSE)
      elseif(NOT ${singleArgIndex} EQUAL -1)
        set(currentArgName ${currentArg})
        set(${prefix}_${currentArgName})  # Overwrite any previous argument with this name
        set(insideValues "SINGLE")
      elseif(NOT ${multiArgIndex} EQUAL -1)
        set(currentArgName ${currentArg})
        set(insideValues "MULTI")
      endif()
    endif()

  endforeach()

  # propagate the result variables to the caller:
  foreach(arg_name ${_singleArgNames} ${_multiArgNames} ${_optionNames})
    set(${prefix}_${arg_name}  ${${prefix}_${arg_name}} PARENT_SCOPE)
  endforeach()
  set(${prefix}_UNPARSED_ARGUMENTS ${${prefix}_UNPARSED_ARGUMENTS} PARENT_SCOPE)

endfunction()



