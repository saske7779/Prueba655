#!/bin/bash
# Instalador de Devils VPS Manager
# Uso: bash <(curl -sSL https://raw.githubusercontent.com/saske7779/Prueba655/main/install.sh)

set -e

REPO_RAW="https://raw.githubusercontent.com/saske7779/Prueba655/main"
TARGET="/usr/local/bin/devils"
SCRIPT_URL="$REPO_RAW/devils.sh"

echo "📦 Instalando Devils VPS Manager..."

if [ "$(id -u)" -eq 0 ]; then
    SUDO=""
else
    SUDO="sudo"
fi

$SUDO curl -sSL "$SCRIPT_URL" -o "$TARGET"
$SUDO chmod +x "$TARGET"

echo "✅ Instalado correctamente."
echo ""
echo "👉 Ejecuta el panel con:"
echo "   devils"
echo ""
