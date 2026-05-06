#!/usr/bin/env bash
# Output current power profile as 3-letter uppercase
powerprofilesctl get 2>/dev/null | cut -c1-3 | tr '[:lower:]' '[:upper:]'
