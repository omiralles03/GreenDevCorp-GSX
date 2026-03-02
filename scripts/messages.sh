#!/bin/bash

# Colors
R='\033[0;31m'
G='\033[0;32m'
Y='\033[1;33m'
B='\033[0;34m'
NC='\033[0m'

# Messages Formats
log() { echo -e "${B}[$(date +%T)]${NC} $1\n"; }
error() {
    echo -e "${R}[ERROR]${NC} $1\n"
    exit 1
}
info() { echo -e "${B}[INFO]${NC} $1\n"; }
success() { echo -e "${G}[SUCCESS]${NC} $1\n"; }
warning() { echo -e "${Y}[WARNING]${NC} $1\n"; }

# Wrapper for VBoxManage
vrun() {
    local out
    if ! out=$(VBoxManage "$@" 2>&1); then
        # error "${out#*error: }"
        echo -e "${R}[VBOX ERROR]${NC} ${out#*error: }"
        exit 1
    fi
    echo "$out" | grep -v "0%...10%" || true # Hide progress clutter
}

# Generic command wrapper
run_command() {
    local out
    if ! out=$("$@" 2>&1); then
        error "${out#*error: }"
    fi

    if [[ -n "$out" ]]; then
        log "$out" | grep -v "0%...10%" || true
    fi
}
