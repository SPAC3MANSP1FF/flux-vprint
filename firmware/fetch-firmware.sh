#!/usr/bin/bash
# ==============================================================================
# flux-vprint: fetch-firmware.sh
# Downloads official Lenovo Windows driver & extracts proprietary sensor firmware
# ==============================================================================

set -e

# Styling
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

TARGET_DIR="${1:-/usr/share/python-validity}"
CACHE_DIR="/var/cache/flux-vprint"
TMP_DIR=$(mktemp -d -t flux-vprint-fw-XXXXXX)

cleanup() {
    rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

echo -e "${BLUE}${BOLD}=== flux-vprint Firmware Installer ===${NC}"

# Check for root if installing to system directory
if [[ "${TARGET_DIR}" == /usr* || "${TARGET_DIR}" == /etc* || "${TARGET_DIR}" == /var* ]]; then
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}[ERROR]${NC} Installing to ${TARGET_DIR} requires root privileges."
        echo -e "Please run: ${BOLD}sudo $0${NC}"
        exit 1
    fi
fi

# Detect USB sensor
SENSOR_ID=""
if lsusb -d 06cb:009a >/dev/null 2>&1; then
    SENSOR_ID="06cb:009a"
elif lsusb -d 138a:0097 >/dev/null 2>&1; then
    SENSOR_ID="138a:0097"
elif lsusb -d 138a:0090 >/dev/null 2>&1; then
    SENSOR_ID="138a:0090"
elif lsusb -d 06cb:009d >/dev/null 2>&1; then
    SENSOR_ID="06cb:009d"
else
    # Default to 06cb:009a (ThinkPad T480)
    SENSOR_ID="06cb:009a"
    echo -e "${YELLOW}[INFO]${NC} No sensor detected via lsusb; defaulting to ${BOLD}06cb:009a${NC} (ThinkPad T480)."
fi

echo -e "${GREEN}[+]${NC} Target sensor: ${BOLD}${SENSOR_ID}${NC}"

case "${SENSOR_ID}" in
    "06cb:009a"|"138a:0097"|"06cb:009d")
        DRIVER_URL="https://download.lenovo.com/pccbbs/mobiles/nz3gf07w.exe"
        FW_FILENAME="6_07f_lenovo_mis_qm.xpfwext"
        EXPECTED_SHA512="a4a4e6058b1ea8ab721953d2cfd775a1e7bc589863d160e5ebbb90344858f147d695103677a8df0b2de0c95345df108bda97196245b067f45630038fb7c807cd"
        ;;
    "138a:0090")
        DRIVER_URL="https://download.lenovo.com/pccbbs/mobiles/n1cgn08w.exe"
        FW_FILENAME="6_07f_Lenovo.xpfwext"
        EXPECTED_SHA512="d839fa65adf4c952ecb4a5c4b2fc5b5bdedd8e02a421564bdc7fae1d281be4ea26fcde2333f2ab78d56cef0fdccce0a3cf429300b89544cdc9cfee6d0fe0db55"
        ;;
    *)
        echo -e "${RED}[ERROR]${NC} Unsupported sensor: ${SENSOR_ID}"
        exit 1
        ;;
esac

# Check for innoextract
if ! command -v innoextract >/dev/null 2>&1; then
    echo -e "${YELLOW}[!]${NC} 'innoextract' not found."
    if command -v zypper >/dev/null 2>&1 && [[ $EUID -eq 0 ]]; then
        echo -e "${BLUE}[*]${NC} Attempting to install innoextract via zypper..."
        zypper --non-interactive in innoextract
    else
        echo -e "${RED}[ERROR]${NC} Please install 'innoextract' first (e.g. sudo zypper in innoextract)"
        exit 1
    fi
fi

# Check for curl or wget
DOWNLOAD_CMD=""
if command -v curl >/dev/null 2>&1; then
    DOWNLOAD_CMD="curl -f -L -s -S --output"
elif command -v wget >/dev/null 2>&1; then
    DOWNLOAD_CMD="wget -q -O"
else
    echo -e "${RED}[ERROR]${NC} Neither curl nor wget was found."
    exit 1
fi

mkdir -p "${CACHE_DIR}" 2>/dev/null || CACHE_DIR="${TMP_DIR}"
EXE_FILE="${CACHE_DIR}/$(basename "${DRIVER_URL}")"

# Download if not already cached and verified
NEEDS_DOWNLOAD=1
if [[ -f "${EXE_FILE}" ]]; then
    ACTUAL_SHA512=$(sha512sum "${EXE_FILE}" | awk '{print $1}')
    if [[ "${ACTUAL_SHA512}" == "${EXPECTED_SHA512}" ]]; then
        echo -e "${GREEN}[+]${NC} Verified cached installer: ${EXE_FILE}"
        NEEDS_DOWNLOAD=0
    fi
fi

if [[ ${NEEDS_DOWNLOAD} -eq 1 ]]; then
    echo -e "${BLUE}[*]${NC} Downloading Lenovo driver executable..."
    echo -e "    URL: ${DRIVER_URL}"
    ${DOWNLOAD_CMD} "${EXE_FILE}" "${DRIVER_URL}"

    echo -e "${BLUE}[*]${NC} Verifying SHA-512 checksum..."
    ACTUAL_SHA512=$(sha512sum "${EXE_FILE}" | awk '{print $1}')
    if [[ "${ACTUAL_SHA512}" != "${EXPECTED_SHA512}" ]]; then
        echo -e "${RED}[ERROR]${NC} SHA-512 mismatch!"
        echo -e "Expected: ${EXPECTED_SHA512}"
        echo -e "Actual:   ${ACTUAL_SHA512}"
        rm -f "${EXE_FILE}"
        exit 1
    fi
    echo -e "${GREEN}[+]${NC} Checksum verified successfully."
fi

# Extract firmware
echo -e "${BLUE}[*]${NC} Extracting firmware (${FW_FILENAME}) via innoextract..."
innoextract --output-dir "${TMP_DIR}" --include "${FW_FILENAME}" --collisions overwrite "${EXE_FILE}" >/dev/null

EXTRACTED_FILE=$(find "${TMP_DIR}" -type f -name "${FW_FILENAME}" | head -n 1)
if [[ -z "${EXTRACTED_FILE}" || ! -f "${EXTRACTED_FILE}" ]]; then
    echo -e "${RED}[ERROR]${NC} Failed to locate ${FW_FILENAME} inside the extracted files."
    exit 1
fi

# Ensure destination directories exist
mkdir -p "${TARGET_DIR}"
mkdir -p /etc/python-validity 2>/dev/null || true
mkdir -p /run/python-validity 2>/dev/null || true

# Copy to persistent target
cp -f "${EXTRACTED_FILE}" "${TARGET_DIR}/${FW_FILENAME}"
chmod 644 "${TARGET_DIR}/${FW_FILENAME}"
echo -e "${GREEN}[+]${NC} Firmware installed to: ${BOLD}${TARGET_DIR}/${FW_FILENAME}${NC}"

# Also mirror to /etc/python-validity as a persistent backup
if [[ -d /etc/python-validity ]]; then
    cp -f "${EXTRACTED_FILE}" "/etc/python-validity/${FW_FILENAME}"
fi

# Link / copy to /run/python-validity for immediate availability
if [[ -d /run/python-validity ]]; then
    ln -sf "${TARGET_DIR}/${FW_FILENAME}" "/run/python-validity/${FW_FILENAME}" 2>/dev/null || \
    cp -f "${EXTRACTED_FILE}" "/run/python-validity/${FW_FILENAME}"
fi

echo -e "${GREEN}${BOLD}✓ Firmware extraction and setup completed successfully!${NC}"

