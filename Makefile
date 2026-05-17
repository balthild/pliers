help:
	@echo Usage: make [build|fmt]

build:
	swift build -c release

fmt:
	dprint fmt
	swift format --in-place --recursive Sources Tests Package.swift
