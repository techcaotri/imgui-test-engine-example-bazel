#!/bin/bash
# Wrapper script to run tests with Xvfb (virtual display)

# Check if Xvfb is installed
if ! command -v Xvfb &> /dev/null; then
    echo "ERROR: Xvfb not found. Install it with:"
    echo "  sudo apt-get install xvfb"
    exit 1
fi

# Find an available display number
DISPLAY_NUM=99
while [ -e "/tmp/.X${DISPLAY_NUM}-lock" ]; do
    DISPLAY_NUM=$((DISPLAY_NUM + 1))
done

# Start Xvfb in the background (suppress XKB warnings)
Xvfb :${DISPLAY_NUM} -screen 0 1280x720x24 2>/dev/null &
XVFB_PID=$!

# Wait for Xvfb to start
sleep 1

# Set DISPLAY environment variable
export DISPLAY=:${DISPLAY_NUM}

# Run the actual test
"$@"
TEST_EXIT_CODE=$?

# Kill Xvfb
kill $XVFB_PID 2>/dev/null || true

# Return the test's exit code
exit $TEST_EXIT_CODE
