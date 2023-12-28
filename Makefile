#
# Makefile
#

PROJECT_DIR	:= $(PWD)

.PHONY: bootstrap setup update test build lint cibuild all

bootstrap:
	$(PROJECT_DIR)/scripts/setup

setup:
	$(PROJECT_DIR)/scripts/setup

update:
	$(PROJECT_DIR)/scripts/update

test:
	$(PROJECT_DIR)/scripts/test

build:
	$(PROJECT_DIR)/scripts/build

format:
	$(PROJECT_DIR)/scripts/format

lint:
	$(PROJECT_DIR)/scripts/lint

cibuild:
	$(PROJECT_DIR)/scripts/cibuild

publish:
	$(PROJECT_DIR)/scripts/publish

readme:
	$(PROJECT_DIR)/scripts/readme