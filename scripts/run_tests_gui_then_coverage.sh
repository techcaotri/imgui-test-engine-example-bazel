#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

echo -e "${MAGENTA}========================================${NC}"
echo -e "${MAGENTA}ImGui Test - GUI Inspection + Coverage${NC}"
echo -e "${MAGENTA}========================================${NC}"
echo -e ""
echo -e "${CYAN}This script runs tests in two phases:${NC}"
echo -e "  ${GREEN}Phase 1:${NC} Interactive GUI - Visual inspection"
echo -e "  ${GREEN}Phase 2:${NC} Headless mode - Accurate coverage"
echo -e ""

# Check if we have a display for GUI phase
if [ -z "$DISPLAY" ]; then
	echo -e "${YELLOW}No DISPLAY variable set - skipping GUI phase${NC}"
	USE_GUI=0
else
	USE_GUI=1
fi

# Check required tools
if ! command -v lcov &>/dev/null; then
	echo -e "${YELLOW}Installing lcov...${NC}"
	sudo apt-get update && sudo apt-get install -y lcov
fi

if ! command -v Xvfb &>/dev/null; then
	echo -e "${YELLOW}Installing xvfb...${NC}"
	sudo apt-get update && sudo apt-get install -y xvfb
fi

# ============================================
# PHASE 1: GUI Mode - Visual Inspection
# ============================================
if [ $USE_GUI -eq 1 ]; then
	echo -e ""
	echo -e "${BLUE}======================================${NC}"
	echo -e "${BLUE}Phase 1: GUI Mode (Visual Inspection)${NC}"
	echo -e "${BLUE}======================================${NC}"
	echo -e ""
	echo -e "${CYAN}Building GUI test application...${NC}"
	bazel build //:imgui_test_app

	echo -e ""
	echo -e "${YELLOW}Instructions for GUI Phase:${NC}"
	echo -e "  • ImGui Test Engine UI will open"
	echo -e "  • Tests run automatically with visual feedback"
	echo -e "  • Watch for any UI glitches or unexpected behavior"
	echo -e "  • Manually test interactions if needed"
	echo -e "  • Close window when done inspecting"
	echo -e ""
	echo -e "${CYAN}Press Enter to start GUI phase...${NC}"
	read

	echo -e "${GREEN}Launching GUI...${NC}"
	set +e
	./bazel-bin/imgui_test_app --test
	GUI_EXIT_CODE=$?
	set -e

	if [ $GUI_EXIT_CODE -eq 0 ]; then
		echo -e "${GREEN}✓ GUI phase completed${NC}"
	else
		echo -e "${YELLOW}⚠ GUI phase exited with code: $GUI_EXIT_CODE${NC}"
	fi

	echo -e ""
	echo -e "${CYAN}Ready for Phase 2 (automated coverage collection)${NC}"
	echo -e "${CYAN}Press Enter to continue...${NC}"
	read
else
	echo -e "${YELLOW}Skipping GUI phase (no display available)${NC}"
fi

# ============================================
# PHASE 2: Headless Mode - Coverage Collection
# ============================================
echo -e ""
echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}Phase 2: Headless Mode (Coverage)${NC}"
echo -e "${BLUE}======================================${NC}"
echo -e ""

# Start Xvfb for headless testing
echo -e "${GREEN}Starting virtual display (Xvfb)...${NC}"
DISPLAY_NUM=99

# Kill any existing Xvfb on :99
pkill -f "Xvfb :99" 2>/dev/null || true
sleep 1

Xvfb :${DISPLAY_NUM} -screen 0 1280x720x24 2>/dev/null &
XVFB_PID=$!
export DISPLAY=:${DISPLAY_NUM}
sleep 2

# Cleanup function
cleanup() {
	echo -e "${YELLOW}Cleaning up Xvfb...${NC}"
	kill $XVFB_PID 2>/dev/null || true
}
trap cleanup EXIT

echo -e "${GREEN}Display :${DISPLAY_NUM} ready${NC}"

# Run tests with coverage
echo -e "${GREEN}Running tests with coverage instrumentation...${NC}"
set +e
bazel coverage --config=coverage //:all_tests --combined_report=lcov
COVERAGE_EXIT_CODE=$?
set -e

if [ $COVERAGE_EXIT_CODE -ne 0 ]; then
	echo -e "${YELLOW}Warning: Coverage tests completed with errors${NC}"
fi

# Generate HTML coverage report
echo -e "${GREEN}Generating coverage report...${NC}"

OUTPUT_BASE=$(bazel info output_base 2>/dev/null)
WORKSPACE=$(pwd)
EXEC_ROOT=$(bazel info execution_root 2>/dev/null)
COVERAGE_FILE="$OUTPUT_BASE/execroot/_main/bazel-out/_coverage/_coverage_report.dat"

OUTPUT_DIR="coverage_report"
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR/html"

if [ -f "$COVERAGE_FILE" ] && [ -s "$COVERAGE_FILE" ]; then
	echo -e "${GREEN}Found coverage data${NC}"

	# Option 1: Show ALL coverage (workspace + external dependencies)
	echo -e "${CYAN}Generating full coverage report (all modules)...${NC}"

	# Run genhtml from exec root where external/ exists
	cd "$EXEC_ROOT"

	# Copy workspace files to exec root temporarily
	cp "$WORKSPACE/app_logic.cpp" . 2>/dev/null || true
	cp "$WORKSPACE/app_logic.h" . 2>/dev/null || true
	cp "$WORKSPACE/main.cpp" . 2>/dev/null || true

	genhtml "$COVERAGE_FILE" \
		--output-directory "$WORKSPACE/$OUTPUT_DIR/html" \
		--title "ImGui Test Coverage (All Modules)" \
		--legend \
		--show-details \
		--ignore-errors source \
		2>&1 | tee "$WORKSPACE/$OUTPUT_DIR/genhtml.log"

	# Clean up
	rm -f app_logic.cpp app_logic.h main.cpp
	cd "$WORKSPACE"

	# Also generate workspace-only report
	echo -e "${CYAN}Generating workspace-only report...${NC}"
	lcov --extract "$COVERAGE_FILE" \
		"app_logic.cpp" \
		"app_logic.h" \
		"main.cpp" \
		--output-file "$OUTPUT_DIR/coverage_workspace.info"

	mkdir -p "$OUTPUT_DIR/html_workspace"
	genhtml "$OUTPUT_DIR/coverage_workspace.info" \
		--output-directory "$OUTPUT_DIR/html_workspace" \
		--title "Workspace Coverage Only" \
		--legend \
		--show-details \
		2>&1 >/dev/null

	# Generate summary
	echo -e "${GREEN}Coverage Summary:${NC}"
	echo -e "${CYAN}=== All Modules ===${NC}"
	lcov --summary "$COVERAGE_FILE" 2>/dev/null | tee "$OUTPUT_DIR/summary_all.txt"
	echo -e ""
	echo -e "${CYAN}=== Workspace Only ===${NC}"
	lcov --summary "$OUTPUT_DIR/coverage_workspace.info" 2>/dev/null | tee "$OUTPUT_DIR/summary_workspace.txt"
else
	echo -e "${YELLOW}No coverage data found${NC}"
	exit 1
fi

# Collect test results
TEST_RESULTS_DIR="test_results"
rm -rf "$TEST_RESULTS_DIR"
mkdir -p "$TEST_RESULTS_DIR"

# Copy test logs
find bazel-testlogs -name "test.xml" -o -name "test.log" 2>/dev/null | while read file; do
	cp "$file" "$TEST_RESULTS_DIR/$(basename $(dirname $file))_$(basename $file)" 2>/dev/null || true
done

# Create summary
cat >"$TEST_RESULTS_DIR/summary.txt" <<EOF
ImGui Test Engine - Complete Test Report
=========================================
Date: $(date)

Phase 1: GUI Mode (Visual Inspection)
EOF

if [ $USE_GUI -eq 1 ]; then
	cat >>"$TEST_RESULTS_DIR/summary.txt" <<EOF
  Status: Completed
  Exit Code: $GUI_EXIT_CODE
  Purpose: Manual inspection and visual verification
EOF
else
	cat >>"$TEST_RESULTS_DIR/summary.txt" <<EOF
  Status: Skipped (no display)
EOF
fi

cat >>"$TEST_RESULTS_DIR/summary.txt" <<EOF

Phase 2: Headless Mode (Automated Coverage)
  Status: Completed
  Exit Code: $COVERAGE_EXIT_CODE
  Purpose: Accurate coverage metrics
  
Test Results: $(find bazel-testlogs -name "test.xml" 2>/dev/null | wc -l) XML reports
Coverage Report: $([ -f "$OUTPUT_DIR/html/index.html" ] && echo "Generated" || echo "Not available")

EOF

# ============================================
# Final Summary
# ============================================
echo -e ""
echo -e "${MAGENTA}========================================${NC}"
echo -e "${GREEN}Test Session Complete!${NC}"
echo -e "${MAGENTA}========================================${NC}"
echo -e ""

if [ $USE_GUI -eq 1 ]; then
	echo -e "${CYAN}Phase 1 (GUI):${NC} Exit code $GUI_EXIT_CODE"
fi
echo -e "${CYAN}Phase 2 (Coverage):${NC} Exit code $COVERAGE_EXIT_CODE"
echo -e ""

echo -e "${CYAN}Generated Files:${NC}"
echo -e "  Test Results: $(pwd)/$TEST_RESULTS_DIR/"
echo -e "  Summary:      $(pwd)/$TEST_RESULTS_DIR/summary.txt"

if [ -f "$OUTPUT_DIR/html/index.html" ]; then
	echo -e "  Coverage:     $(pwd)/$OUTPUT_DIR/html/index.html"
	echo -e ""
	echo -e "${CYAN}Open coverage report:${NC}"
	echo -e "  xdg-open $OUTPUT_DIR/html/index.html"
fi

echo -e ""
echo -e "${CYAN}Individual Test Reports:${NC}"
ls -1 bazel-testlogs/*/test.xml 2>/dev/null | while read f; do
	TEST_NAME=$(basename $(dirname $f))
	FAILURES=$(grep -o 'failures="[0-9]*"' $f | cut -d'"' -f2)
	if [ "$FAILURES" = "0" ]; then
		echo -e "  ${GREEN}✓${NC} $TEST_NAME"
	else
		echo -e "  ${RED}✗${NC} $TEST_NAME ($FAILURES failures)"
	fi
done

# Show coverage summary if available
if [ -f "$OUTPUT_DIR/summary.txt" ]; then
	echo -e ""
	echo -e "${CYAN}Coverage Summary:${NC}"
	cat "$OUTPUT_DIR/summary.txt"
fi

echo -e ""
echo -e "${GREEN}Tip:${NC} This workflow combines visual inspection with accurate metrics!"
echo -e "  ${YELLOW}GUI mode:${NC} See tests run, catch visual bugs"
echo -e "  ${YELLOW}Headless mode:${NC} Get reliable coverage data"

# Return coverage exit code for CI/CD
exit $COVERAGE_EXIT_CODE
