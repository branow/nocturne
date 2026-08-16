# nocturne

Keep your Mac awake — a menu bar app **and** a CLI in a single binary. No App
Store, no Apple account. An open, scriptable alternative to Amphetamine and
Caffeine.

## Install

```bash
brew tap branow/nocturne https://github.com/branow/nocturne
brew install nocturne
brew services start nocturne   # runs the menu-bar daemon, restarts at login
```

Or build from source:

```bash
swift build -c release
.build/release/nocturne daemon &
```

## Usage

```bash
nocturne on 2h             # stay fully awake (screen on) for 2 hours
nocturne on 90m            # ...or 90m / 45s / a raw number of seconds
nocturne on --until 18:00  # awake until a clock time
nocturne on 2h -i          # keep the system awake but let the display sleep
nocturne on                # awake until you turn it off
nocturne toggle            # flip on/off
nocturne status            # is it on? how much time is left?
nocturne off               # stop, restore normal sleep
```

`on` and `toggle` auto-start the daemon if it isn't already running.

## Modes

- **full** (default) — display stays on, system awake.
- **system** (`-i` / `--no-display`) — system stays awake, display may sleep.

## How it works

A single `nocturne` binary plays two roles:

- **Daemon** (`nocturne daemon`) — a menu-bar app that holds a native IOKit power
  assertion and owns all state. Managed by `brew services`.
- **CLI** (`nocturne on|off|toggle|status`) — thin commands that message the
  running daemon over a Unix socket at `~/.nocturne.sock`.

Both faces drive the same source of truth, so the menu bar and the terminal
never disagree. The engine calls `IOPMAssertionCreateWithName` directly — no
`caffeinate` subprocess.

## Releasing

```bash
git tag v0.1.0 && git push origin v0.1.0
```

CI builds a universal (arm64 + x86_64) binary, publishes a GitHub release with
the tarball, and rewrites `Formula/nocturne.rb` on `main`. Keep
`Sources/nocturne/Version.swift` in sync with the tag.

## License

[MIT](LICENSE)
