PLIERS_CONF ?= /etc/pliers
PLIERS_PKGS ?= /opt/pliers
PLIERS_RUN ?= /run/pliers
PLIERS_ASSETS ?= /usr/share/pliers
PLIERS_SYSTEM_BIN ?= /usr/bin
PLIERS_SYSTEM_SERVICES ?= /etc/systemd/system
PLIERS_CADDY_EXEC ?= /usr/bin/caddy
PLIERS_CADDY_CONF ?= /etc/caddy
PLIERS_CADDY_LOG ?= /var/log/caddy
PLIERS_CADDY_USER ?= caddy
PLIERS_CRON_EXEC ?= /usr/bin/crontab
PLIERS_WWW_HOME ?= /var/www
PLIERS_WWW_USER ?= www-data
PLIERS_WWW_GROUP ?= www-data

override GENERATE_PATH = ./Sources/PliersCommon/Constants+Generated.swift
override define GENERATE_CODE
import Path
extension Constants {
	public static let conf = Path("$(PLIERS_CONF)")!
	public static let pkgs = Path("$(PLIERS_PKGS)")!
	public static let run = Path("$(PLIERS_RUN)")!
	public static let assets = Path("$(PLIERS_ASSETS)")!
	public enum system {
		public static let bin = Path("$(PLIERS_SYSTEM_BIN)")!
		public static let services = Path("$(PLIERS_SYSTEM_SERVICES)")!
	}
	public enum caddy {
		public static let exec = Path("$(PLIERS_CADDY_EXEC)")!
		public static let conf = Path("$(PLIERS_CADDY_CONF)")!
		public static let log = Path("$(PLIERS_CADDY_LOG)")!
		public static let user = "$(PLIERS_CADDY_USER)"
	}
	public enum www {
		public static let home = Path("$(PLIERS_WWW_HOME)")!
		public static let user = "$(PLIERS_WWW_USER)"
		public static let group = "$(PLIERS_WWW_GROUP)"
	}
}
endef

help:
	@echo "Usage: make [configure|build|test|fmt]"

configure:
	@$(foreach v, $(sort $(filter PLIERS_%, $(.VARIABLES))), echo "$(v)=$($(v))";)
	@echo "Generating $(GENERATE_PATH)"
	$(file > $(GENERATE_PATH),$(GENERATE_CODE))

build:
	@if [ ! -f $(GENERATE_PATH) ]; then echo 'Please run "make configure" first'; exit 1; fi
	npm exec vite build
	swift build -c release

test:
	@if [ ! -f $(GENERATE_PATH) ]; then echo 'Please run "make configure" first'; exit 1; fi
	swift test

package: export PKGARCH=$(shell uname -m)
package: build
	rm -rf ./.build/pkg
	mkdir -p ./.build/pkg
	npm exec nfpm pkg --packager deb --target ./.build/pkg --config ./nfpm.yaml

release: package
	git tag -f dev
	git push -f origin dev
	gh release delete dev --yes || true
	gh release create dev --notes "dev"
	gh release upload dev ./.build/pkg/*.deb

dev:
	@printf "\033]0;dev\007"
	npm exec mprocs

dev.%:
	@printf "\033]0;dev.$*\007"
	@if [ ! -f $(GENERATE_PATH) ]; then echo 'Please run "make configure" first'; exit 1; fi
	swift build -c debug
	sudo \
		SWIFT_BACKTRACE="timeout=none" \
		LOG_LEVEL="$(LOG_LEVEL)" \
		./.build/debug/pliers $*

dev.vite:
	@printf "\033]0;dev.vite\007"
	npm exec vite

dev.check:
	npm exec tsc

dev.sqlite:
	@printf "\033]0;dev.sqlite\007"
	sudo podman rm --force --time 1 pliers-sqlite || true
	sudo podman run \
		--rm -it \
		--name=pliers-sqlite \
		--user=root \
		-p 8080:8080 \
		-v /var/lib/pliers/dashboard:/data \
		ghcr.io/coleifer/sqlite-web db.sqlite

dev.dbus:
	busctl introspect --xml-interface org.freedesktop.DBus /org/freedesktop/DBus > ./Sources/PliersDBus/DBus.xml
	busctl introspect --xml-interface org.freedesktop.systemd1 /org/freedesktop/systemd1 > ./Sources/PliersDBus/Systemd1.xml

	swift run dbus-codegen \
		./Sources/PliersDBus/DBus.xml \
		./Sources/PliersDBus/Systemd1.xml \
		./Sources/PliersDBus/Pliers.xml \
		--output-dir ./Sources/PliersDBus

	npm exec dprint fmt ./Sources/PliersDBus/**

fmt:
	npm exec dprint fmt

clean:
	swift package reset
