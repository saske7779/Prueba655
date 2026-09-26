#!/bin/bash

clear

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
MAGENTA='\033[0;95m'
ORANGE='\033[0;33m'
BOLD='\033[1m'
NC='\033[0m'

SSHX_INFO=".sshx_info"

type_effect() {
    local text="$1"
    local delay="$2"
    for (( i=0; i<${#text}; i++ )); do
        echo -n "${text:$i:1}"
        sleep "$delay"
    done
    echo ""
}

loading_bar() {
    local title="$1"
    echo -ne "${YELLOW}⏳ $title ${NC}[          ]"
    sleep 0.3
    echo -ne "\b\b\b\b\b\b\b\b\b\b\b[===       ]"
    sleep 0.3
    echo -ne "\b\b\b\b\b\b\b\b\b\b\b[======    ]"
    sleep 0.3
    echo -ne "\b\b\b\b\b\b\b\b\b\b\b[========= ]"
    sleep 0.3
    echo -ne "\b\b\b\b\b\b\b\b\b\b\b[==========]"
    echo -e " ${GREEN}DONE!${NC}"
}

if [ "$(id -u)" -eq 0 ]; then
    SUDO_CMD=""
else
    SUDO_CMD="sudo"
fi

export PATH="$HOME/.local/bin:$HOME/.sshx/bin:$PATH"

ensure_sshx() {
    if ! command -v sshx > /dev/null 2>&1; then
        echo -e "${YELLOW}     📦 Installing SSHX client...${NC}"
        curl -sSf https://sshx.io/get | sh > /dev/null 2>&1
        export PATH="$HOME/.local/bin:$HOME/.sshx/bin:$PATH"
    fi
}

# ─── Inicia sshx y guarda URL + PID en $SSHX_INFO ───
start_sshx_tunnel() {
    ensure_sshx

    # Matar instancias viejas
    if [ -f "$SSHX_INFO" ]; then
        OLD_PID=$(grep '^PID=' "$SSHX_INFO" | cut -d= -f2)
        [ -n "$OLD_PID" ] && kill "$OLD_PID" > /dev/null 2>&1
    fi
    pkill -f "sshx" > /dev/null 2>&1
    sleep 1

    local LOG=$(mktemp)
    nohup sshx > "$LOG" 2>&1 &
    local PID=$!

    echo -ne "${YELLOW}     ⏳ Generating SSHX link"
    local URL=""
    for i in $(seq 1 40); do
        URL=$(grep -oE 'https://sshx\.io/s/[A-Za-z0-9]+' "$LOG" 2>/dev/null | head -n1)
        [ -n "$URL" ] && break
        echo -n "."
        sleep 1
    done
    echo ""

    {
        echo "PID=$PID"
        echo "URL=$URL"
        echo "LOG=$LOG"
    } > "$SSHX_INFO"

    echo "$URL"
}

# ─── Muestra el panel con la info del link actual ───
show_sshx_info() {
    local URL=""
    local PID=""
    local STATUS="${RED}● STOPPED${NC}"

    if [ -f "$SSHX_INFO" ]; then
        URL=$(grep '^URL=' "$SSHX_INFO" | cut -d= -f2)
        PID=$(grep '^PID=' "$SSHX_INFO" | cut -d= -f2)
        if [ -n "$PID" ] && kill -0 "$PID" > /dev/null 2>&1; then
            STATUS="${GREEN}● RUNNING${NC}"
        fi
    fi

    clear
    echo ""
    echo -e "${MAGENTA}     ╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}     ║           ${WHITE}SSHX TUNNEL INFORMATION${MAGENTA}             ║${NC}"
    echo -e "${MAGENTA}     ╚══════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "     ${WHITE}Status   : ${STATUS}"
    echo -e "     ${WHITE}PID      : ${CYAN}${PID:-N/A}${NC}"
    echo ""

    if [ -n "$URL" ]; then
        echo -e "${MAGENTA}     ╔══════════════════════════════════════════════════╗${NC}"
        echo -e "${MAGENTA}     ║ ${YELLOW}🔥 LIVE SSHX LINK:${NC}"
        echo -e "${MAGENTA}     ║ ${GREEN}${URL}${NC}"
        echo -e "${MAGENTA}     ╚══════════════════════════════════════════════════╝${NC}"
    else
        echo -e "${RED}     ❌ No hay link activo. Inicia la VPS primero (Opción 1 o 2).${NC}"
    fi

    if [ -f ".vps_env" ]; then
        source .vps_env
        echo ""
        echo -e "${CYAN}     ── Datos de la VM ──${NC}"
        echo -e "     ${WHITE}👤 User     : ${CYAN}${USER_NAME:-ubuntu}${NC}"
        echo -e "     ${WHITE}🔑 Password : ${CYAN}${USER_PASS:-1234}${NC}"
        echo -e "     ${WHITE}🌐 SSH cmd  : ${CYAN}ssh ${USER_NAME:-ubuntu}@localhost -p ${TCP_HOST_PORT:-2222}${NC}"
    fi

    echo ""
    echo -e "${CYAN}     Presiona ENTER para volver al menú..."
    read
    show_menu
}

show_menu() {
    clear

    echo ""
    echo -e "${MAGENTA}     ██████╗ ███████╗██╗   ██╗██╗██╗     ███████╗${NC}"
    echo -e "${MAGENTA}     ██╔══██╗██╔════╝██║   ██║██║██║     ██╔════╝${NC}"
    echo -e "${RED}     ██║  ██║█████╗  ██║   ██║██║██║     ███████╗${NC}"
    echo -e "${RED}     ██║  ██║██╔══╝  ╚██╗ ██╔╝██║██║     ╚════██║${NC}"
    echo -e "${PURPLE}     ██████╔╝███████╗ ╚████╔╝ ██║███████╗███████║${NC}"
    echo -e "${PURPLE}     ╚═════╝ ╚══════╝  ╚═══╝  ╚═╝╚══════╝╚══════╝${NC}"
    echo ""
    echo -e "${CYAN}                    ██╗    ██╗██╗██╗     ██╗     ${NC}"
    echo -e "${CYAN}                    ██║    ██║██║██║     ██║     ${NC}"
    echo -e "${BLUE}                    ██║ █╗ ██║██║██║     ██║     ${NC}"
    echo -e "${BLUE}                    ██║███╗██║██║██║     ██║     ${NC}"
    echo -e "${GREEN}                    ╚███╔███╔╝██║███████╗███████╗${NC}"
    echo -e "${GREEN}                     ╚══╝╚══╝ ╚═╝╚══════╝╚══════╝${NC}"
    echo ""
    echo -e "${RED}                    ██████╗ ██╗███████╗███████╗${NC}"
    echo -e "${RED}                    ██╔══██╗██║██╔════╝██╔════╝${NC}"
    echo -e "${YELLOW}                    ██████╔╝██║███████╗█████╗  ${NC}"
    echo -e "${YELLOW}                    ██╔══██╗██║╚════██║██╔══╝  ${NC}"
    echo -e "${ORANGE}                    ██║  ██║██║███████║███████╗${NC}"
    echo -e "${ORANGE}                    ╚═╝  ╚═╝╚═╝╚══════╝╚══════╝${NC}"
    echo ""
    echo -e "${MAGENTA}     ══════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                  ${BOLD}VPS CONTROL PANEL${NC}${WHITE}                    ${NC}"
    echo -e "${MAGENTA}     ══════════════════════════════════════════════════${NC}"
    echo ""

    # Detectar estado
    VM_STATUS="${RED}● OFFLINE${NC}"
    SSHX_STATUS="${RED}● NO LINK${NC}"
    if [ -f "/home/daytona/ubuntu22.qcow2" ] && [ -f "seed.img" ]; then
        VM_STATUS="${GREEN}● READY${NC}"
    fi
    if [ -f "$SSHX_INFO" ]; then
        local PID=$(grep '^PID=' "$SSHX_INFO" | cut -d= -f2)
        if [ -n "$PID" ] && kill -0 "$PID" > /dev/null 2>&1; then
            SSHX_STATUS="${GREEN}● ACTIVE${NC}"
        fi
    fi

    echo -e "${RED}     ┌──────────────────────────────────────────────────┐${NC}"
    echo -e "${RED}     │  ${WHITE}SYSTEM STATUS${RED}                                    │${NC}"
    echo -e "${RED}     │                                                  │${NC}"
    echo -e "${RED}     │  VM: ${VM_STATUS}${RED}          SSHX: ${SSHX_STATUS}${RED}            │${NC}"
    echo -e "${RED}     │                                                  │${NC}"
    echo -e "${RED}     └──────────────────────────────────────────────────┘${NC}"
    echo ""

    echo -e "${PURPLE}     ┌─────────────────── ${WHITE}MAIN MENU${PURPLE} ─────────────────────┐${NC}"
    echo -e "${PURPLE}     │                                                  │${NC}"

    echo -e "${PURPLE}     │   ${CYAN}01${PURPLE}  ›  ${WHITE}CREATE VPS${PURPLE}                              │${NC}"
    echo -e "${PURPLE}     │       ${WHITE}Deploy a new Ubuntu virtual machine${PURPLE}        │${NC}"
    echo -e "${PURPLE}     │                                                  │${NC}"

    echo -e "${PURPLE}     │   ${CYAN}02${PURPLE}  ›  ${WHITE}RESTART VPS${PURPLE}                             │${NC}"
    echo -e "${PURPLE}     │       ${WHITE}Start existing VPS instance${PURPLE}                │${NC}"
    echo -e "${PURPLE}     │                                                  │${NC}"

    echo -e "${PURPLE}     │   ${CYAN}03${PURPLE}  ›  ${WHITE}NETWORK${PURPLE}                                 │${NC}"
    echo -e "${PURPLE}     │       ${WHITE}Configure TCP port forwarding${PURPLE}              │${NC}"
    echo -e "${PURPLE}     │                                                  │${NC}"

    echo -e "${PURPLE}     │   ${CYAN}04${PURPLE}  ›  ${WHITE}CLEANUP${PURPLE}                                 │${NC}"
    echo -e "${PURPLE}     │       ${WHITE}Remove VPS files and cache${PURPLE}                 │${NC}"
    echo -e "${PURPLE}     │                                                  │${NC}"

    echo -e "${PURPLE}     │   ${CYAN}05${PURPLE}  ›  ${WHITE}VIEW SSHX LINK${PURPLE}                         │${NC}"
    echo -e "${PURPLE}     │       ${WHITE}Show current SSHX tunnel URL${PURPLE}              │${NC}"
    echo -e "${PURPLE}     │                                                  │${NC}"

    echo -e "${PURPLE}     │   ${CYAN}06${PURPLE}  ›  ${WHITE}EXIT${PURPLE}                                    │${NC}"
    echo -e "${PURPLE}     │       ${WHITE}Close control panel${PURPLE}                        │${NC}"

    echo -e "${PURPLE}     │                                                  │${NC}"
    echo -e "${PURPLE}     └──────────────────────────────────────────────────┘${NC}"
    echo ""

    echo -e "${MAGENTA}     ─────────────────────────────────────────────────────${NC}"
    echo -e "${WHITE}       DEVILS WILL RISE  •  VPS MANAGER  •  ${GREEN}READY${WHITE}${NC}"
    echo -e "${MAGENTA}     ─────────────────────────────────────────────────────${NC}"
    echo ""
    echo -e "${CYAN}     ${BOLD}Credits:${NC}"
    echo -e "${WHITE}     👤 Creator TG  : ${GREEN}@UnknownGuy9876${NC}"
    echo -e "${WHITE}     📸 Creator Insta: ${GREEN}@UnknownGuy_.01${NC}"
    echo -e "${WHITE}     📢 TG Channel  : ${GREEN}@SGCodexs${NC}"
    echo -e "${MAGENTA}     ─────────────────────────────────────────────────────${NC}"
    echo ""

    echo -ne "${CYAN}     Select option › [1-6]: ${NC}"
    read CHOICE

    case $CHOICE in
        1) create_vps ;;
        2) restart_vps ;;
        3) configure_tcp ;;
        4) clean_vps ;;
        5) show_sshx_info ;;
        6)
            clear
            echo ""
            echo -e "${MAGENTA}     DEVILS WILL RISE VPS Manager closed.${NC}"
            echo ""
            exit 0
            ;;
        *)
            echo ""
            echo -e "${RED}     ❌ Invalid choice! Please select 1-6.${NC}"
            sleep 2
            show_menu
            ;;
    esac
}

create_vps() {
    clear

    echo ""
    echo -e "${MAGENTA}     ╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}     ║              ${WHITE}CREATE NEW VPS${MAGENTA}                  ║${NC}"
    echo -e "${MAGENTA}     ╚══════════════════════════════════════════════════╝${NC}"
    echo ""

    echo -ne "${CYAN}     🔹 Enter RAM Size in GB (e.g., 4, 8, 16, 32): ${NC}"
    read RAM_GB

    echo -ne "${CYAN}     🔹 Enter CPU Cores (e.g., 2, 4, 8): ${NC}"
    read CPU_CORES

    echo -ne "${CYAN}     🔹 Enter Disk Space to ADD in GB (e.g., 10, 20): ${NC}"
    read DISK_ADD

    echo -ne "${CYAN}     🔹 Create Username (Default: ubuntu): ${NC}"
    read USER_NAME
    USER_NAME=${USER_NAME:-ubuntu}

    echo -ne "${CYAN}     🔹 Create Password (Default: 1234): ${NC}"
    read USER_PASS
    USER_PASS=${USER_PASS:-1234}

    TCP_HOST_PORT=${TCP_HOST_PORT:-2222}
    TCP_GUEST_PORT=22

    echo ""
    echo -e "${YELLOW}     ⏳ Installing core dependencies... Please wait.${NC}"
    echo ""

    $SUDO_CMD apt-get update -y > /dev/null 2>&1
    $SUDO_CMD apt-get install -y \
        qemu-system-x86 \
        qemu-utils \
        wget \
        cloud-image-utils \
        curl \
        lsof \
        openssh-client > /dev/null 2>&1

    $SUDO_CMD mkdir -p /home/daytona > /dev/null 2>&1

    if [ ! -f "/home/daytona/ubuntu22.qcow2" ]; then
        echo -e "${YELLOW}     📥 Downloading Ubuntu 22.04 Cloud Image...${NC}"
        $SUDO_CMD wget -q --show-progress \
            https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img \
            -O /home/daytona/ubuntu22.qcow2
        $SUDO_CMD chmod 666 /home/daytona/ubuntu22.qcow2
    else
        echo -e "${GREEN}     ✅ Existing Ubuntu Image Cache Detected.${NC}"
    fi

    loading_bar "Generating Cloud-Init Matrix"

    cat <<EOF > user-data
#cloud-config
ssh_pwauth: True
chpasswd:
  list: |
    ${USER_NAME}:${USER_PASS}
  expire: False
EOF

    cloud-localds seed.img user-data > /dev/null 2>&1

    loading_bar "Expanding Server Hard Disk Allocation"

    $SUDO_CMD qemu-img resize \
        /home/daytona/ubuntu22.qcow2 \
        +${DISK_ADD}G > /dev/null 2>&1

    save_env
    boot_qemu
}

configure_tcp() {
    clear

    echo ""
    echo -e "${MAGENTA}     ╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}     ║             ${WHITE}NETWORK CONFIGURATION${MAGENTA}             ║${NC}"
    echo -e "${MAGENTA}     ╚══════════════════════════════════════════════════╝${NC}"
    echo ""

    if [ -f ".vps_env" ]; then
        source .vps_env
    fi

    echo -e "     Current Target Host Port  : ${CYAN}${TCP_HOST_PORT:-2222}${NC}"
    echo -e "     Current Guest VM Port     : ${CYAN}${TCP_GUEST_PORT:-22}${NC}"
    echo ""

    echo -ne "${CYAN}     🔹 Enter NEW External Host Port (Default: 2222): ${NC}"
    read NEW_HOST_PORT
    TCP_HOST_PORT=${NEW_HOST_PORT:-2222}

    echo -ne "${CYAN}     🔹 Enter Internal Guest Port (Default SSH: 22): ${NC}"
    read NEW_GUEST_PORT
    TCP_GUEST_PORT=${NEW_GUEST_PORT:-22}

    save_env

    echo ""
    echo -e "${GREEN}     ✅ TCP Rule Updated Successfully!${NC}"

    sleep 2
    show_menu
}

save_env() {
    echo "RAM_GB=${RAM_GB:-32}" > .vps_env
    echo "CPU_CORES=${CPU_CORES:-4}" >> .vps_env
    echo "USER_NAME=${USER_NAME:-ubuntu}" >> .vps_env
    echo "USER_PASS=${USER_PASS:-1234}" >> .vps_env
    echo "TCP_HOST_PORT=${TCP_HOST_PORT:-2222}" >> .vps_env
    echo "TCP_GUEST_PORT=${TCP_GUEST_PORT:-22}" >> .vps_env
}

boot_qemu() {

    if [ -f ".vps_env" ]; then
        source .vps_env
    fi

    TCP_HOST_PORT=${TCP_HOST_PORT:-2222}
    TCP_GUEST_PORT=${TCP_GUEST_PORT:-22}
    RAM_VALUE="${RAM_GB:-32}G"

    clear
    echo ""
    echo -e "${MAGENTA}     ╔══════════════════════════════════════════════════╗${NC}"
    type_effect "     🚀 DEVILS WILL RISE SYSTEM SYNCHRONIZED! STARTING VM..." 0.02
    echo -e "${MAGENTA}     ╚══════════════════════════════════════════════════╝${NC}"
    echo ""

    # ─── Verificar/liberar puerto ───
    if $SUDO_CMD lsof -i :${TCP_HOST_PORT} > /dev/null 2>&1; then
        echo -e "${YELLOW}     ⚠️ Puerto ${TCP_HOST_PORT} en uso. Liberando...${NC}"
        $SUDO_CMD fuser -k ${TCP_HOST_PORT}/tcp > /dev/null 2>&1
        sleep 2
    fi

    # ─── Levantar túnel SSHX ───
    SSHX_URL=$(start_sshx_tunnel)

    # ─── Panel de información ───
    clear
    echo ""
    echo -e "${MAGENTA}     ╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}     ║              ${GREEN}✓ VM NETWORK ACTIVE${MAGENTA}                ║${NC}"
    echo -e "${MAGENTA}     ╠══════════════════════════════════════════════════╣${NC}"
    echo -e "${MAGENTA}     ║ ${WHITE}👤 Username : ${CYAN}${USER_NAME:-ubuntu}${NC}"
    echo -e "${MAGENTA}     ║ ${WHITE}🔑 Password : ${CYAN}${USER_PASS:-1234}${NC}"
    echo -e "${MAGENTA}     ║ ${WHITE}⚙️  Resources: ${CYAN}${RAM_VALUE} RAM | ${CPU_CORES:-4} Cores${NC}"
    echo -e "${MAGENTA}     ║ ${WHITE}🚀 Port Rule : ${YELLOW}${TCP_HOST_PORT} → ${TCP_GUEST_PORT}${NC}"
    echo -e "${MAGENTA}     ╠══════════════════════════════════════════════════╣${NC}"

    if [ -n "$SSHX_URL" ]; then
        echo -e "${MAGENTA}     ║ ${YELLOW}🔥 LIVE SSHX ACCESS LINK:${NC}"
        echo -e "${MAGENTA}     ║ ${GREEN}${SSHX_URL}${NC}"
    else
        echo -e "${MAGENTA}     ║ ${RED}⚠️ SSHX todavía generando el link.${NC}"
        echo -e "${MAGENTA}     ║ ${WHITE}Usa la Opción 05 del menú para verlo.${NC}"
    fi

    echo -e "${MAGENTA}     ╠══════════════════════════════════════════════════╣${NC}"
    echo -e "${MAGENTA}     ║ ${WHITE}👉 Dentro del link SSHX ejecuta:${NC}"
    echo -e "${MAGENTA}     ║ ${CYAN}ssh ${USER_NAME:-ubuntu}@localhost -p ${TCP_HOST_PORT}${NC}"
    echo -e "${MAGENTA}     ╚══════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}     ${BOLD}Powered by DEVILS WILL RISE${NC}"
    echo -e "${WHITE}     TG  : ${GREEN}@UnknownGuy9876${NC}"
    echo -e "${WHITE}     Insta: ${GREEN}@UnknownGuy_.01${NC}"
    echo -e "${WHITE}     Chnl : ${GREEN}@SGCodexs${NC}"
    echo ""
    echo -e "${YELLOW}     ⏳ Arrancando QEMU en 5 segundos..."
    sleep 5

    # ─── Arrancar QEMU ───
    qemu-system-x86_64 \
        -hda /home/daytona/ubuntu22.qcow2 \
        -m "$RAM_VALUE" \
        -smp "${CPU_CORES:-4}" \
        -drive file=seed.img,format=raw \
        -nographic \
        -netdev user,id=net0,hostfwd=tcp::${TCP_HOST_PORT}-:${TCP_GUEST_PORT} \
        -device e1000,netdev=net0

    # ─── Al salir de QEMU ───
    echo ""
    echo -e "${YELLOW}     ⚠️ QEMU detenido. El túnel SSHX sigue activo.${NC}"
    echo -e "${CYAN}     Link actual guardado en '${SSHX_INFO}'${NC}"
    echo ""
    echo -ne "${CYAN}     Volver al menú? [Y/n]: ${NC}"
    read BACK
    if [[ "$BACK" =~ ^[Nn]$ ]]; then
        exit 0
    fi
    show_menu
}

restart_vps() {

    clear

    if [ -f "/home/daytona/ubuntu22.qcow2" ] && [ -f "seed.img" ]; then
        echo ""
        echo -e "${MAGENTA}     ╔══════════════════════════════════════════════════╗${NC}"
        echo -e "${MAGENTA}     ║        ${GREEN}🔄 RESTARTING DEVILS WILL RISE VPS${MAGENTA}       ║${NC}"
        echo -e "${MAGENTA}     ╚══════════════════════════════════════════════════╝${NC}"
        sleep 1
        boot_qemu
    else
        echo ""
        echo -e "${MAGENTA}     ╔══════════════════════════════════════════════════╗${NC}"
        echo -e "${MAGENTA}     ║ ${RED}❌ No active VPS configuration found.${MAGENTA}            ║${NC}"
        echo -e "${MAGENTA}     ║ ${WHITE}Build the VPS using Option 1.${MAGENTA}                    ║${NC}"
        echo -e "${MAGENTA}     ╚══════════════════════════════════════════════════╝${NC}"
        sleep 3
        show_menu
    fi
}

clean_vps() {

    clear

    echo ""
    echo -e "${MAGENTA}     ╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}     ║              ${YELLOW}⚠ CLEAN WORKSPACE${MAGENTA}                 ║${NC}"
    echo -e "${MAGENTA}     ╚══════════════════════════════════════════════════╝${NC}"
    echo ""

    echo -e "${YELLOW}     ⚠️ Purging VPS storage components and configurations...${NC}"

    $SUDO_CMD rm -rf \
        user-data \
        seed.img \
        /home/daytona/ubuntu22.qcow2 \
        .vps_env

    # Matar sshx y limpiar info
    if [ -f "$SSHX_INFO" ]; then
        PID=$(grep '^PID=' "$SSHX_INFO" | cut -d= -f2)
        [ -n "$PID" ] && kill "$PID" > /dev/null 2>&1
    fi
    pkill -f "sshx" > /dev/null 2>&1
    rm -f "$SSHX_INFO"

    sleep 1

    echo -e "${GREEN}     ✅ DEVILS WILL RISE workspace successfully cleaned!${NC}"

    sleep 2
    show_menu
}

show_menu
