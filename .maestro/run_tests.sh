#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════
# Nexus Shield — Maestro Test Runner
# ═══════════════════════════════════════════════════════════════════
#
# Usage:
#   ./run_tests.sh                    # Run all tests
#   ./run_tests.sh --tag hypothesis   # Run only hypothesis tests
#   ./run_tests.sh --tag smoke        # Run only smoke tests
#   ./run_tests.sh --flow 10          # Run specific flow by number
#   ./run_tests.sh --install          # Install Maestro CLI first
#
# Prerequisites:
#   - Maestro CLI installed (https://maestro.mobile.dev)
#   - iOS Simulator running with Nexus Shield app installed
#   - Or physical device connected via USB
#
# ═══════════════════════════════════════════════════════════════════

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLOWS_DIR="${SCRIPT_DIR}/flows"
APP_ID="com.nexus.shield"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_banner() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  NEXUS SHIELD — Maestro Test Suite${NC}"
    echo -e "${CYAN}  Hypothesis: Shield blocks AI transcription${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
    echo ""
}

install_maestro() {
    echo -e "${YELLOW}Installing Maestro CLI...${NC}"
    curl -Ls "https://get.maestro.mobile.dev" | bash
    echo -e "${GREEN}Maestro installed.${NC}"
    export PATH="$PATH:$HOME/.maestro/bin"
}

check_maestro() {
    if ! command -v maestro &> /dev/null; then
        echo -e "${RED}Maestro CLI not found.${NC}"
        echo "Install with: curl -Ls 'https://get.maestro.mobile.dev' | bash"
        echo "Or run: $0 --install"
        exit 1
    fi
    echo -e "${GREEN}Maestro CLI: $(maestro --version 2>/dev/null || echo 'installed')${NC}"
}

run_all() {
    echo -e "${CYAN}Running all 12 test flows...${NC}"
    echo ""
    maestro test "${FLOWS_DIR}"
}

run_tag() {
    local tag="$1"
    echo -e "${CYAN}Running flows tagged: ${tag}${NC}"
    echo ""
    maestro test "${FLOWS_DIR}" --include-tags="${tag}"
}

run_flow() {
    local flow_num="$1"
    local flow_file
    flow_file=$(find "${FLOWS_DIR}" -name "${flow_num}_*" -o -name "0${flow_num}_*" | head -1)
    if [[ -z "$flow_file" ]]; then
        echo -e "${RED}Flow ${flow_num} not found.${NC}"
        exit 1
    fi
    echo -e "${CYAN}Running: $(basename "$flow_file")${NC}"
    echo ""
    maestro test "$flow_file"
}

# ── Main ─────────────────────────────────────────────────────────

print_banner

case "${1:-}" in
    --install)
        install_maestro
        ;;
    --tag)
        check_maestro
        run_tag "${2:?Usage: $0 --tag <tag>}"
        ;;
    --flow)
        check_maestro
        run_flow "${2:?Usage: $0 --flow <number>}"
        ;;
    --hypothesis)
        check_maestro
        echo -e "${YELLOW}Running HYPOTHESIS tests only...${NC}"
        run_tag "hypothesis"
        ;;
    --e2e)
        check_maestro
        echo -e "${YELLOW}Running full E2E call-blocking test...${NC}"
        run_flow "10"
        ;;
    --help|-h)
        echo "Usage:"
        echo "  $0                    Run all 12 test flows"
        echo "  $0 --install          Install Maestro CLI"
        echo "  $0 --tag <tag>        Run flows by tag"
        echo "  $0 --flow <number>    Run specific flow (1-12)"
        echo "  $0 --hypothesis       Run hypothesis tests only"
        echo "  $0 --e2e              Run full E2E call-blocking test"
        echo ""
        echo "Tags: onboarding, shield, core, hypothesis, tiers,"
        echo "      jam-score, critical, settings, techniques,"
        echo "      routing, diagnostics, metrics, proof, analytics,"
        echo "      session, privacy, e2e, call-blocking, pricing,"
        echo "      free, account, data, destructive, smoke"
        ;;
    *)
        check_maestro
        run_all
        ;;
esac

echo ""
echo -e "${GREEN}Done.${NC}"
