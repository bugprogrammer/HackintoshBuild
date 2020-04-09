#!/bin/bash

BUILDDIR=$(dirname "$0")
pushd "$BUILDDIR" >/dev/null
BUILDDIR=$(pwd)
popd >/dev/null

cd "$BUILDDIR"

prompt() {
  echo "$1"
  if [ "$FORCE_INSTALL" != "1" ]; then
    read -p "Enter [Y]es to continue: " v
    if [ "$v" != "Y" ] && [ "$v" != "y" ]; then
      exit 1
    fi
  fi
}

updaterepo() {
  if [ ! -d "$2" ]; then
    git clone "$1" -b "$3" --depth=1 "$2" || exit 1
  fi
  pushd "$2" >/dev/null
  git pull
  if [ "$2" != "edk2" ]; then
    sym=$(find . -not -type d -exec file "{}" ";" | grep CRLF)
    if [ "${sym}" != "" ]; then
      echo "Repository $1 named $2 contains CRLF line endings"
      exit 1
    fi
  fi
  popd >/dev/null
}

package() {
  if [ ! -d "$1" ]; then
    echo "Missing package directory"
    exit 1
  fi

  local ver=$(cat Include/OpenCore.h | grep OPEN_CORE_VERSION | sed 's/.*"\(.*\)".*/\1/' | grep -E '^[0-9.]+$')
  if [ "$ver" = "" ]; then
    echo "Invalid version $ver"
  fi

  selfdir=$(pwd)
  pushd "$1" || exit 1
  rm -rf tmp || exit 1
  mkdir -p tmp/EFI || exit 1
  mkdir -p tmp/EFI/OC || exit 1
  mkdir -p tmp/EFI/OC/ACPI || exit 1
  mkdir -p tmp/EFI/OC/Drivers || exit 1
  mkdir -p tmp/EFI/OC/Icons || exit 1
  mkdir -p tmp/EFI/OC/Kexts || exit 1
  mkdir -p tmp/EFI/OC/Tools || exit 1
  mkdir -p tmp/EFI/BOOT || exit 1
  mkdir -p tmp/Docs/AcpiSamples || exit 1
  mkdir -p tmp/Utilities || exit 1
  cp OpenCore.efi tmp/EFI/OC/ || exit 1
  cp BOOTx64.efi tmp/EFI/BOOT/ || exit 1
  cp OpenUsbKbDxe.efi tmp/EFI/OC/Drivers/ || exit 1
  cp OpenRuntime.efi tmp/EFI/OC/Drivers/ || exit 1
  cp HiiDatabase.efi tmp/EFI/OC/Drivers/ || exit 1
  cp MmapDump.efi tmp/EFI/OC/Tools/ || exit 1
  cp NvmExpressDxe.efi tmp/EFI/OC/Drivers/ || exit 1
  cp XhciDxe.efi tmp/EFI/OC/Drivers/ || exit 1
  cp BootKicker.efi tmp/EFI/OC/Tools/ || exit 1
  cp CleanNvram.efi tmp/EFI/OC/Tools/ || exit 1
  cp GopStop.efi tmp/EFI/OC/Tools/ || exit 1
  cp HdaCodecDump.efi tmp/EFI/OC/Tools/ || exit 1
  cp VerifyMsrE2.efi tmp/EFI/OC/Tools/ || exit 1
  cp Shell.efi tmp/EFI/OC/Tools/OpenShell.efi || exit 1
  cp KeyTester.efi tmp/EFI/OC/Tools/ || exit 1
  cp ChipTune.efi tmp/EFI/OC/Tools/ || exit 1
  cp OpenControl.efi tmp/EFI/OC/Tools/ || exit 1
  cp "${selfdir}/Docs/Configuration.pdf" tmp/Docs/ || exit 1
  cp "${selfdir}/Docs/Differences/Differences.pdf" tmp/Docs/ || exit 1
  cp "${selfdir}/Docs/Sample.plist" tmp/Docs/ || exit 1
  cp "${selfdir}/Docs/SampleFull.plist" tmp/Docs/ || exit 1
  cp "${selfdir}/Changelog.md" tmp/Docs/ || exit 1
  cp -r "${selfdir}/Docs/AcpiSamples/" tmp/Docs/AcpiSamples/ || exit 1
  cp -r "${selfdir}/Themes/Default/Light/Icons/" tmp/EFI/OC/Icons/ || exit 1
  cp -r "${selfdir}/Utilities/BootInstall" tmp/Utilities/ || exit 1
  cp -r "${selfdir}/Utilities/CreateVault" tmp/Utilities/ || exit 1
  cp -r "${selfdir}/Utilities/LogoutHook" tmp/Utilities/ || exit 1
  pushd tmp || exit 1
  zip -qry -FS ../"NDK-OpenCore-${ver}-${2}.zip" * || exit 1
  popd || exit 1
  rm -rf tmp || exit 1
  popd || exit 1
}

if [ "$BUILDDIR" != "$(printf "%s\n" $BUILDDIR)" ]; then
  echo "EDK2 build system may still fail to support directories with spaces!"
  exit 1
fi

if [ "$(which clang)" = "" ] || [ "$(which git)" = "" ] || [ "$(clang -v 2>&1 | grep "no developer")" != "" ] || [ "$(git -v 2>&1 | grep "no developer")" != "" ]; then
  echo "Missing Xcode tools, please install them!"
  exit 1
fi

if [ "$(nasm -v)" = "" ] || [ "$(nasm -v | grep Apple)" != "" ]; then
  echo "Missing or incompatible nasm!"
  echo "Download the latest nasm from http://www.nasm.us/pub/nasm/releasebuilds/"
  pushd /tmp >/dev/null
  rm -rf nasm-mac64.zip
  curl -OL "https://github.com/acidanthera/ocbuild/raw/master/external/nasm-mac64.zip" || exit 1
  nasmzip=$(cat nasm-mac64.zip)
  rm -rf nasm-*
  curl -OL "https://github.com/acidanthera/ocbuild/raw/master/external/${nasmzip}" || exit 1
  unzip -q "${nasmzip}" nasm*/nasm nasm*/ndisasm || exit 1
  sudo mkdir -p /usr/local/bin || exit 1
  sudo mv nasm*/nasm /usr/local/bin/ || exit 1
  sudo mv nasm*/ndisasm /usr/local/bin/ || exit 1
  rm -rf "${nasmzip}" nasm-*
  popd >/dev/null
fi

mtoc_hash=$(curl -L "https://github.com/acidanthera/ocbuild/raw/master/external/mtoc-mac64.sha256") || exit 1

if [ "${mtoc_hash}" = "" ]; then
  echo "Cannot obtain the latest compatible mtoc hash!"
  exit 1
fi

valid_mtoc=true
if [ "$(which mtoc)" != "" ]; then
  mtoc_path=$(which mtoc)
  mtoc_hash_user=$(shasum -a 256 "${mtoc_path}" | cut -d' ' -f1)
  if [ "${mtoc_hash}" = "${mtoc_hash_user}" ]; then
    valid_mtoc=true
  elif [ "${IGNORE_MTOC_VERSION}" = "1" ]; then
    echo "Forcing the use of UNKNOWN mtoc version due to IGNORE_MTOC_VERSION=1"
    valid_mtoc=true
  elif [ "${mtoc_path}" != "/usr/local/bin/mtoc" ]; then
    echo "Custom UNKNOWN mtoc is installed to ${mtoc_path}!"
    echo "Hint: Remove this mtoc or use IGNORE_MTOC_VERSION=1 at your own risk."
    exit 1
  else
    echo "Found incompatible mtoc installed to ${mtoc_path}!"
    echo "Expected SHA-256: ${mtoc_hash}"
    echo "Found SHA-256:    ${mtoc_hash_user}"
    echo "Hint: Reinstall this mtoc or use IGNORE_MTOC_VERSION=1 at your own risk."
  fi
fi

if ! $valid_mtoc; then
  echo "Missing or incompatible mtoc!"
  echo "To build mtoc follow: https://github.com/tianocore/tianocore.github.io/wiki/Xcode#mac-os-x-xcode"
  pushd /tmp >/dev/null
  rm -f mtoc mtoc-mac64.zip
  curl -OL "https://github.com/acidanthera/ocbuild/raw/master/external/mtoc-mac64.zip" || exit 1
  mtoczip=$(cat mtoc-mac64.zip)
  rm -rf mtoc-*
  curl -OL "https://github.com/acidanthera/ocbuild/raw/master/external/${mtoczip}" || exit 1
  unzip -q "${mtoczip}" mtoc || exit 1
  sudo mkdir -p /usr/local/bin || exit 1
  sudo rm -f /usr/local/bin/mtoc /usr/local/bin/mtoc.NEW || exit 1
  sudo cp mtoc /usr/local/bin/mtoc || exit 1
  popd >/dev/null

  mtoc_path=$(which mtoc)
  mtoc_hash_user=$(shasum -a 256 "${mtoc_path}" | cut -d' ' -f1)
  if [ "${mtoc_hash}" != "${mtoc_hash_user}" ]; then
    echo "Failed to install a compatible version of mtoc!"
    echo "Expected SHA-256: ${mtoc_hash}"
    echo "Found SHA-256:    ${mtoc_hash_user}"
    exit 1
  fi
fi


if [ ! -d "Binaries" ]; then
  mkdir Binaries || exit 1
  cd Binaries || exit 1
  ln -s ../edk2/Build/OpenCorePkg/RELEASE_XCODE5/X64 RELEASE || exit 1
  ln -s ../edk2/Build/OpenCorePkg/DEBUG_XCODE5/X64 DEBUG || exit 1
  ln -s ../edk2/Build/OpenCorePkg/NOOPT_XCODE5/X64 NOOPT || exit 1
  cd .. || exit 1
fi

while true; do
  if [ "$1" == "--skip-tests" ]; then
    SKIP_TESTS=1
    shift
  elif [ "$1" == "--skip-build" ]; then
    SKIP_BUILD=1
    shift
  elif [ "$1" == "--skip-package" ]; then
    SKIP_PACKAGE=1
    shift
  else
    break
  fi
done

if [ "$1" != "" ]; then
  MODE="$1"
  shift
fi

if [ ! -f edk2/edk2.ready ]; then
  rm -rf edk2

  sym=$(find . -not -type d -exec file "{}" ";" | grep CRLF)
  if [ "${sym}" != "" ]; then
    echo "Repository CRLF line endings"
    exit 1
  fi
fi

updaterepo "https://github.com/tianocore/edk2.git" edk2 master || exit 1
cd edk2
updaterepo "https://github.com/acidanthera/EfiPkg" EfiPkg master || exit 1
updaterepo "https://github.com/acidanthera/MacInfoPkg" MacInfoPkg master || exit 1

if [ ! -d OpenCorePkg ]; then
  ln -s .. OpenCorePkg || exit 1
fi

source edksetup.sh || exit 1

if [ "$SKIP_TESTS" != "1" ]; then
  make -C BaseTools || exit 1
  touch edk2.ready
fi

if [ "$SKIP_BUILD" != "1" ]; then
  if [ "$MODE" = "" ] || [ "$MODE" = "DEBUG" ]; then
    build -a X64 -b DEBUG -t XCODE5 -p OpenCorePkg/OpenCorePkg.dsc || exit 1
  fi

  if [ "$MODE" = "" ] || [ "$MODE" = "DEBUG" ]; then
    build -a X64 -b NOOPT -t XCODE5 -p OpenCorePkg/OpenCorePkg.dsc || exit 1
  fi

  if [ "$MODE" = "" ] || [ "$MODE" = "RELEASE" ]; then
    build -a X64 -b RELEASE -t XCODE5 -p OpenCorePkg/OpenCorePkg.dsc || exit 1
  fi
fi

cd .. || exit 1

if [ "$SKIP_PACKAGE" != "1" ]; then
  if [ "$PACKAGE" = "" ] || [ "$PACKAGE" = "DEBUG" ]; then
    package "Binaries/DEBUG" "DEBUG" || exit 1
  fi

  if [ "$PACKAGE" = "" ] || [ "$PACKAGE" = "RELEASE" ]; then
    package "Binaries/RELEASE" "RELEASE" || exit 1
  fi
fi

if [[ -d "$(pwd)"/edk2/Build/OpenCorePkg/RELEASE_XCODE5/X64 ]]; then
  open "$(pwd)"/edk2/Build/OpenCorePkg/RELEASE_XCODE5/X64
else
  echo && echo "Directory not found."
  sleep 2
fi
