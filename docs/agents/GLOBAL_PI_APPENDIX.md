---

# Pi Harness Guidance

- In the pi coding harness, background bash is not supported; long-running or blocking commands (dev servers, tails) should run in `tmux` instead so the user shell stays unblocked.
