#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${MAGENTA}======================================${NC}"
echo -e "${MAGENTA}ImGui Test App - Bazel 8 Build${NC}"
echo -e "${MAGENTA}======================================${NC}"

# Parse arguments
CONFIG="debug"
RUN_TESTS=0
RUN_COVERAGE=0
CLEAN_BUILD=0
FETCH_ONLY=0

while [[ $# -gt 0 ]]; do
	case $1 in
	--release)
		CONFIG="release"
		shift
		;;
	--test)
		RUN_TESTS=1
		shift
		;;
	--coverage)
		RUN_COVERAGE=1
		CONFIG="coverage"
		shift
		;;
	--clean)
		CLEAN_BUILD=1
		shift
		;;
	--fetch)
		FETCH_ONLY=1
		shift
		;;
	--help)
		echo "Usage: $0 [OPTIONS]"
		echo "Options:"
		echo "  --release    Build in Release mode"
		echo "  --test       Run tests after building"
		echo "  --coverage   Generate coverage report"
		echo "  --clean      Clean build before building"
		echo "  --fetch      Only fetch dependencies"
		echo "  --help       Show this help message"
		exit 0
		;;
	*)
		echo -e "${RED}Unknown option: $1${NC}"
		exit 1
		;;
	esac
done

# Clean if requested
if [ $CLEAN_BUILD -eq 1 ]; then
	echo -e "${YELLOW}Cleaning Bazel cache...${NC}"
	bazel clean --expunge
	rm -f MODULE.bazel.lock
fi

# Fetch dependencies
echo -e "${GREEN}Fetching dependencies...${NC}"
bazel fetch //... 2>&1 | grep -v "WARNING: For repository" || true

if [ $FETCH_ONLY -eq 1 ]; then
	echo -e "${GREEN}Dependencies fetched successfully!${NC}"
	exit 0
fi

# Build
echo -e "${GREEN}Building with config: ${CONFIG}${NC}"
if [ $RUN_COVERAGE -eq 1 ]; then
	bazel build --config=coverage //:imgui_test_app_coverage 2>&1 | grep -v "WARNING: For repository" || true
	BINARY="bazel-bin/imgui_test_app_coverage"
else
	bazel build --config=${CONFIG} //:imgui_test_app 2>&1 | grep -v "WARNING: For repository" || true
	BINARY="bazel-bin/imgui_test_app"
fi

# Run tests if requested
if [ $RUN_TESTS -eq 1 ]; then
	echo -e "${GREEN}Running tests...${NC}"
	if [ $RUN_COVERAGE -eq 1 ]; then
		# Run all tests with coverage
		bazel coverage --config=coverage //:all_tests 2>&1 | grep -v "WARNING: For repository" || true

		# Generate HTML report
		echo -e "${GREEN}Generating coverage report...${NC}"
		bazel run //:coverage
	else
		# Run test suite
		bazel test //:all_tests --test_output=all 2>&1 | grep -v "WARNING: For repository" || true
	fi
fi

echo -e "${MAGENTA}======================================${NC}"
echo -e "${GREEN}Build complete!${NC}"
echo -e "${MAGENTA}======================================${NC}"

echo -e "\n${BLUE}Executable: ${BINARY}${NC}"

if [ $RUN_TESTS -eq 0 ]; then
	echo -e "\n${YELLOW}Next steps:${NC}"
	echo "  Run app:          ./${BINARY}"
	echo "  Run tests:        ./${BINARY} --test --headless"
	echo "  Run with GUI:     ./${BINARY} --test"
fi

if [ $RUN_COVERAGE -eq 1 ]; then
	echo -e "\n${GREEN}Coverage report: coverage_report/html/index.html${NC}"
fi
