#!/bin/bash

echo "========================================="
echo "  🐧 Interactive Linux Process Killer"
echo "========================================="

# 1. SEARCH & DISPLAY PROCESSES
read -p "🔍 Enter keyword to filter (leave blank for top 25 by CPU): " keyword
echo ""

if [ -n "$keyword" ]; then
    echo "📋 PROCESSES MATCHING '$keyword':"
    # -F: fixed string (avoids regex errors), -i: case-insensitive
    ps -eo pid,user,%cpu,%mem,comm,args | grep -iF "$keyword" | grep -v grep | head -n 30
else
    echo "📋 TOP 25 ACTIVE PROCESSES (sorted by CPU):"
    ps -eo pid,user,%cpu,%mem,comm,args --sort=-%cpu | tail -n +2 | head -n 25
fi
echo ""

# 2. INPUT & VALIDATION
read -p "🎯 Enter PID to kill (or 'q' to quit): " target_pid
[[ "$target_pid" == "q" ]] && { echo "Aborted."; exit 0; }

# Check if input is numeric
if ! [[ "$target_pid" =~ ^[0-9]+$ ]]; then
    echo "❌ Error: Please enter a valid numeric PID."
    exit 1
fi

# Protect system-critical PID 1
if [ "$target_pid" -eq 1 ]; then
    echo "❌ Error: Cannot kill PID 1 (init/systemd). System critical process."
    exit 1
fi

# Verify process exists & you have permission
if ! kill -0 "$target_pid" 2>/dev/null; then
    echo "❌ Error: Process $target_pid does not exist or you lack permissions."
    echo "💡 Tip: Prefix with 'sudo' if it's owned by root/another user."
    exit 1
fi

# 3. CONFIRM & TERMINATE
proc_name=$(ps -p "$target_pid" -o comm=)
echo -e "\n✅ Selected: $proc_name (PID: $target_pid)"
read -p "⚠️  Proceed with termination? (y/N): " confirm
[[ "$confirm" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }

echo "⏳ Sending SIGTERM (graceful shutdown)..."
kill -TERM "$target_pid" 2>/dev/null || { echo "❌ Failed to send SIGTERM."; exit 1; }

# Wait up to 5 seconds for graceful exit
for i in {1..5}; do
    if kill -0 "$target_pid" 2>/dev/null; then
        sleep 1
    else
        echo "✅ Process terminated gracefully."
        exit 0
    fi
done

# Force kill if still running
echo "⚠️  Process unresponsive. Sending SIGKILL..."
kill -KILL "$target_pid" 2>/dev/null && echo "✅ Forcefully terminated." || echo "❌ Failed to terminate process."
