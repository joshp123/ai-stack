---
name: xcodebuildmcp-cli
description: Official skill for the XcodeBuildMCP CLI. Use when doing iOS/macOS/watchOS/tvOS/visionOS work (build, test, run, debug, log, UI automation).
---

# XcodeBuildMCP CLI

This skill is for AI agents. It positions the XcodeBuildMCP CLI as a low‑overhead alternative to MCP tool calls: agents can already run shell commands, and the CLI exposes the same tool surface without the schema‑exchange cost. Prefer the CLI over raw `xcodebuild`, `xcrun`, or `simctl`.

## When To Use This CLI (Capabilities And Workflows)

- When you need build/test/run/debugging/logging/UI automation capabilities.
- When you want simulator/device management capabilities.
- When you want AI optimized tools and tool responses.
- When you need project discovery capabilities (schemes, bundle IDs, app paths).

## Command Discovery

Use `--help` to discover workflows, tools, and arguments.

```bash
mobilebuildmcp --help
mobilebuildmcp tools --help
mobilebuildmcp tools --json
mobilebuildmcp <workflow> --help
mobilebuildmcp <workflow> <tool> --help
```

Notes:
- Use `--json '{...}'` for complex arguments and `--output json` if you need machine-readable results (not recommended).

## Common Workflows

### Build And Run On Simulator

If your intent is to run the app in Simulator, use `build-and-run` directly. It already performs the build step.
Do not run `build` first unless the user explicitly requests both commands.

1. List simulators and pick a device name or UDID.
2. Build and run.

If app and project details are not known:
```bash
mobilebuildmcp simulator discover-projects --workspace-root .
mobilebuildmcp simulator list-schemes --project-path ./MyApp.xcodeproj
mobilebuildmcp simulator list
```

To build, install and launch the app in one command:
```bash
mobilebuildmcp simulator build-and-run --scheme MyApp --project-path ./MyApp.xcodeproj --simulator-name "iPhone 17 Pro"
```

### Build only

Use this only when you want compile feedback and do not want to launch the app.
For run/launch intent, use `build-and-run` instead of chaining `build` and `build-and-run`.

```bash
mobilebuildmcp simulator build --scheme MyApp --project-path ./MyApp.xcodeproj --simulator-name "iPhone 17 Pro"
```

### Run Tests

When you need to run tests, you can do so with the `test` tool.

```bash
mobilebuildmcp simulator test --scheme MyAppTests --project-path ./MyApp.xcodeproj --simulator-name "iPhone 17 Pro"
```

### Install And Launch On Physical Device

```bash
mobilebuildmcp device list
mobilebuildmcp device build --scheme MyApp --project-path ./MyApp.xcodeproj
mobilebuildmcp device get-app-path --scheme MyApp --project-path ./MyApp.xcodeproj
mobilebuildmcp device get-app-bundle-id --app-path /path/to/MyApp.app
mobilebuildmcp device install --device-id DEVICE_UDID --app-path /path/to/MyApp.app
mobilebuildmcp device launch --device-id DEVICE_UDID --bundle-id io.sentry.MyApp
```

### Capture Logs On Simulator

```bash
mobilebuildmcp logging start-simulator-log-capture --simulator-id SIMULATOR_UDID --bundle-id io.sentry.MyApp
mobilebuildmcp logging stop-simulator-log-capture --log-session-id LOG_SESSION_ID
```

### Debug A Running App (Simulator)

1. Launch the app.
2. Attach the debugger after the app is fully launched.

Launch if not already running:
```bash
mobilebuildmcp simulator launch-app --bundle-id io.sentry.MyApp --simulator-id SIMULATOR_UDID
```

Attach the debugger:

It's generally a good idea to wait for 1-2s for the app to fully launch before attaching the debugger.

```bash
mobilebuildmcp debugging attach --bundle-id io.sentry.MyApp --simulator-id SIMULATOR_UDID
```

To add/remove breakpoints, inspect stack/variables, and issue arbitrary LLDB commands, view debugging help:
```bash
mobilebuildmcp debugging --help
```


### Inspect UI And Automate Input

Snapshot UI accessibility tree, tap/swipe/type, and capture screenshots:

```bash
mobilebuildmcp ui-automation snapshot-ui --simulator-id SIMULATOR_UDID
mobilebuildmcp ui-automation tap --simulator-id SIMULATOR_UDID --label "Submit"
mobilebuildmcp ui-automation tap --simulator-id SIMULATOR_UDID --id "SubmitButton"
# Coordinate fallback when label/id is unavailable
mobilebuildmcp ui-automation tap --simulator-id SIMULATOR_UDID --x 200 --y 400
mobilebuildmcp ui-automation type-text --simulator-id SIMULATOR_UDID --text "hello"
mobilebuildmcp ui-automation screenshot --simulator-id SIMULATOR_UDID --return-format path
```

To see all UI automation tools, view UI automation help:
```bash
mobilebuildmcp ui-automation --help
```

### macOS App Build/Run

```bash
mobilebuildmcp macos build --scheme MyMacApp --project-path ./MyMacApp.xcodeproj
mobilebuildmcp macos build-and-run --scheme MyMacApp --project-path ./MyMacApp.xcodeproj
```

To see all macOS tools, view macOS help:
```bash
mobilebuildmcp macos --help
```

### SwiftPM Package Workflows

```bash
mobilebuildmcp swift-package list
mobilebuildmcp swift-package build --package-path ./MyPackage
mobilebuildmcp swift-package test --package-path ./MyPackage
```

To see all SwiftPM tools, view SwiftPM help:
```bash
mobilebuildmcp swift-package --help
```

### Project Discovery

```bash
mobilebuildmcp project-discovery discover-projects --workspace-root .
mobilebuildmcp project-discovery list-schemes --project-path ./MyApp.xcodeproj
mobilebuildmcp project-discovery get-app-bundle-id --app-path ./Build/MyApp.app
```

To see all project discovery tools, view project discovery help:
```bash
mobilebuildmcp project-discovery --help
```

### Scaffolding new projects

It's worth viewing the --help for the scaffolding tools to see the available options.
Here are some minimal examples:

```bash
mobilebuildmcp project-scaffolding scaffold-ios --project-name MyApp --output-path ./Projects
mobilebuildmcp project-scaffolding scaffold-macos --project-name MyMacApp --output-path ./Projects
```

To see all project scaffolding tools, view project scaffolding help:
```bash
mobilebuildmcp project-scaffolding --help
```

## Daemon Notes (Stateful Tools)

Stateful tools (logs, debug, video recording, background run) go through a per-workspace daemon that auto-starts, if you find you are getting errors with the stateful tools, you can manage the daemon process manually.

```bash
mobilebuildmcp daemon status
mobilebuildmcp daemon restart
```

To see all daemon commands, view daemon help:
```bash
mobilebuildmcp daemon --help
```
