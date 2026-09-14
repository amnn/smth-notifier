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

SMTH_NOTIFIER_ICON ?= App/Notifier.svg
ICON_SOURCE := $(SMTH_NOTIFIER_ICON)

# Keep each configured source in its own build directory so switching
# SMTH_NOTIFIER_ICON also selects a distinct Make target.
ICON_SOURCE_KEY := $(shell printf '%s' "$(ICON_SOURCE)" | shasum -a 256 | cut -d ' ' -f 1)
ICON_DIR := $(BUILD_DIR)/icons/$(ICON_SOURCE_KEY)
ICONSET := $(ICON_DIR)/AppIcon.iconset
ICON := $(ICON_DIR)/AppIcon.icns

# Escape spaces when using a path as a prerequisite.
EMPTY :=
SPACE := $(EMPTY) $(EMPTY)
ESCAPE_SPACES = $(subst $(SPACE),\$(SPACE),$(1))
ICON_SOURCE_PREREQUISITE := $(call ESCAPE_SPACES,$(ICON_SOURCE))

# Keeping the build stamp inside the bundle makes deleting the bundle or
# switching icons invalidate the bundle without freshness logic.
APP_STAMP := $(RESOURCES)/BuildStamp-$(ICON_SOURCE_KEY)
APP_STAMP_TARGET := $(call ESCAPE_SPACES,$(APP_STAMP))

.DEFAULT_GOAL := bundle
.DELETE_ON_ERROR:

# These aliases expose Make's incremental artifacts to the justfile.
.PHONY: build icon bundle clean

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

bundle: $(APP_STAMP_TARGET)

$(APP_STAMP_TARGET): $(EXECUTABLE) $(ICON) App/Info.plist
	rm -rf "$(APP)"
	mkdir -p "$(MACOS)" "$(RESOURCES)"
	cp "$(EXECUTABLE)" "$(MACOS)/$(EXECUTABLE_NAME)"
	cp App/Info.plist "$(CONTENTS)/Info.plist"
	cp "$(ICON)" "$(RESOURCES)/AppIcon.icns"
	@touch "$(APP_STAMP)"
	@echo "Built $(APP)"

clean:
	rm -rf "$(BUILD_DIR)"
