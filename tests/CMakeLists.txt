cmake_minimum_required(VERSION 3.12)

project(sphinx-cmake-test VERSION 1.0)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/../cmake")

find_package(Sphinx)

if(Sphinx_FOUND)
  add_sphinx_document(
      sphinx-cmake-test
      CONF_FILE "${CMAKE_CURRENT_LIST_DIR}/src/conf.py"
      SKIP_PDF
      "${CMAKE_CURRENT_LIST_DIR}/src/index.rst"
    )
else()
  message(WARNING "No Sphinx found. Documentation target not available.")
endif()
