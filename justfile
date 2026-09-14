# Copyright (c) Ashok Menon
# SPDX-License-Identifier: Apache-2.0

set shell := ["bash", "-euo", "pipefail", "-c"]

NAME := "smth notifier"
APP := ".build/" + NAME + ".app"
INSTALL_DIR := env("SMTH_NOTIFIER_INSTALL_DIR", env("HOME") + "/Applications")
INSTALLED_APP := INSTALL_DIR + "/" + NAME + ".app"
INSTALLED_EXECUTABLE := INSTALLED_APP + "/Contents/MacOS/smth-notifier"
LAUNCH_SERVICES := "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

# List the available recipes.
default:
    @just --list

# Build the executable incrementally.
build:
    make build

# Generate the app icon incrementally.
icon:
    make icon

# Assemble the app bundle incrementally without signing it.
bundle:
    make bundle

# Assemble and ad-hoc sign the local app.
app: bundle
    just sign-app

# Sign an app with the requested identity, defaulting to an ad-hoc signature.
sign-app APP_PATH=APP CODE_SIGN_IDENTITY="-":
    codesign --force --sign "{{ CODE_SIGN_IDENTITY }}" --timestamp=none "{{ APP_PATH }}"
    just verify-app "{{ APP_PATH }}"
    @echo "Signed {{ APP_PATH }}"

# Verify an app's sealed contents and signature.
verify-app APP_PATH=APP:
    codesign --verify --strict --verbose=4 "{{ APP_PATH }}"

# Build, sign, install, and register the app.
install: app
    mkdir -p "{{ INSTALL_DIR }}"
    rm -rf "{{ INSTALLED_APP }}"
    ditto "{{ APP }}" "{{ INSTALLED_APP }}"
    "{{ LAUNCH_SERVICES }}" -f "{{ INSTALLED_APP }}"
    @echo "Installed {{ INSTALLED_APP }}"

# Request notification permission from the installed app.
authorize:
    "{{ INSTALLED_EXECUTABLE }}" authorize

# Remove all build products.
clean:
    make clean
