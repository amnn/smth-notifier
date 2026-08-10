# Copyright (c) Ashok Menon
# SPDX-License-Identifier: Apache-2.0

NAME := smth notifier
EXECUTABLE_NAME := smth-notifier

BUILD_DIR := .build
APP := $(BUILD_DIR)/$(NAME).app
CONTENTS := $(APP)/Contents
MACOS := $(CONTENTS)/MacOS
RESOURCES := $(CONTENTS)/Resources
EXECUTABLE := $(BUILD_DIR)/release/$(EXECUTABLE_NAME)

SWIFT_INPUTS := $(shell find Sources -type f)
SWIFT_SOURCE_DIRS := $(shell find Sources -type d)
PACKAGE_INPUTS := Package.swift $(wildcard Package.resolved)

SMTH_NOTIFIER_TERMINAL_BINARY ?= Terminal
SMTH_NOTIFIER_TERMINAL_BUNDLE_IDENTIFIER ?= com.apple.Terminal

SMTH_NOTIFIER_ICON ?= App/Notifier.svg
ICON_SOURCE := $(SMTH_NOTIFIER_ICON)

# Keep each configured source in its own build directory so switching
# SMTH_NOTIFIER_ICON also selects a distinct Make target.
ICON_SOURCE_KEY := $(shell printf '%s' "$(ICON_SOURCE)" | shasum -a 256 | cut -d ' ' -f 1)
ICON_DIR := $(BUILD_DIR)/icons/$(ICON_SOURCE_KEY)
ICONSET := $(ICON_DIR)/AppIcon.iconset
ICON := $(ICON_DIR)/AppIcon.icns

# The app configuration key ensures changing any embedded build setting selects
# a new app target, even when all input files are older than the existing app.
APP_CONFIGURATION_KEY := $(shell printf '%s\0%s\0%s' \
  "$(ICON_SOURCE)" \
  "$(SMTH_NOTIFIER_TERMINAL_BINARY)" \
  "$(SMTH_NOTIFIER_TERMINAL_BUNDLE_IDENTIFIER)" \
  | shasum -a 256 | cut -d ' ' -f 1)

# Escape spaces when using the configurable source path as a prerequisite.
empty :=
space := $(empty) $(empty)
escape_spaces = $(subst $(space),\$(space),$(1))
ICON_SOURCE_PREREQUISITE := $(call escape_spaces,$(ICON_SOURCE))

# Keeping the variant stamp inside the bundle makes deleting the bundle or
# switching build settings invalidate the app target without freshness logic.
APP_STAMP := $(RESOURCES)/BuildStamp-$(APP_CONFIGURATION_KEY)
APP_STAMP_TARGET := $(call escape_spaces,$(APP_STAMP))

SMTH_NOTIFIER_INSTALL_DIR ?= $(HOME)/Applications
INSTALLED_APP := $(SMTH_NOTIFIER_INSTALL_DIR)/$(NAME).app
INSTALLED_EXECUTABLE := $(INSTALLED_APP)/Contents/MacOS/$(EXECUTABLE_NAME)
INSTALLED_STAMP := $(INSTALLED_APP)/Contents/Resources/BuildStamp-$(APP_CONFIGURATION_KEY)
INSTALLED_STAMP_TARGET := $(call escape_spaces,$(INSTALLED_STAMP))

LAUNCH_SERVICES := /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister

.DEFAULT_GOAL := help
.DELETE_ON_ERROR:

# These are user-facing aliases or actions. The build aliases have no recipes;
# Make caches their concrete file prerequisites.
.PHONY: help build icon app install authorize clean

help:
	@printf '%s\n' \
	  'Available targets:' \
	  '  build      Build the executable when its inputs change' \
	  '  icon       Generate the icon when its source changes' \
	  '  app        Build and sign the app when its inputs change' \
	  '  install    Install and register the app when it changes' \
	  '  authorize  Request notification permission' \
	  '  clean      Remove build products'

build: $(EXECUTABLE)

$(EXECUTABLE): $(PACKAGE_INPUTS) $(SWIFT_INPUTS) $(SWIFT_SOURCE_DIRS)
	swift build -c release
	@test -x "$@"
	@touch "$@"

icon: $(ICON)

$(ICON): $(ICON_SOURCE_PREREQUISITE)
	@rm -rf "$(ICONSET)"
	@mkdir -p "$(ICONSET)"
	@sips --setProperty format png --resampleHeightWidth 16 16 "$(ICON_SOURCE)" --out "$(ICONSET)/icon_16x16.png" >/dev/null
	@sips --setProperty format png --resampleHeightWidth 32 32 "$(ICON_SOURCE)" --out "$(ICONSET)/icon_16x16@2x.png" >/dev/null
	@sips --setProperty format png --resampleHeightWidth 32 32 "$(ICON_SOURCE)" --out "$(ICONSET)/icon_32x32.png" >/dev/null
	@sips --setProperty format png --resampleHeightWidth 64 64 "$(ICON_SOURCE)" --out "$(ICONSET)/icon_32x32@2x.png" >/dev/null
	@sips --setProperty format png --resampleHeightWidth 128 128 "$(ICON_SOURCE)" --out "$(ICONSET)/icon_128x128.png" >/dev/null
	@sips --setProperty format png --resampleHeightWidth 256 256 "$(ICON_SOURCE)" --out "$(ICONSET)/icon_128x128@2x.png" >/dev/null
	@sips --setProperty format png --resampleHeightWidth 256 256 "$(ICON_SOURCE)" --out "$(ICONSET)/icon_256x256.png" >/dev/null
	@sips --setProperty format png --resampleHeightWidth 512 512 "$(ICON_SOURCE)" --out "$(ICONSET)/icon_256x256@2x.png" >/dev/null
	@sips --setProperty format png --resampleHeightWidth 512 512 "$(ICON_SOURCE)" --out "$(ICONSET)/icon_512x512.png" >/dev/null
	@sips --setProperty format png --resampleHeightWidth 1024 1024 "$(ICON_SOURCE)" --out "$(ICONSET)/icon_512x512@2x.png" >/dev/null
	@iconutil --convert icns "$(ICONSET)" --output "$@"
	@rm -rf "$(ICONSET)"
	@echo "Built $@"

app: $(APP_STAMP_TARGET)

$(APP_STAMP_TARGET): $(EXECUTABLE) $(ICON) App/Info.plist
	rm -rf "$(APP)"
	mkdir -p "$(MACOS)" "$(RESOURCES)"
	cp "$(EXECUTABLE)" "$(MACOS)/$(EXECUTABLE_NAME)"
	cp App/Info.plist "$(CONTENTS)/Info.plist"
	plutil -replace SmthNotifierTerminalBinary -string "$(SMTH_NOTIFIER_TERMINAL_BINARY)" "$(CONTENTS)/Info.plist"
	plutil -replace SmthNotifierTerminalBundleIdentifier -string "$(SMTH_NOTIFIER_TERMINAL_BUNDLE_IDENTIFIER)" "$(CONTENTS)/Info.plist"
	cp "$(ICON)" "$(RESOURCES)/AppIcon.icns"
	printf 'APPL????' > "$(CONTENTS)/PkgInfo"
	@touch "$(APP_STAMP)"
	codesign --force --sign - "$(APP)"
	xattr -dr com.apple.quarantine "$(APP)" 2>/dev/null || true
	codesign --verify --strict --verbose=2 "$(APP)"
	@echo "Built $(APP)"

install: $(INSTALLED_STAMP_TARGET)

$(INSTALLED_STAMP_TARGET): $(APP_STAMP_TARGET)
	mkdir -p "$(SMTH_NOTIFIER_INSTALL_DIR)"
	rm -rf "$(INSTALLED_APP)"
	ditto "$(APP)" "$(INSTALLED_APP)"
	"$(LAUNCH_SERVICES)" -f "$(INSTALLED_APP)"
	@echo "Installed $(INSTALLED_APP)"

authorize:
	"$(INSTALLED_EXECUTABLE)" authorize

clean:
	rm -rf "$(BUILD_DIR)"
