#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SOURCE="main.cpp"
TARGET="root"
INSTALL_DIR="/usr/local/bin"

detect_distro() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "$ID"
  elif [ -f /etc/gentoo-release ]; then
    echo "gentoo"
  elif [ -f /etc/debian_version ]; then
    echo "debian"
  elif [ -f /etc/redhat-release ]; then
    echo "rhel"
  else
    echo "unknown"
  fi
}

DISTRO=$(detect_distro)

check_and_install_gpp() {
  if ! command -v g++ &>/dev/null; then
    echo -e "${YELLOW}⚠️  g++ not found. Installing...${NC}"

    case "$DISTRO" in
    gentoo)
      echo -e "${BLUE}Detected Gentoo - using emerge${NC}"
      sudo emerge -av sys-devel/gcc
      ;;
    ubuntu | debian | linuxmint | pop)
      echo -e "${BLUE}Detected Debian/Ubuntu - using apt${NC}"
      sudo apt-get update
      sudo apt-get install -y g++ make
      ;;
    fedora | rhel | centos | rocky | almalinux)
      echo -e "${BLUE}Detected RHEL/Fedora - using dnf/yum${NC}"
      if command -v dnf &>/dev/null; then
        sudo dnf install -y gcc-c++ make
      else
        sudo yum install -y gcc-c++ make
      fi
      ;;
    arch | manjaro | endeavouros)
      echo -e "${BLUE}Detected Arch - using pacman${NC}"
      sudo pacman -S --noconfirm gcc make
      ;;
    opensuse | suse)
      echo -e "${BLUE}Detected openSUSE - using zypper${NC}"
      sudo zypper install -y gcc-c++ make
      ;;
    alpine)
      echo -e "${BLUE}Detected Alpine - using apk${NC}"
      sudo apk add g++ make
      ;;
    *)
      echo -e "${RED}❌ Unsupported distribution: $DISTRO${NC}"
      echo -e "${YELLOW}Please install g++ and make manually${NC}"
      exit 1
      ;;
    esac

    echo -e "${GREEN}✓ g++ installed successfully${NC}"
  else
    echo -e "${GREEN}✓ g++ is already installed${NC}"
  fi
}

compile_program() {
  echo -e "${BLUE}Compiling $TARGET...${NC}"

  if [ ! -f "$SOURCE" ]; then
    echo -e "${RED}❌ Error: $SOURCE not found!${NC}"
    exit 1
  fi

  g++ -Wall -Wextra -O2 -o "$TARGET" "$SOURCE"

  if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Compilation successful!${NC}"
  else
    echo -e "${RED}❌ Compilation failed!${NC}"
    exit 1
  fi
}

install_system() {
  echo -e "${BLUE}Installing to $INSTALL_DIR...${NC}"

  if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}Need root privileges for installation${NC}"
    sudo cp "$TARGET" "$INSTALL_DIR/"
    sudo chown root:root "$INSTALL_DIR/$TARGET"
    sudo chmod 4755 "$INSTALL_DIR/$TARGET"
  else
    cp "$TARGET" "$INSTALL_DIR/"
    chown root:root "$INSTALL_DIR/$TARGET"
    chmod 4755 "$INSTALL_DIR/$TARGET"
  fi

  if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Installation complete!${NC}"
    echo -e "${GREEN}You can now run:${NC} $TARGET <command> [args...]"
    echo -e "${GREEN}Example:${NC} $TARGET whoami"
  else
    echo -e "${RED}❌ Installation failed!${NC}"
    exit 1
  fi
}

install_local() {
  echo -e "${BLUE}Setting up local binary...${NC}"

  if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}Need root to set setuid bit${NC}"
    sudo chown root:root "$TARGET"
    sudo chmod 4755 "$TARGET"
  else
    chown root:root "$TARGET"
    chmod 4755 "$TARGET"
  fi

  echo -e "${GREEN}✓ Local setup complete!${NC}"
  echo -e "${GREEN}Run:${NC} ./$TARGET <command> [args...]"
  echo -e "${GREEN}Example:${NC} ./$TARGET whoami"
}

test_program() {
    echo -e "${BLUE}Testing $TARGET...${NC}"

    if /usr/local/bin/root whoami > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Test passed!${NC}"
        echo -e "  $(/usr/local/bin/root whoami 2>/dev/null)"
    else
        echo -e "${RED}✗ Test failed${NC}"
        echo -e "${YELLOW}Try running:${NC} /usr/local/bin/root whoami"
    fi
}

uninstall() {
  echo -e "${YELLOW}Removing $TARGET from $INSTALL_DIR...${NC}"

  if [ "$EUID" -ne 0 ]; then
    sudo rm -f "$INSTALL_DIR/$TARGET"
  else
    rm -f "$INSTALL_DIR/$TARGET"
  fi

  echo -e "${GREEN}✓ Uninstallation complete${NC}"
}

clean() {
  echo -e "${YELLOW}Cleaning...${NC}"
  rm -f "$TARGET"
  echo -e "${GREEN}✓ Clean complete${NC}"
}

show_help() {
  echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║  Root Program Installer                                   ║${NC}"
  echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
  echo ""
  echo -e "${YELLOW}Usage:${NC} ./install.sh [OPTION]"
  echo ""
  echo -e "${BLUE}Options:${NC}"
  echo "  (no option)  - Compile and install system-wide"
  echo "  local        - Compile and setup locally (no system install)"
  echo "  test         - Test the program"
  echo "  uninstall    - Remove from system"
  echo "  clean        - Remove compiled binary"
  echo "  help         - Show this help message"
  echo ""
  echo -e "${BLUE}Examples:${NC}"
  echo "  ./install.sh        # Compile and install system-wide"
  echo "  ./install.sh local  # Compile and setup locally"
  echo "  ./install.sh test   # Test the program"
  echo ""
}

case "$1" in
local)
  check_and_install_gpp
  compile_program
  install_local
  test_program
  ;;
test)
  test_program
  ;;
uninstall)
  uninstall
  ;;
clean)
  clean
  ;;
help | --help | -h)
  show_help
  ;;
*)
  check_and_install_gpp
  compile_program
  install_system
  test_program
  ;;
esac
