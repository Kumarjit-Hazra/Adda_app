#!/bin/bash

# ═══════════════════════════════════════════════════════════
#  PUSH — a polished git commit & deploy CLI
# ═══════════════════════════════════════════════════════════

set -e

# ─────────────────────────────────────────────
# 🎨 Colors & Styles
# ─────────────────────────────────────────────

RESET='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'
ITALIC='\033[3m'

GREEN='\033[32m'
CYAN='\033[36m'
BLUE='\033[34m'
MAGENTA='\033[35m'
YELLOW='\033[33m'
RED='\033[31m'
WHITE='\033[97m'
GRAY='\033[90m'

BG_GREEN='\033[42m'
BG_RED='\033[41m'

# Hide cursor on start, always restore on exit
tput civis 2>/dev/null || true
trap 'tput cnorm 2>/dev/null || true' EXIT INT TERM

# ─────────────────────────────────────────────
# 📋 Helpers
# ─────────────────────────────────────────────

line() {
    echo -e "${DIM}──────────────────────────────────────────────────────${RESET}"
}

success() { echo -e "  ${GREEN}✔${RESET} $1"; }
info()    { echo -e "  ${CYAN}›${RESET} $1"; }
warn()    { echo -e "  ${YELLOW}⚠${RESET} $1"; }
error()   { echo -e "  ${RED}✖${RESET} $1"; }

# Typewriter effect for headers
type_out() {
    local text="$1"
    local delay="${2:-0.012}"
    for (( i=0; i<${#text}; i++ )); do
        printf "%s" "${text:$i:1}"
        sleep "$delay"
    done
    printf "\n"
}

# Spinner that runs while a background command executes.
# Usage: run_with_spinner "Label text" -- git add .
run_with_spinner() {
    local label="$1"; shift
    shift # discard the "--"
    local frames=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)
    local start_time
    start_time=$(date +%s%N)

    local logfile
    logfile=$(mktemp)

    ( "$@" > "$logfile" 2>&1 )
    local status=$?

    # simulate a brief animated pass even for fast commands, so
    # the spinner is perceptible and the tool feels alive
    local i=0
    local elapsed_ms=0
    while [ $elapsed_ms -lt 350 ]; do
        printf "\r  ${CYAN}%s${RESET} %s" "${frames[$((i % ${#frames[@]}))]}" "$label"
        sleep 0.035
        i=$((i + 1))
        elapsed_ms=$((elapsed_ms + 35))
    done

    local end_time
    end_time=$(date +%s%N)
    local duration_ms=$(( (end_time - start_time) / 1000000 ))

    if [ $status -eq 0 ]; then
        printf "\r  ${GREEN}✔${RESET} %s ${GRAY}(%sms)${RESET}\n" "$label" "$duration_ms"
    else
        printf "\r  ${RED}✖${RESET} %s ${GRAY}(%sms)${RESET}\n" "$label" "$duration_ms"
        echo ""
        echo -e "  ${RED}${BOLD}Command failed:${RESET}"
        sed 's/^/    /' "$logfile"
        rm -f "$logfile"
        tput cnorm 2>/dev/null || true
        exit $status
    fi

    rm -f "$logfile"
}

progress_bar() {
    local pct=$1
    local width=30
    local filled=$(( pct * width / 100 ))
    local empty=$(( width - filled ))
    printf "  ["
    printf "%${filled}s" | tr ' ' '█'
    printf "%${empty}s" | tr ' ' '░'
    printf "] %3d%%\r" "$pct"
}

# ─────────────────────────────────────────────
# 🚀 Header
# ─────────────────────────────────────────────

clear
echo ""
echo -e "${BOLD}${MAGENTA}   ██████╗ ██╗   ██╗███████╗██╗  ██╗${RESET}"
echo -e "${BOLD}${MAGENTA}   ██╔══██╗██║   ██║██╔════╝██║  ██║${RESET}"
echo -e "${BOLD}${CYAN}   ██████╔╝██║   ██║███████╗███████║${RESET}"
echo -e "${BOLD}${CYAN}   ██╔═══╝ ██║   ██║╚════██║██╔══██║${RESET}"
echo -e "${BOLD}${BLUE}   ██║     ╚██████╔╝███████║██║  ██║${RESET}"
echo -e "${BOLD}${BLUE}   ╚═╝      ╚═════╝ ╚══════╝╚═╝  ╚═╝${RESET}"
echo -e "   ${DIM}${ITALIC}commit & deploy, without the ceremony${RESET}"
echo ""
line

# ─────────────────────────────────────────────
# 🔍 Pre-flight checks
# ─────────────────────────────────────────────

echo ""
info "Running pre-flight checks..."

if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    error "Not inside a git repository."
    exit 1
fi
success "Git repository detected"

BRANCH=$(git rev-parse --abbrev-ref HEAD)
success "On branch ${BOLD}${BRANCH}${RESET}"

if git diff --quiet && git diff --cached --quiet && [ -z "$(git status --porcelain)" ]; then
    echo ""
    warn "No changes to commit. Working tree is clean."
    echo ""
    exit 0
fi

CHANGED_FILES=$(git status --porcelain | wc -l | tr -d ' ')
success "${CHANGED_FILES} file(s) changed"

# ─────────────────────────────────────────────
# 📝 Commit message
# ─────────────────────────────────────────────

echo ""
if [ -z "$1" ]; then
    echo -e "  ${DIM}Usage:${RESET}  ${YELLOW}./push.sh \"feat: implement WebRTC media support\"${RESET}"
    echo ""
    printf "  ${CYAN}?${RESET} Enter a commit message: "
    read -r COMMIT_MESSAGE
    if [ -z "$COMMIT_MESSAGE" ]; then
        error "No commit message provided. Aborting."
        exit 1
    fi
else
    COMMIT_MESSAGE="$1"
fi

echo ""
line
echo ""
echo -e "  ${BOLD}${WHITE}Summary${RESET}"
echo -e "  ${GRAY}Branch:${RESET}  ${BRANCH}"
echo -e "  ${GRAY}Files:${RESET}   ${CHANGED_FILES} changed"
echo -e "  ${GRAY}Message:${RESET} ${ITALIC}\"${COMMIT_MESSAGE}\"${RESET}"
echo ""
line

# ─────────────────────────────────────────────
# 📦 Stage → Commit → Push
# ─────────────────────────────────────────────

echo ""
run_with_spinner "Staging changes"    -- git add .
run_with_spinner "Creating commit"    -- git commit -m "$COMMIT_MESSAGE"
echo ""
info "Pushing to ${BOLD}origin/${BRANCH}${RESET}..."
echo ""

# Fake but smooth progress bar for the push step
for pct in 10 25 40 55 70 85 100; do
    progress_bar "$pct"
    sleep 0.06
done
echo ""

run_with_spinner "Pushing to origin/${BRANCH}" -- git push origin "$BRANCH"

# ─────────────────────────────────────────────
# 🎉 Done
# ─────────────────────────────────────────────

COMMIT_HASH=$(git rev-parse --short HEAD)

echo ""
line
echo ""
echo -e "  ${BG_GREEN}${WHITE}${BOLD} SUCCESS ${RESET}  Your changes are live on ${BOLD}${BRANCH}${RESET}"
echo ""
echo -e "  ${GRAY}Commit:${RESET}  ${GREEN}${COMMIT_HASH}${RESET}"
echo -e "  ${GRAY}Branch:${RESET}  ${BRANCH}"
echo -e "  ${GRAY}Message:${RESET} ${COMMIT_MESSAGE}"
echo ""
line
echo ""
echo -e "  ${MAGENTA}✨ Shipped. Go build the next thing. 🚀${RESET}"
echo ""

tput cnorm 2>/dev/null || true