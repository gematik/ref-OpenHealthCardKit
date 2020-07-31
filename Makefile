#
# Makefile
#

CIBUILD			?= false
BUILD_TYPE	?= Debug
PROJECT_DIR	:= $(PWD)
IOS_DEPLOYMENT_TARGET ?= 'ios13.0'

ifeq ($(CIBUILD), true)
  BUILD_TYPE = Release
endif

.PHONY: setup update test build lint cibuild all

setup:
	$(PROJECT_DIR)/scripts/setup ${BUILD_TYPE}

update:
	$(PROJECT_DIR)/scripts/update

test:
	$(PROJECT_DIR)/scripts/test

build:
	$(PROJECT_DIR)/scripts/build ${BUILD_TYPE} ${IOS_DEPLOYMENT_TARGET}

lint:
	$(PROJECT_DIR)/scripts/lint

cibuild:
	$(PROJECT_DIR)/scripts/cibuild ${BUILD_TYPE}

all: cibuild
