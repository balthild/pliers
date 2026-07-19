PLIERS_CONF ?= /etc/pliers
PLIERS_PKGS ?= /opt/pliers
PLIERS_COREUTILS ?= /usr/bin
PLIERS_CADDY_EXEC ?= /usr/bin/caddy
PLIERS_CADDY_CONF ?= /etc/caddy
PLIERS_CADDY_USER ?= caddy
PLIERS_WWW_HOME ?= /var/www
PLIERS_WWW_USER ?= www-data
PLIERS_WWW_GROUP ?= www-data

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
		public static let user = "$(PLIERS_CADDY_USER)"
	}
	public enum www {
		public static let home = Path("$(PLIERS_WWW_HOME)")!
		public static let user = "$(PLIERS_WWW_USER)"
		public static let group = "$(PLIERS_WWW_GROUP)"
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
	busctl introspect --xml-interface org.freedesktop.systemd1 /org/freedesktop/systemd1 > ./Sources/PliersSystemd/Systemd1.xml
	swift run dbus-codegen ./Sources/PliersSystemd/Systemd1.xml
	dprint fmt ./Sources/PliersSystemd

fmt:
	dprint fmt
