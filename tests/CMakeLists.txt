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
