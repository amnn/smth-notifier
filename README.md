# smth notifier

A small macOS notification bridge for `smth`.

It sends silent notifications for agent state changes. When `--terminal` is
provided, clicking a notification switches the associated tmux client to the
requested pane, then activates the configured terminal application.

## Install

```sh
brew install just
just install
just authorize
```

The app is built locally, ad-hoc signed, and installed to
`~/Applications/smth notifier.app`. Set `SMTH_NOTIFIER_INSTALL_DIR` to install
it elsewhere. Because the app is built locally rather than downloaded, macOS
can launch it from Notification Center without a Developer ID signature.

The checked-in `App/Notifier.svg` is used by default. The icon can be changed
at build time:

```sh
SMTH_NOTIFIER_ICON="$HOME/.config/smth/notifier.svg" just install
```

`SMTH_NOTIFIER_ICON` may name any image supported by `sips`.

Useful targets:

```sh
just build      # build the executable incrementally
just icon       # generate the app icon incrementally
just bundle     # assemble the app bundle incrementally without signing
just app        # assemble and ad-hoc sign the app
just install    # build, sign, install, and register the app
just authorize  # request notification permission for the installed app
just clean      # remove build products
```

## Configure smth

```toml
[notification]
clear = [
  "/Users/you/Applications/smth notifier.app/Contents/MacOS/smth-notifier",
  "clear",
  "smth:{pane}",
]

notify = [
  "/Users/you/Applications/smth notifier.app/Contents/MacOS/smth-notifier",
  "send",
  "--title", "{title}",
  "--message", "{message}",
  "--identifier", "smth:{pane}",
  "--socket", "{socket}",
  "--tty", "{tty}",
  "--pane", "{pane}",
  "--terminal", "com.apple.Terminal",
]
```

Set `--terminal` to your terminal application's reverse-domain bundle identifier,
for example `com.apple.Terminal` for Terminal or `com.mitchellh.ghostty` for Ghostty.
The same app build works with any terminal. Omit `--terminal` to send notifications
without click-to-focus.

Both commands use the same `smth:{pane}` identifier. When an agent publishes a
`running` lifecycle update, `smth` invokes `clear` and removes only that pane's
pending or delivered notification.

## Commands

```text
smth-notifier authorize
smth-notifier status
smth-notifier clear [IDENTIFIER]
smth-notifier focus --socket PATH --tty PATH --pane ID [--terminal BUNDLE_ID]
smth-notifier send --title TEXT --message TEXT --identifier ID \
  --socket PATH --tty PATH --pane ID [--terminal BUNDLE_ID]
```

Notification messages are parsed as inline Markdown before delivery. Formatting
markers are removed while text, whitespace, link labels, and block markers are
preserved for Notification Center's plain-text body.

The `send` and `focus` commands accept an optional `--terminal` bundle identifier;
executable names are not accepted as a fallback. Without it, notifications still
appear, but clicking them does nothing and `focus` is a no-op.

The notifier resolves `tmux` from the sending process's `PATH` and stores the
absolute path and optional terminal bundle identifier with each notification.
When a terminal is provided, the click handler activates the first running
application with that bundle identifier, even if macOS launches a fresh notifier
process to handle the click. It deliberately does not distinguish among multiple
terminal windows, tabs, or splits.
