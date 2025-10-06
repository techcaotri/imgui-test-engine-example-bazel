#!/bin/bash
set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}ImGui Test - GUI with Test Reports${NC}"
echo -e "${BLUE}======================================${NC}"

# Check display
if [ -z "$DISPLAY" ]; then
	echo -e "${RED}ERROR: No DISPLAY variable set${NC}"
	exit 1
fi

# Check and install junit2html
if ! command -v junit2html &>/dev/null; then
	echo -e "${YELLOW}Installing junit2html...${NC}"
	if command -v pip3 &>/dev/null; then
		pip3 install --user junit2html
	elif command -v pip &>/dev/null; then
		pip install --user junit2html
	else
		echo -e "${RED}ERROR: pip not found. Install with:${NC}"
		echo -e "  sudo apt-get install python3-pip"
		exit 1
	fi
	export PATH="$PATH:$HOME/.local/bin"
fi

echo -e "${GREEN}✓ junit2html is available${NC}"

# Build application
echo -e "${CYAN}Building GUI application...${NC}"
bazel build //:imgui_test_app

# Prepare test results directory
TEST_RESULTS_DIR="test_results"
JUNIT_DIR="$TEST_RESULTS_DIR/junit"
rm -rf "$TEST_RESULTS_DIR"
mkdir -p "$TEST_RESULTS_DIR"
mkdir -p "$JUNIT_DIR"

# Run GUI
echo -e ""
echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}GUI Test Session${NC}"
echo -e "${BLUE}======================================${NC}"
echo -e ""
echo -e "${YELLOW}Instructions:${NC}"
echo -e "  • Tests will run automatically"
echo -e "  • Watch for visual issues"
echo -e "  • Wait for all tests to complete"
echo -e "  • Close window when done"
echo -e "  • JUnit XML will be exported to test_results/"
echo -e ""
echo -e "${CYAN}Press Enter to launch GUI...${NC}"
read

echo -e "${GREEN}Launching GUI...${NC}"
set +e
./bazel-bin/imgui_test_app --test
GUI_EXIT_CODE=$?
set -e

if [ $GUI_EXIT_CODE -eq 0 ]; then
	echo -e "${GREEN}✓ GUI session completed${NC}"
else
	echo -e "${YELLOW}⚠ GUI exited with code: $GUI_EXIT_CODE${NC}"
fi

# Check if JUnit XML was generated
if [ ! -f "$TEST_RESULTS_DIR/test_results.xml" ]; then
	echo -e "${RED}ERROR: test_results/test_results.xml not found${NC}"
	echo -e "${YELLOW}Make sure app_logic.cpp has JUnit export enabled:${NC}"
	echo -e "  test_io.ExportResultsFilename = \"test_results/test_results.xml\";"
	echo -e "  test_io.ExportResultsFormat = ImGuiTestEngineExportFormat_JUnitXml;"
	exit 1
fi

# Generate HTML report
echo -e ""
echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}Generating HTML Test Report${NC}"
echo -e "${BLUE}======================================${NC}"

# Convert to HTML
echo -e "${GREEN}Converting XML to HTML...${NC}"
junit2html "$TEST_RESULTS_DIR/test_results.xml" "$JUNIT_DIR/test_report.html"

# Extract test statistics
TOTAL_TESTS=$(grep -o 'tests="[0-9]*"' "$TEST_RESULTS_DIR/test_results.xml" | head -1 | cut -d'"' -f2)
FAILURES=$(grep -o 'failures="[0-9]*"' "$TEST_RESULTS_DIR/test_results.xml" | head -1 | cut -d'"' -f2)
PASSED=$((TOTAL_TESTS - FAILURES))

# Create index with summary
cat >"$JUNIT_DIR/index.html" <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>Test Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        h1 { color: #333; border-bottom: 3px solid #4CAF50; padding-bottom: 10px; }
        .summary { background: white; padding: 20px; margin: 20px 0; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .summary h2 { margin-top: 0; color: #333; }
        .stat { display: inline-block; margin: 10px 20px 10px 0; font-size: 18px; }
        .stat-label { color: #666; }
        .stat-value { font-weight: bold; font-size: 24px; }
        .passed { color: #4CAF50; }
        .failed { color: #f44336; }
        .report-link { background: #1976D2; color: white; padding: 15px 30px; text-decoration: none; border-radius: 4px; display: inline-block; margin-top: 20px; }
        .report-link:hover { background: #1565C0; }
    </style>
</head>
<body>
    <h1>ImGui Test Results</h1>
    <div class="summary">
        <h2>Test Summary</h2>
        <div class="stat">
            <div class="stat-label">Total Tests</div>
            <div class="stat-value">${TOTAL_TESTS}</div>
        </div>
        <div class="stat">
            <div class="stat-label">Passed</div>
            <div class="stat-value passed">${PASSED}</div>
        </div>
        <div class="stat">
            <div class="stat-label">Failed</div>
            <div class="stat-value failed">${FAILURES}</div>
        </div>
        <br>
        <a href="test_report.html" class="report-link">View Detailed Report</a>
    </div>
</body>
</html>
EOF

# Create summary file
cat >"$TEST_RESULTS_DIR/summary.txt" <<EOF
ImGui Test Report
=================
Date: $(date)

Results:
  Total Tests: ${TOTAL_TESTS}
  Passed: ${PASSED}
  Failed: ${FAILURES}

Files:
  XML:  $TEST_RESULTS_DIR/test_results.xml
  HTML: $JUNIT_DIR/index.html
EOF

# Final output
echo -e ""
echo -e "${BLUE}======================================${NC}"
echo -e "${GREEN}Complete!${NC}"
echo -e "${BLUE}======================================${NC}"
echo -e ""
echo -e "${CYAN}Test Results:${NC}"
echo -e "  Total Tests: ${TOTAL_TESTS}"
if [ "$FAILURES" = "0" ]; then
	echo -e "  Status: ${GREEN}All tests passed ✓${NC}"
else
	echo -e "  Status: ${RED}${FAILURES} test(s) failed ✗${NC}"
fi
echo -e ""
echo -e "${CYAN}Reports:${NC}"
echo -e "  XML:  $TEST_RESULTS_DIR/test_results.xml"
echo -e "  HTML: $JUNIT_DIR/index.html"
echo -e ""
echo -e "${CYAN}Open report:${NC}"
echo -e "  xdg-open $JUNIT_DIR/index.html"

# Display summary
cat "$TEST_RESULTS_DIR/summary.txt"

exit $GUI_EXIT_CODE
