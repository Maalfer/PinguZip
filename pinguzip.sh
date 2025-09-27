#!/bin/bash

# ----------- CONFIGURACIÓN DE COLORES -----------
BLUE="\033[38;5;39m"
YELLOW="\033[38;5;226m"
GREEN="\033[38;5;46m"
RED="\033[38;5;196m"
RESET="\033[0m"

# ----------- BANNER -----------
show_banner() {
    echo -e "
████████  ████ ██    ██  ██████   ██      ██ ████████ ████ ████████
██     ██  ██  ███   ██ ██    ██  ██      ██      ██   ██  ██     ██
██     ██  ██  ████  ██ ██        ██      ██     ██    ██  ██     ██
████████   ██  ██ ██ ██ ██   ████ ██      ██    ██     ██  ████████
██         ██  ██  ████ ██     ██ ██      ██   ██      ██  ██
██         ██  ██   ███ ██     ██ ██      ██  ██       ██  ██
██        ████ ██    ██  ██████    ████████  ████████ ████ ██

${BLUE}[+]${RESET} - ${YELLOW}Made with love by The Penguin of Mario${RESET}
"
    sleep 1
}

# ----------- VARIACIONES DE CONTRASEÑAS -----------
generate_variations() {
    local pass="$1"
    echo "$pass"
    echo "${pass}123"
    echo "${pass}!"
    echo "abc${pass}"
    echo "${pass^^}"
    echo "${pass,,}"
    echo "${pass:0:1}${pass:1}"
}

# ----------- MULTIPLATAFORMA -----------
setup_environment() {
    case "$(uname -s)" in
        Darwin*) STAT_CMD="stat -f %z"; SHASUM="shasum -a 256" ;;
        Linux*)  STAT_CMD="stat -c %s"; SHASUM="sha256sum" ;;
        *) echo -e "${RED}Sistema operativo no soportado${RESET}"; exit 1 ;;
    esac
}

# ----------- MANEJO DE SEÑALES -----------
handle_interrupt() {
    echo -e "\n${YELLOW}[!] Interrupción detectada. Mostrando resumen...${RESET}"
    show_summary "${RED}INTERRUPCIÓN${RESET}"
    cleanup
    exit 1
}

# ----------- LIMPIEZA -----------
cleanup() {
    [[ -f "$ZIP_CACHE" ]] && rm -f "$ZIP_CACHE"
}

# ----------- RESUMEN -----------
show_summary() {
    local end_time=$(date +%s)
    local total_time=$((end_time - START_TIME))
    echo -e "\n${BLUE}=== RESUMEN DE EJECUCIÓN ==="
    echo -e "Archivo analizado: ${YELLOW}$ZIPFILE${BLUE}"
    echo -e "Diccionario usado: ${YELLOW}$WORDLIST${BLUE}"
    echo -e "Tamaño del diccionario: ${YELLOW}$TOTAL_LINES líneas${BLUE}"
    echo -e "Variaciones activadas: ${YELLOW}${ENABLE_VARIATIONS}${BLUE}"
    echo -e "Contraseñas probadas: ${YELLOW}$ATTEMPT_COUNT${BLUE}"
    echo -e "Tiempo total: ${YELLOW}${total_time} segundos${BLUE}"
    [[ $total_time -gt 0 ]] && \
    echo -e "Velocidad promedio: ${YELLOW}$((ATTEMPT_COUNT / total_time)) p/s${BLUE}"
    echo -e "Estado final: ${1}${RESET}"
}

# ----------- DEPENDENCIAS -----------
check_dependencies() {
    local missing=()
    # Herramienta zip preferente
    if command -v 7z &> /dev/null; then
        ZIP_TOOL="7z"
        ZIP_TEST_CMD="7z t -p{password} -y {zipfile} &>/dev/null"
    elif command -v unzip &> /dev/null; then
        ZIP_TOOL="unzip"
        ZIP_TEST_CMD="unzip -t -P {password} {zipfile} &>/dev/null"
    else
        missing+=("7z o unzip")
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo -e "${RED}Faltan dependencias críticas:${RESET}"
        for m in "${missing[@]}"; do echo -e " - ${YELLOW}$m${RESET}"; done
        exit 1
    fi

    echo -e "${BLUE}[+]${RESET} Usando herramienta: ${YELLOW}$ZIP_TOOL${RESET}"
}

# ----------- FUNCIÓN GENÉRICA DE PRUEBA -----------
test_password() {
    local zipfile="$1" password="$2"
    local cmd="${ZIP_TEST_CMD//\{password\}/"$password"}"
    cmd="${cmd//\{zipfile\}/"$zipfile"}"
    eval "$cmd"
}

# ----------- CONFIG INICIAL -----------
trap handle_interrupt SIGINT
VERBOSE=0
ZIP_CACHE=""
ENABLE_VARIATIONS=0
START_TIME=0
ATTEMPT_COUNT=0
TOTAL_LINES=0

# ----------- INICIO -----------
show_banner
check_dependencies
setup_environment

# ----------- ARGUMENTOS -----------
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -v) VERBOSE=1; shift ;;
        -vv) VERBOSE=2; shift ;;
        *) break ;;
    esac
done

if [[ "$#" -ne 2 ]]; then
    echo -e "${RED}Uso: $0 [-v|-vv] archivo.zip diccionario.txt${RESET}"
    exit 1
fi

ZIPFILE="$1"
WORDLIST="$2"

[[ ! -f "$ZIPFILE" ]] && echo -e "${RED}El archivo ZIP no existe${RESET}" && exit 1
[[ ! -f "$WORDLIST" ]] && echo -e "${RED}El diccionario no existe${RESET}" && exit 1

# ----------- VARIACIONES -----------
read -rp "$(echo -e "${BLUE}[?]${RESET} ¿Deseas probar variaciones de contraseñas? (s/n): ")" USE_VARIATIONS
USE_VARIATIONS=${USE_VARIATIONS,,}
[[ "$USE_VARIATIONS" =~ ^(s|si|y|yes)$ ]] && ENABLE_VARIATIONS=1

# ----------- CACHE RAM -----------
ZIP_CACHE="/dev/shm/${ZIPFILE##*/}"
cp "$ZIPFILE" "$ZIP_CACHE" && trap "cleanup" EXIT || exit 1

# ----------- ESTADÍSTICAS -----------
START_TIME=$(date +%s)
TOTAL_LINES=$(wc -l < "$WORDLIST")
[[ $VERBOSE -ge 1 ]] && echo -e "${BLUE}Iniciando proceso con ${YELLOW}$TOTAL_LINES${BLUE} entradas base${RESET}"

# ----------- ATAQUE -----------
while IFS= read -r base_password || [[ -n "$base_password" ]]; do
    password_list=("$base_password")
    [[ $ENABLE_VARIATIONS -eq 1 ]] && mapfile -t variations < <(generate_variations "$base_password") && password_list+=("${variations[@]}")

    for password in "${password_list[@]}"; do
        ((ATTEMPT_COUNT++))

        [[ $VERBOSE -ge 2 ]] && echo -e "${YELLOW}Probando (${ATTEMPT_COUNT}): ${password:0:12}$([[ ${#password} -gt 12 ]] && echo '...')${RESET}"

        if test_password "$ZIP_CACHE" "$password"; then
            echo -e "\n\n${GREEN}[+] ¡Contraseña encontrada!: ${YELLOW}$password${RESET}"
            show_summary "${GREEN}ÉXITO${RESET}"
            exit 0
        fi

        if [[ $((ATTEMPT_COUNT % 100)) -eq 0 ]] || [[ $VERBOSE -ge 1 ]]; then
            elapsed=$(( $(date +%s) - START_TIME ))
            speed=$(( ATTEMPT_COUNT / (elapsed + 1) ))
            echo -ne "${BLUE}Progreso: ${YELLOW}$ATTEMPT_COUNT${BLUE} intentos | Velocidad: ${YELLOW}$speed p/s${BLUE} | Tiempo: ${YELLOW}${elapsed}s${RESET}\r"
        fi
    done
done < "$WORDLIST"

# ----------- FIN -----------
show_summary "${RED}FRACASO${RESET}"
exit 1
