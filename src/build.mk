#
# Copyright (c) 2015, 2016 Intel Corporation
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
#   * Redistributions of source code must retain the above copyright notice,
#     this list of conditions and the following disclaimer.
#   * Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
#   * Neither the name of Intel Corporation nor the names of its contributors
#     may be used to endorse or promote products derived from this software
#     without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# Standard make declarations. Handles common and OS specific settings
#


# require that we know the root of the repo, or error
ifndef ROOT_DIR
	ROOT_ERR := $(error ROOT_DIR variable not set)
endif

# define common OS operations
RM = rm -f
COPY = cp -rav
MOVE = mv
MKDIR = mkdir -p
RMDIR = rm -rf
SOFTLINK = ln -s
SED = sed
TAR = tar
RPMBUILD = rpmbuild

# useful makefile debugging tools
# Its a hack, but it does the job! To unpause, simply hit the [ENTER] key.
PAUSE = read

# helper variables to define certain characters
BLDMK_PERIOD = .
BLDMK_COMMA = ,
BLDMK_EMPTY =
BLDMK_COLON = :
BLDMK_SLASH = /
BLDMK_SPACE = $(BLDMK_EMPTY) $(BLDMK_EMPTY)

ifndef BUILDNUM
	BUILDNUM= $(shell git describe --abbrev=0 | sed -e 's/\([a-zA-Z_-]*\)\(.*\)/\2/g')
	ifeq ($(strip $(BUILDNUM)),)
		BUILDNUM=99.99.99.9999
	endif
endif

#parse into individual pieces
VERSION_MAJOR = $(word 1,$(subst ., ,$(BUILDNUM)))
VERSION_MINOR = $(word 2,$(subst ., ,$(BUILDNUM)))
VERSION_HOTFIX = $(word 3,$(subst ., ,$(BUILDNUM)))
VERSION_BUILDNUM = $(word 4,$(subst ., ,$(BUILDNUM)))


# initialize/define compilation flag helper variables
C_CPP_FLAGS_CMN =  -Wall -Werror -Wfatal-errors -fstack-protector-all -D_FORTIFY_SOURCE=2 -D_XOPEN_SOURCE=500 
C_CPP_FLAGS_SRC = -MMD -D__VERSION_MAJOR__=$(VERSION_MAJOR) -D__VERSION_MINOR__=$(VERSION_MINOR) -D__VERSION_HOTFIX__=$(VERSION_HOTFIX) -D__VERSION_BUILDNUM__=$(VERSION_BUILDNUM) -D__VERSION_NUMBER__=$(BUILDNUM)  $(INTEL_I18N)

CFLAGS_CMN = -std=c99
CPPFLAGS_CMN =

LIB_BASENAME=libinvm-i18n
LIB_NAME=invm-i18n
HEADER_DIRECTORY=libinvm-i18n

# OS specific settings
UNAME := $(shell uname)
ifeq ($(UNAME), Linux)

	# ESX builds occur on Linux but the environment will include this variable
	ifdef ESXBUILD
		MGMT_ENV_DIR = /opt/mgmt_env
		MGMT_SYSROOT =  $(MGMT_ENV_DIR)/4.5-32
		BUILD_ESX = 1
		OS_TYPE = esx
		LIB_SUFFIX = so

		# GNU toolchain provided by VMware		
		AR = /build/toolchain/lin32/gcc-4.4.3-1/x86_64-linux5.0/bin/ar
		CC = /build/toolchain/lin32/gcc-4.4.3-1/bin/i686-linux5.0-gcc \
			--sysroot=/opt/vmware/toolchain/cayman_esx_glibc-d2e7492e1433e2ac7bff92a58f9ac237a70c621f/sysroot -D_GNU_SOURCE -m32
		# VMware doesn't directly support C++ for ESX 3rd party applications.
		# Provide own C++ compiler and development environment. 
		CPP = export LD_LIBRARY_PATH=$(MGMT_SYSROOT)/usr/lib;\
			$(MGMT_SYSROOT)/usr/bin/g++ -m32 --sysroot=$(MGMT_SYSROOT)
		CPP_RUNTIME = $(MGMT_SYSROOT)/usr/lib/libstdc++.so*

		C_CPP_FLAGS_CMN += -fPIC
		C_CPP_FLAGS_SRC += -D__ESX__ -DCLI_OUTPUT_ESX
	else
		BUILD_LINUX = 1
		OS_TYPE = linux
		LIB_SUFFIX = so

		# get the Mgmt Build Environment
		MGMT_ENV_DIR ?= /opt/mgmt_env

		# doxygen
		DOXYGEN ?= $(MGMT_ENV_DIR)/doxygen/doxygen

		# GNU toolchain
		CC = gcc
		CPP = g++
		AR = ar

		C_CPP_FLAGS_CMN += -fPIC
		uname_m = $(shell uname -m)
		ifeq (,$(findstring arm,$(uname_m)))
			C_CPP_FLAGS_CMN += -m64
		endif
		C_CPP_FLAGS_SRC += -D__LINUX__

		ifneq ("$(wildcard /etc/redhat-release)","")
			LINUX_DIST := rel
		else ifneq ("$(wildcard /etc/SuSE-release)","")
			LINUX_DIST := sle
		else
			LINUX_DIST := $(warning Unrecognized Linux distribution)
		endif
	endif		
else
	BUILD_WINDOWS = 1
	OS_TYPE = windows
	LIB_SUFFIX = dll

	# get the Mgmt Build Environment
	MGMT_ENV_DIR ?= C:/mgmt_env

	# doxygen (runs in windows only)
	DOXYGEN ?= $(MGMT_ENV_DIR)/doxygen/doxygen.exe

	# MinGW_w64 toolchain
	MINGW_DIR ?= $(MGMT_ENV_DIR)/mingw_w64
	include $(MINGW_DIR)/mingw.mk

	# note: -mno-ms-bitfields is a workaround for a gcc (4.7.0)+ byte-packing bug
	#		This may cause GCC packed structs to present differences with MSVC packed structs
	C_CPP_FLAGS_CMN += -m64 -mno-ms-bitfields
	C_CPP_FLAGS_SRC += -D__WINDOWS__
	CPPFLAGS_CMN += -static-libstdc++

endif

# release/debug build specific settings
ifdef RELEASE
	BUILD_TYPE = release
	C_CPP_FLAGS_CMN += -O2
	CPPFLAGS_CMN += -fno-strict-aliasing
else
	BUILD_TYPE = debug
	C_CPP_FLAGS_CMN += -O -ggdb
endif

# define compilation flags used within $(ROOT_DIR)/external & $(ROOT_DIR)/src
CFLAGS_EXTERNAL ?=
CFLAGS_EXT = $(C_CPP_FLAGS_CMN) $(CFLAGS_CMN)
CPPFLAGS_EXT = $(C_CPP_FLAGS_CMN) $(CPPFLAGS_CMN)
CFLAGS = $(C_CPP_FLAGS_CMN) $(CFLAGS_CMN) $(C_CPP_FLAGS_SRC) $(CFLAGS_EXTERNAL)
CPPFLAGS = $(C_CPP_FLAGS_CMN) $(CPPFLAGS_CMN) $(C_CPP_FLAGS_SRC) $(CPPFLAGS_SRC) 
RCFLAGS = -D__VERSION_MAJOR__=$(VERSION_MAJOR) -D__VERSION_MINOR__=$(VERSION_MINOR) -D__VERSION_HOTFIX__=$(VERSION_HOTFIX) -D__VERSION_BUILDNUM__=$(VERSION_BUILDNUM) -D__VERSION_NUMBER__=$(BUILDNUM)

# define top-level directories
EXTERN_DIR = $(ROOT_DIR)/external
TOOLS_DIR = $(ROOT_DIR)/tools
SRC_DIR = $(ROOT_DIR)/src
ifdef CCOV
	OUTPUT_DIR ?= $(ROOT_DIR)/output/cov
else 
	OUTPUT_DIR ?= $(ROOT_DIR)/output
endif

# define OS-specific build output directories
EXTERN_LIB_DIR = $(EXTERN_DIR)/precompiled_libs/$(OS_TYPE)
BUILT_TOOLS_DIR = $(OUTPUT_DIR)/tools/$(OS_TYPE)/$(BUILD_TYPE)
OBJECT_DIR = $(OUTPUT_DIR)/obj/$(OS_TYPE)/$(BUILD_TYPE)
BUILD_DIR = $(OUTPUT_DIR)/build/$(OS_TYPE)/$(BUILD_TYPE)
I18N_HEADER_DIR = $(OUTPUT_DIR)/build/$(OS_TYPE)/$(BUILD_TYPE)/include/$(HEADER_DIRECTORY)
#DOCS_DIR = $(OUTPUT_DIR)/docs
SOURCEDROP_DIR ?= $(OUTPUT_DIR)/workspace/$(HEADER_DIRECTORY)
RPMBUILD_DIR ?= $(shell pwd)/$(OUTPUT_DIR)/rpmbuild
# Tools
CSTYLE = $(TOOLS_DIR)/cstyle/cstyle -o doxygen -pP
SCHEMA_GEN = $(BUILT_TOOLS_DIR)/SchemaGen.exe

# Unit Test default
RUN_UNITTEST_DEFAULT = cd $(BUILD_DIR)
ifndef BUILD_WINDOWS
	RUN_UNITTEST_DEFAULT += && export LD_LIBRARY_PATH=./
endif

# memory leak tool (changes default unittest to run leak checks)
ifdef MEMCHK
	INSPXE_CFG_DIR = $(TOOLS_DIR)/inspxe
	include $(INSPXE_CFG_DIR)/inspector.mk
	RUN_UNITTEST = $(RUN_UNITTEST_DEFAULT) && $(INSPXE_TARGETNAME)
else
	RUN_UNITTEST = $(RUN_UNITTEST_DEFAULT) && ./$(TARGETNAME)
endif

# test coverage tool
ifdef CCOV
	BULLSEYE_DIR = $(MGMT_ENV_DIR)/bullseye
	include $(BULLSEYE_DIR)/bullseye.mk
	# force bullseye to update coverage metrics at termination of executables
	# instead of during execution
	export COVAUTOSAVE := 0
endif


