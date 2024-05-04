#           __        _
#  ________/ /  ___ _(_)__  ___
# / __/ __/ _ \/ _ `/ / _ \/ -_)
# \__/\__/_//_/\_,_/_/_//_/\__/
# 
# Copyright (C) Clément Chaine
# This file is part of sphinx-cmake <https://github.com/ecap5/sphinx-cmake>
# 
# sphinx-cmake is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# sphinx-cmake is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with sphinx-cmake.  If not, see <http://www.gnu.org/licenses/>.

include(FindPackageHandleStandardArgs)

find_package(Python3)
if(PYTHONINTERP_FOUND)
  get_filename_component(_PYTHON_DIR "${PYTHON_EXECUTABLE}" DIRECTORY)
  set(
        _PYTHON_PATHS
      "${_PYTHON_DIR}"
      "${_PYTHON_DIR}/bin"
      "${_PYTHON_DIR}/Scripts")
endif()
find_program(
    SPHINX_EXECUTABLE
    NAMES sphinx-build sphinx-build.exe
    HINTS ${_PYTHON_PATHS})
mark_as_advanced(SPHINX_EXECUTABLE)

find_package_handle_standard_args(Sphinx DEFAULT_MSG SPHINX_EXECUTABLE)

# If finding Sphinx fails, there is no use in defining
# add_sphinx_document, so return early
if(NOT Sphinx_FOUND)
    return()
endif()

set(_SPHINX_SCRIPT_DIR ${CMAKE_CURRENT_LIST_DIR})

# add_sphinx_document(
#   <name>
#   CONF_FILE <conf-py-filename>
#   [C_API <c-api-header-file>]
#   [SKIP_HTML] [SKIP_PDF]
#   <rst-src-file>...)
#
# Function for creating Sphinx documentation targets.
function(add_sphinx_document TARGET_NAME)
    cmake_parse_arguments(
      ${TARGET_NAME}
      "SKIP_HTML;SKIP_PDF"
      "CONF_FILE"
      ""
      ${ARGN})

  get_filename_component(SRCDIR "${${TARGET_NAME}_CONF_FILE}" DIRECTORY)
  set(INTDIR "${CMAKE_CURRENT_BINARY_DIR}/${TARGET_NAME}/source")
  set(OUTDIR "${CMAKE_CURRENT_BINARY_DIR}/${TARGET_NAME}/build")

  string(TIMESTAMP SPHINX_TARGET_YEAR "%Y" UTC)

  # Generate conf.py at configuration time
  add_custom_command(
    OUTPUT "${INTDIR}/conf.py"
    COMMAND "${CMAKE_COMMAND}" -E make_directory "${INTDIR}"
    COMMAND
        "${CMAKE_COMMAND}"
        "-DCONFIGURE_FILE_IN=${${TARGET_NAME}_CONF_FILE}"
        "-DCONFIGURE_FILE_OUT=${INTDIR}/conf.py"
        "-DSPHINX_TARGET_NAME=${TARGET_NAME}"
        "-DSPHINX_TARGET_VERSION=${PROJECT_VERSION}"
        "-DSPHINX_TARGET_VERSION_MAJOR=${PROJECT_VERSION_MAJOR}"
        "-DSPHINX_TARGET_VERSION_MINOR=${PROJECT_VERSION_MINOR}"
        "-DSPHINX_TARGET_YEAR=${SPHINX_TARGET_YEAR}"
        -P "${_SPHINX_SCRIPT_DIR}/BuildTimeConfigureFile.cmake"
    DEPENDS "${${TARGET_NAME}_CONF_FILE}")
  set(SPHINX_DEPENDS "${INTDIR}/conf.py")

  # Copy each source file to the build directory
  foreach(DOCFILE ${${TARGET_NAME}_UNPARSED_ARGUMENTS})
    get_filename_component(DOCFILE_INTDIR "${DOCFILE}" DIRECTORY)
    string(
        REPLACE
        "${SRCDIR}" "${INTDIR}"
        DOCFILE_INTDIR "${DOCFILE_INTDIR}")

    get_filename_component(DOCFILE_DEST "${DOCFILE}" NAME)
    set(DOCFILE_DEST "${DOCFILE_INTDIR}/${DOCFILE_DEST}")

    add_custom_command(
        OUTPUT "${DOCFILE_DEST}"
        COMMAND
            "${CMAKE_COMMAND}" -E make_directory "${DOCFILE_INTDIR}"
        COMMAND
            "${CMAKE_COMMAND}" -E copy_if_different
            "${DOCFILE}" "${DOCFILE_DEST}"
        DEPENDS "${DOCFILE}")

    list(APPEND SPHINX_DEPENDS "${DOCFILE_DEST}")
  endforeach()
  set(TARGET_DEPENDS)

  # Generate the HTML if not skipped
  if(NOT ${TARGET_NAME}_SKIP_HTML)
      add_custom_command(
          OUTPUT "${OUTDIR}/html.stamp"
          # Create the _static directory required by Sphinx in case it
          # wasn't added as one of the source files
          COMMAND "${CMAKE_COMMAND}" -E make_directory "${INTDIR}/_static"
          COMMAND "${SPHINX_EXECUTABLE}" -M html "${INTDIR}" "${OUTDIR}"
          COMMAND "${CMAKE_COMMAND}" -E touch "${OUTDIR}/html.stamp"
          DEPENDS ${SPHINX_DEPENDS})

      list(APPEND TARGET_DEPENDS "${OUTDIR}/html.stamp")
  endif()

  # Generate pdf with rst->latex
  if(NOT ${TARGET_NAME}_SKIP_PDF)
    find_package(LATEX COMPONENTS PDFLATEX)

    if(LATEX_PDFLATEX_FOUND)
        add_custom_command(
            OUTPUT "${OUTDIR}/latex/${TARGET_NAME}.tex"
            COMMAND "${SPHINX_EXECUTABLE}" -M latex "${INTDIR}" "${OUTDIR}"
            DEPENDS ${SPHINX_DEPENDS})

        add_custom_command(
            OUTPUT "${OUTDIR}/latex/${TARGET_NAME}.pdf"
            # Three times' the charm for PdfLaTeX to get all xrefs right
            COMMAND "${PDFLATEX_COMPILER}" "${TARGET_NAME}.tex"
            COMMAND "${PDFLATEX_COMPILER}" "${TARGET_NAME}.tex"
            COMMAND "${PDFLATEX_COMPILER}" "${TARGET_NAME}.tex"
            WORKING_DIRECTORY "${OUTDIR}/latex"
            DEPENDS "${OUTDIR}/latex/${TARGET_NAME}.tex")

        list(APPEND TARGET_DEPENDS "${OUTDIR}/latex/${TARGET_NAME}.pdf")
    else()
        message(WARNING "No PdfLaTeX found. PDF output not available.")
    endif()
  endif()

  # Create the target
  add_custom_target(
      ${TARGET_NAME}
      DEPENDS ${TARGET_DEPENDS})

  # Add the target to the docs target
  if(NOT TARGET doc)
      add_custom_target(docs)
  endif()
  add_dependencies(docs ${TARGET_NAME})
endfunction()
