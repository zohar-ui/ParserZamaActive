#!/bin/bash
# Wrapper script for Claude CLI with API key
# Usage: ./scripts/claude.sh "your prompt here"

# Load API key from .env.local
if [ -f .env.local ]; then
    export $(grep ANTHROPIC_API_KEY .env.local | xargs)
fi

# Check if key is set
if [ -z "$ANTHROPIC_API_KEY" ]; then
    echo "❌ Error: ANTHROPIC_API_KEY not found in .env.local"
    echo "Add it to .env.local: ANTHROPIC_API_KEY=\"your-key-here\""
    exit 1
fi

# Run claude with all arguments
claude "$@"
