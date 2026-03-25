#!/usr/bin/env bash
# Outputs tmux environment variables as "NAME value" lines.
# Multi-line values are folded: embedded newlines become the literal string \n.
tmux show-environment "$@" | awk '
    /^-/ { next }
    /^[A-Za-z_][A-Za-z0-9_]*=/ {
        if (line != "") print line
        line = $0
        next
    }
    { line = line "\\n" $0 }
    END { if (line != "") print line }
' | sed 's/=/ /'
