#!/bin/bash

# Stop immediately if any command fails
set -e

# ─────────────────────────────────────────────
# 🎨 Colors
# ─────────────────────────────────────────────

RESET='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'

GREEN='\033[32m'
CYAN='\033[36m'
BLUE='\033[34m'
YELLOW='\033[33m'
RED='\033[31m'
WHITE='\033[97m'

# ─────────────────────────────────────────────
# 📋 Helpers
# ─────────────────────────────────────────────

line() {
    echo -e "${DIM}────────────────────────────────────────────────────${RESET}"
}

success() {
    echo -e "  ${GREEN}✔${RESET} $1"
}

info() {
    echo -e "  ${CYAN}›${RESET} $1"
}

error() {
    echo -e "  ${RED}✖${RESET} $1"
}

# ─────────────────────────────────────────────
# 🚀 Header
# ─────────────────────────────────────────────

clear

echo ""
echo -e "${BOLD}${CYAN}       G I T   P U S H${RESET}"
echo -e "${DIM}       Commit & deploy your changes${RESET}"
echo ""

line

# ─────────────────────────────────────────────
# 📝 Validate commit message
# ─────────────────────────────────────────────

if [ -z "$1" ]; then
    echo ""
    error "No commit message provided."
    echo ""
    echo -e "  ${DIM}Usage:${RESET}"
    echo -e "  ${YELLOW}./push.sh \"feat: implement WebRTC media support\"${RESET}"
    echo ""
    exit 1
fi

COMMIT_MESSAGE="$1"

# ─────────────────────────────────────────────
# 📦 Git Add
# ─────────────────────────────────────────────

echo ""
info "Staging changes..."
git add .
success "Changes staged"

# ─────────────────────────────────────────────
# 📝 Git Commit
# ─────────────────────────────────────────────

echo ""
info "Creating commit..."

git commit -m "$COMMIT_MESSAGE"

success "Commit created"
echo -e "  ${DIM}\"${COMMIT_MESSAGE}\"${RESET}"

# ─────────────────────────────────────────────
# 🚀 Git Push
# ─────────────────────────────────────────────

echo ""
info "Pushing to ${BOLD}origin/main${RESET}..."

git push origin main

success "Changes pushed successfully"

# ─────────────────────────────────────────────
# 🎉 Complete
# ─────────────────────────────────────────────

echo ""
line

echo ""
echo -e "  ${GREEN}${BOLD}✨ All done! Your changes are on main. 🚀${RESET}"
echo ""

line

echo ""