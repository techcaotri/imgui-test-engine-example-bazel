#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}ImGui Test Engine - GUI Mode Testing${NC}"
echo -e "${BLUE}======================================${NC}"

# Check if we have a display
if [ -z "$DISPLAY" ]; then
    echo -e "${RED}ERROR: No DISPLAY variable set${NC}"
    echo -e "${YELLOW}This script requires a GUI environment${NC}"
    echo -e "${YELLOW}For headless testing, use: ./run_tests_coverage.sh${NC}"
    exit 1
fi

echo -e ""
echo -e "${YELLOW}⚠️  Important Note About GUI Coverage:${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}GUI mode coverage is NOT reliable with Bazel because:${NC}"
echo -e "  • Bazel's coverage requires running tests through bazel coverage"
echo -e "  • Direct binary execution bypasses coverage collection"
echo -e "  • .gcda files may not be generated or accessible"
echo -e ""
echo -e "${CYAN}This script will:${NC}"
echo -e "  ✓ Run tests in GUI mode for VISUAL INSPECTION"
echo -e "  ✗ NOT produce accurate coverage data"
echo -e ""
echo -e "${YELLOW}For accurate coverage, use:${NC}"
echo -e "  ${GREEN}./run_tests_coverage.sh${NC}          (headless, accurate coverage)"
echo -e "  ${GREEN}./run_tests_gui_then_coverage.sh${NC} (GUI + accurate coverage)"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e ""
echo -e "${CYAN}Continue with GUI testing only? (no coverage) [y/N]${NC}"
read -r response

if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Cancelled. Use ./run_tests_gui_then_coverage.sh for GUI + coverage${NC}"
    exit 0
fi

echo -e ""
echo -e "${GREEN}Building GUI test application...${NC}"
bazel build //:imgui_test_app

echo -e ""
echo -e "${BLUE}======================================${NC}"
echo -e "${CYAN}Starting GUI Test Session${NC}"
echo -e "${BLUE}======================================${NC}"
echo -e ""
echo -e "${YELLOW}Instructions:${NC}"
echo -e "  1. The ImGui Test Engine UI will open"
echo -e "  2. Tests run automatically (or use Test Engine window)"
echo -e "  3. Watch for visual issues or failures"
echo -e "  4. Manually interact with the UI if needed"
echo -e "  5. Close the window when done"
echo -e ""
echo -e "${CYAN}Test Engine UI:${NC}"
echo -e "  • Open 'Test Engine' from the menu"
echo -e "  • View all tests in the Tests tab"
echo -e "  • Run individual tests or all tests"
echo -e "  • Check results in real-time"
echo -e ""
echo -e "${YELLOW}Press Enter to launch GUI...${NC}"
read

# Run the GUI application
echo -e "${GREEN}Launching GUI application...${NC}"
set +e
./bazel-bin/imgui_test_app --test
GUI_EXIT_CODE=$?
set -e

echo -e ""
if [ $GUI_EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}✓ GUI session completed successfully${NC}"
else
    echo -e "${YELLOW}⚠ GUI session ended with code: $GUI_EXIT_CODE${NC}"
fi

# Create session report
TEST_RESULTS_DIR="test_results_gui"
rm -rf "$TEST_RESULTS_DIR"
mkdir -p "$TEST_RESULTS_DIR"

cat > "$TEST_RESULTS_DIR/session_report.txt" << EOF
GUI Test Session Report
=======================
Date: $(date)
Exit Code: $GUI_EXIT_CODE

Test Mode: Interactive GUI (Visual Inspection Only)
Application: imgui_test_app

Purpose:
--------
- Visual verification of test execution
- Manual testing and interaction
- UI bug detection
- Real-time test observation

Coverage:
---------
⚠️  NO COVERAGE DATA COLLECTED
GUI mode does not produce coverage metrics.

For coverage analysis, use:
  ./run_tests_coverage.sh           - Headless mode with coverage
  ./run_tests_gui_then_coverage.sh  - GUI inspection + coverage

Test Observations:
------------------
(Add your manual observations here)

Known Limitations:
------------------
- No automated test reports (manual observation only)
- No coverage metrics
- No XML test results
- Exit code may not reflect test failures

Next Steps:
-----------
For complete test validation:
1. Run: ./run_tests_coverage.sh
2. Review: coverage_report/html/index.html
3. Check: test_results/summary.txt
EOF

echo -e ""
echo -e "${BLUE}======================================${NC}"
echo -e "${GREEN}GUI Test Session Complete${NC}"
echo -e "${BLUE}======================================${NC}"
echo -e ""
echo -e "${CYAN}Session Report:${NC}"
echo -e "  Location: $(pwd)/$TEST_RESULTS_DIR/session_report.txt"
echo -e "  Exit Code: $GUI_EXIT_CODE"
echo -e ""
echo -e "${YELLOW}⚠️  No coverage data was collected (by design)${NC}"
echo -e ""
echo -e "${CYAN}To get coverage metrics, run:${NC}"
echo -e "  ${GREEN}./run_tests_coverage.sh${NC}"
echo -e "${CYAN}Or for GUI + coverage:${NC}"
echo -e "  ${GREEN}./run_tests_gui_then_coverage.sh${NC}"
echo -e ""
echo -e "${CYAN}View session report:${NC}"
echo -e "  cat $TEST_RESULTS_DIR/session_report.txt"

exit $GUI_EXIT_CODE
