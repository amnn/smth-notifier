# smth notifier

A small macOS notification bridge for `smth`.

It sends silent notifications for agent state changes. Clicking a notification
switches the associated tmux client to the requested pane, then activates the
configured terminal application.

## Install

```sh
make install
make authorize
```

The app is built locally, ad-hoc signed, and installed to
`~/Applications/smth notifier.app`. Set `SMTH_NOTIFIER_INSTALL_DIR` to install
it elsewhere. Because the app never acquires a quarantine attribute, macOS can
launch it from Notification Center without a Developer ID signature.

The checked-in `App/Notifier.svg` and macOS Terminal are used by default. The
icon, terminal executable, and reverse-domain bundle identifier can be changed
at build time:

```sh
SMTH_NOTIFIER_ICON="$HOME/.config/smth/notifier.svg" \
SMTH_NOTIFIER_TERMINAL_BINARY="ghostty" \
SMTH_NOTIFIER_TERMINAL_BUNDLE_IDENTIFIER="com.mitchellh.ghostty" \
make install
```

`SMTH_NOTIFIER_ICON` may name any image supported by `sips`.

Useful targets:

```sh
make build      # build the executable when Swift inputs change
make icon       # generate the app icon when its source changes
make app        # assemble and sign the app when its inputs change
make install    # install and register the app when it changes
make authorize  # request notification permission for the installed app
make clean      # remove build products
```

## Configure smth

```toml
[notification]
command = [
  "/Users/you/Applications/smth notifier.app/Contents/MacOS/smth-notifier",
  "send",
  "--title", "{title}",
  "--message", "{message}",
  "--identifier", "smth:{pane}",
  "--socket", "{socket}",
  "--tty", "{tty}",
  "--pane", "{pane}",
]
```

## Commands

```text
smth-notifier authorize
smth-notifier status
smth-notifier clear [IDENTIFIER]
smth-notifier focus --socket PATH --tty PATH --pane ID
smth-notifier send --title TEXT --message TEXT --identifier ID \
  --socket PATH --tty PATH --pane ID
```

The notifier resolves `tmux` from the sending process's `PATH` and stores the
absolute path with each notification. The click handler then activates the first
running application with the configured bundle identifier (or executable name
as a fallback). It deliberately does not distinguish among multiple terminal
windows, tabs, or splits.
