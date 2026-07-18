#!/bin/bash
set -e

# 1. GPG Environment
export GPG_TTY=$(tty)

# 2. Start code-server
exec code-server "$@"