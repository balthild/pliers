PLIERS_CONFIG_DIR ?= /etc/pliers

override GENERATE_PATH = ./Sources/PliersCommon/Constants+Generated.swift
override define GENERATE_CODE
import Foundation
extension Constants {
	static let configDir = URL(filePath: "$(PLIERS_CONFIG_DIR)")
}
endef
export GENERATE_CODE

help:
	@echo "Usage: make [configure|build|fmt]"

configure:
	@echo "PLIERS_CONFIG_DIR=$(PLIERS_CONFIG_DIR)"
	@echo "Generating $(GENERATE_PATH)"
	@echo "$$GENERATE_CODE" > $(GENERATE_PATH)

build:
	@if [ ! -f $(GENERATE_PATH) ]; then echo 'Please run "make configure" first'; exit 1; fi
	npx @tailwindcss/cli -i ./Resources/Style/main.css -o ./Public/dist/main.css
	swift build -c release

dev.%:
	@if [ ! -f $(GENERATE_PATH) ]; then echo 'Please run "make configure" first'; exit 1; fi
	swift build -c debug
	sudo ./.build/debug/pliers $*

dev.css:
	npx @tailwindcss/cli -i ./Resources/Style/main.css -o ./Public/dist/main.css --watch

fmt:
	dprint fmt
	swift format --in-place --recursive Sources Tests Package.swift
