#!/bin/bash
cat <<'EOF'
    __  __               __                               ____  ______   ______            ____   _ __                            
   / / / /___ __________/ /      ______ _________        / __ \/_  __/  /_  __/___  ____  / / /__(_) /_                            
  / /_/ / __ `/ ___/ __  / | /| / / __ `/ ___/ _ \______/ /_/ / / /      / / / __ \/ __ \/ / //_/ / __/                            
 / __  / /_/ / /  / /_/ /| |/ |/ / /_/ / /  /  __/_____/ ____/ / /      / / / /_/ / /_/ / / ,< / / /_                              
/_/ /_/\__,_/_/   \__,_/ |__/|__/\__,_/_/   \___/     /_/     /_/      /_/  \____/\____/_/_/|_/_/\__/                              
         ______                __           __   __             ______      __                                   ___________ ____ 
        / ____/_______  ____ _/ /____  ____/ /  / /_  __  __   / ____/_  __/ /_  ___  _________ ___  ____ __  __/ ____/ ___// __ \
       / /   / ___/ _ \/ __ `/ __/ _ \/ __  /  / __ \/ / / /  / /   / / / / __ \/ _ \/ ___/ __ `__ \/ __ `/ |/_/___ \/ __ \/ / / /
      / /___/ /  /  __/ /_/ / /_/  __/ /_/ /  / /_/ / /_/ /  / /___/ /_/ / /_/ /  __/ /  / / / / / / /_/ />  <____/ / /_/ / /_/ / 
      \____/_/   \___/\__,_/\__/\___/\__,_/  /_.___/\__, /   \____/\__, /_.___/\___/_/  /_/ /_/ /_/\__,_/_/|_/_____/\____/\____/  
                                                   /____/         /____/                                                          v0.1
EOF

set -u

BIN_DIR="$HOME/.local/bin"
SRC_DIR="$HOME/.local/src"
DO_UPGRADE=0
BUILD_SOURCE=1

# ---------------------------------------------------------------------------
# Tool groups for Kali rolling. Unavailable packages are skipped and reported.
# ---------------------------------------------------------------------------
base_tools=(git curl wget default-jdk 7zip zip unzip python3-pip python3-venv
    cmake build-essential g++ pkg-config zlib1g-dev liblzma-dev liblz4-dev libzstd-dev)

re_tools=(gdb gdb-multiarch radare2 rizin ghidra jadx apktool binutils-multiarch ltrace strace
    patchelf nasm checksec python3-pwntools python3-capstone python3-keystone python3-unicorn
    upx-ucl hexedit xxd bsdextrautils yara
    qemu-user qemu-user-binfmt qemu-system-arm qemu-system-mips qemu-system-misc qemu-utils)

# coreutils provides dd.
firmware_tools=(binwalk coreutils squashfs-tools sasquatch mtd-utils u-boot-tools device-tree-compiler
    cramfsswap erofs-utils f2fs-tools e2fsprogs cpio lzop lz4 zstd xz-utils fdisk kpartx foremost
    firmware-mod-kit python3-jefferson python3-ubireader)

hardware_tools=(openocd flashrom avrdude dfu-util stlink-tools esptool urjtag
    minicom picocom tio screen setserial sigrok sigrok-cli pulseview
    i2c-tools spi-tools gpiod can-utils libnfc-bin mfoc usbutils pciutils bluez
    ubertooth hackrf rtl-sdr python3-serial python3-smbus python3-usb libusb-1.0-0-dev)

network_tools=(wireshark nmap bettercap ettercap-graphical john hashcat)

# name|git URL, built with CMake and installed to ~/.local
source_tools=(
    "moria|https://github.com/nmatt0/moria.git"
    "mithril|https://github.com/nmatt0/mithril.git"
)

INSTALLED=()
PRESENT=()
SKIPPED=()
FAILED=()

info() { printf '\e[34m%s\e[0m\n' "$*"; }
ok()   { printf '\e[32m%s\e[0m\n' "$*"; }
warn() { printf '\e[33m%s\e[0m\n' "$*"; }
err()  { printf '\e[31m%s\e[0m\n' "$*"; }

usage() {
    cat <<USAGE
Usage: $0 [options]

  --upgrade     Run apt-get full-upgrade before installing tools
  --no-source   Skip tools built from source (moria, mithril)
  -h, --help    Show this help
USAGE
}

while (($#)); do
    case "$1" in
        --upgrade) DO_UPGRADE=1 ;;
        --no-source) BUILD_SOURCE=0 ;;
        -h|--help) usage; exit 0 ;;
        *) err "Unknown option: $1"; usage; exit 2 ;;
    esac
    shift
done

as_root() {
    if ((EUID == 0)); then "$@"; else sudo "$@"; fi
}

apt_get() {
    as_root env DEBIAN_FRONTEND=noninteractive apt-get \
        -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold "$@"
}

is_installed() {
    dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "install ok installed"
}

install_pkg() {
    local pkg="$1"
    if is_installed "$pkg"; then
        ok "$pkg is already installed."
        PRESENT+=("$pkg")
        return
    fi
    # A dry run catches packages this distro does not offer, including virtual packages.
    if ! apt-get -s install "$pkg" >/dev/null 2>&1; then
        warn "$pkg is not installable on this system, skipping."
        SKIPPED+=("$pkg")
        return
    fi
    info "Installing $pkg..."
    if apt_get install -y "$pkg"; then
        ok "$pkg installed successfully."
        INSTALLED+=("$pkg")
    else
        err "Failed to install $pkg."
        FAILED+=("$pkg")
    fi
}

install_group() {
    local title="$1" pkg
    shift
    info "=== $title ==="
    for pkg in "$@"; do
        install_pkg "$pkg"
    done
}

build_source() {
    local name="$1" url="$2" dir="$SRC_DIR/$name" before="" after=""

    info "=== $name (from source) ==="
    if [[ -d "$dir/.git" ]]; then
        before="$(git -C "$dir" rev-parse HEAD)"
        if ! git -C "$dir" pull --ff-only; then
            err "Failed to update $name in $dir."
            FAILED+=("$name")
            return
        fi
    elif [[ -e "$dir" ]]; then
        err "$dir exists but is not a git checkout. Move it and re-run."
        FAILED+=("$name")
        return
    elif ! git clone --depth 1 "$url" "$dir"; then
        err "Failed to clone $url."
        FAILED+=("$name")
        return
    fi

    after="$(git -C "$dir" rev-parse HEAD)"
    if [[ "$before" == "$after" && -x "$BIN_DIR/$name" ]]; then
        ok "$name is already up to date."
        PRESENT+=("$name")
        return
    fi

    if cmake -S "$dir" -B "$dir/build" -DCMAKE_BUILD_TYPE=Release \
        && cmake --build "$dir/build" -j "$(nproc)" \
        && cmake --install "$dir/build" --prefix "$HOME/.local"; then
        ok "$name installed to $BIN_DIR."
        INSTALLED+=("$name")
    else
        err "Failed to build $name."
        FAILED+=("$name")
    fi
}

print_list() {
    local label="$1"
    shift
    printf '%-20s %d\n' "$label:" "$#"
    if (($#)); then
        printf '    %s\n' "$*"
    fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
os_id="unknown"
if [[ -r /etc/os-release ]]; then
    os_id="$(. /etc/os-release && printf '%s' "${ID:-unknown}")"
fi
if [[ "$os_id" != "kali" ]]; then
    err "This script supports Kali Linux rolling only (detected: $os_id)."
    exit 1
fi

info "Updating package list..."
if apt_get update; then
    ok "Package list updated successfully."
else
    err "Failed to update package list. Please check your network connection."
    exit 1
fi

if ((DO_UPGRADE)); then
    info "Upgrading packages..."
    if apt_get full-upgrade -y; then
        ok "Packages upgraded successfully."
    else
        err "Failed to upgrade packages. Please check for errors."
        exit 1
    fi
fi

install_group "Base and build tools" "${base_tools[@]}"
install_group "Reverse engineering" "${re_tools[@]}"
install_group "Firmware analysis" "${firmware_tools[@]}"
install_group "Hardware hacking" "${hardware_tools[@]}"
install_group "Network and password auditing" "${network_tools[@]}"

if ((BUILD_SOURCE)); then
    mkdir -p "$BIN_DIR" "$SRC_DIR"
    for entry in "${source_tools[@]}"; do
        build_source "${entry%%|*}" "${entry#*|}"
    done
fi

echo
info "=== Summary ==="
print_list "Newly installed" ${INSTALLED[@]+"${INSTALLED[@]}"}
print_list "Already present" ${PRESENT[@]+"${PRESENT[@]}"}
print_list "Skipped" ${SKIPPED[@]+"${SKIPPED[@]}"}
print_list "Failed" ${FAILED[@]+"${FAILED[@]}"}

if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    warn "$BIN_DIR is not in your PATH. Add this line to your shell profile:"
    warn "  export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

current_user="$(id -un)"
if is_installed wireshark && ! id -nG "$current_user" | grep -qw wireshark; then
    warn "Wireshark non-root capture is not configured for $current_user. To enable it, run:"
    warn "  sudo dpkg-reconfigure wireshark-common"
    warn "  sudo usermod -aG wireshark $current_user"
    warn "Then log out and back in."
fi

if ! id -nG "$current_user" | grep -qw dialout; then
    warn "To use serial adapters without sudo, run: sudo usermod -aG dialout $current_user"
fi

if ((${#FAILED[@]})); then
    err "Setup finished with ${#FAILED[@]} failure(s). Review the errors above."
    exit 1
fi

ok "Setup completed. Happy Hacking!"
