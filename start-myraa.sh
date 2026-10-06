#!/bin/bash

# MYRAA Launcher for macOS
echo "============================================================"
echo "                MYRAA ALL-IN-ONE LAUNCHER (macOS)"
echo "============================================================"
echo ""

PROJECT_DIR=$(dirname "$0")
cd "$PROJECT_DIR" || exit

echo "[1/4] Cleaning up any old instances..."
lsof -ti:3000 | xargs kill -9 2>/dev/null
lsof -ti:8765 | xargs kill -9 2>/dev/null
sleep 2
echo "    Done."
echo ""

echo "[2/4] Starting Desktop Control Agent (Python, port 8765)..."
# Assuming python3 is available in the environment. If a virtual environment is used, this should point to the venv python.
./.venv_mac/bin/python -m uvicorn desktop_agent.main:app --host 127.0.0.1 --port 8765 &
AGENT_PID=$!
echo "    Agent launched in background (PID: $AGENT_PID)..."
echo ""

echo "[3/4] Waiting for agent to be ready..."
READY=0
for i in {1..15}; do
    sleep 1
    if curl -s http://127.0.0.1:8765/health > /dev/null; then
        READY=1
        echo "    Desktop Agent is ONLINE!"
        break
    fi
    echo "    ...waiting $i/15"
done

if [ "$READY" -eq "0" ]; then
    echo "    [WARNING] Desktop Agent did not respond in time."
    echo "    MYRAA will still run, but desktop control may be unavailable."
fi
echo ""

echo "[4/4] Starting MYRAA Server (Node, port 3000)..."
echo "============================================================"
echo "  Desktop Agent : http://127.0.0.1:8765"
echo "  MYRAA UI      : http://localhost:3000"
echo "============================================================"
echo ""
echo "  Press Ctrl+C to stop MYRAA."
echo ""

# Catch SIGINT and kill the agent
trap "echo 'Stopping MYRAA...'; kill $AGENT_PID; exit" INT TERM

npm run dev
