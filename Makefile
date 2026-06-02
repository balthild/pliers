help:
	@echo "Usage: make [build|fmt]"

build:
	swift build -c release

debug.%:
	swift build -c debug
	sudo ./.build/debug/pliers $*

fmt:
	dprint fmt
	swift format --in-place --recursive Sources Tests Package.swift
