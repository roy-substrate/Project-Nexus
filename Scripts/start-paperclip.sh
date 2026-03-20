#!/usr/bin/env bash
# Start Paperclip AI Company OS for Project Nexus
#
# Fixes applied for running as root in minimal-locale Linux environments:
#   - PAPERCLIP_HOME=/tmp/paperclip-home (avoids /root being inaccessible to postgres user)
#   - LC_MESSAGES_LOCALE patched to 'C' in packages/db/node_modules/embedded-postgres/dist/index.js
#   - createPostgresUser: true in packages/db/src/migration-runtime.ts
#   - spawn env inherits process.env (for LD_LIBRARY_PATH) in embedded-postgres dist
#
# Dashboard: http://localhost:3100
# Company:   Project Nexus (ID: ca1eaa81-6c6f-446b-a0b9-0d2f73850a23)
# Agents:    16 (CEO, CTO, Eng Manager, QA, Review, Optimize, Mobile, Ship, Product,
#               Marketing, Growth, Script, Strategy, Sales, GEO, PM)
# Goal:      Ship Nexus Shield to 500 DAU (PRO-*)

set -euo pipefail

PAPERCLIP_DIR="/home/user/paperclip"
PAPERCLIP_HOME="/tmp/paperclip-home"

mkdir -p "$PAPERCLIP_HOME"
chmod 755 "$PAPERCLIP_HOME"

echo ""
echo "  Paperclip — Project Nexus AI Company OS"
echo "  Dashboard: http://localhost:3100"
echo "  Data dir:  $PAPERCLIP_HOME"
echo ""

cd "$PAPERCLIP_DIR"
exec PAPERCLIP_HOME="$PAPERCLIP_HOME" pnpm dev
