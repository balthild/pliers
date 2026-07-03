PLIERS_CONF ?= /etc/pliers
PLIERS_PKGS ?= /opt/pliers
PLIERS_COREUTILS ?= /usr/bin
PLIERS_CADDY_EXEC ?= /usr/bin/caddy
PLIERS_CADDY_CONF ?= /etc/caddy

override GENERATE_PATH = ./Sources/PliersCommon/Constants+Generated.swift
override define GENERATE_CODE
import Path
extension Constants {
	public static let conf = Path("$(PLIERS_CONF)")!
	public static let pkgs = Path("$(PLIERS_PKGS)")!
	public static let coreutils = Path("$(PLIERS_COREUTILS)")!
	public enum caddy {
		public static let exec = Path("$(PLIERS_CADDY_EXEC)")!
		public static let conf = Path("$(PLIERS_CADDY_CONF)")!
	}
}
endef
export GENERATE_CODE

help:
	@echo "Usage: make [configure|build|fmt]"

configure:
	@$(foreach v, $(sort $(filter PLIERS_%, $(.VARIABLES))), echo "$(v)=$($(v))";)
	@echo "Generating $(GENERATE_PATH)"
	@echo "$$GENERATE_CODE" > $(GENERATE_PATH)

build:
	@if [ ! -f $(GENERATE_PATH) ]; then echo 'Please run "make configure" first'; exit 1; fi
	npx @tailwindcss/cli -i ./Resources/Style/main.css -o ./Public/dist/main.css
	swift build -c release

dev.%: SWIFT_BACKTRACE = timeout=none
dev.%:
	@printf "\033]0;dev.$*\007"
	@if [ ! -f $(GENERATE_PATH) ]; then echo 'Please run "make configure" first'; exit 1; fi
	swift build -c debug
	sudo ./.build/debug/pliers $*

dev.css:
	@printf "\033]0;dev.css\007"
	npx @tailwindcss/cli -i ./Resources/Style/main.css -o ./Public/dist/main.css --watch

dbus:
	busctl introspect --xml-interface org.freedesktop.systemd1 /org/freedesktop/systemd1 > ./Sources/PliersServer/Support/DBus/Systemd1.xml
	swift run dbus-codegen ./Sources/PliersServer/Support/DBus/Systemd1.xml
	swift format --in-place ./Sources/PliersServer/Support/DBus/Systemd1.swift

fmt:
	dprint fmt
	swift format --in-place --recursive Sources Tests Package.swift
