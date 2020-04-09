#!/bin/bash

package() {
  if [ ! -d "$1" ]; then
    echo "Missing package directory"
    exit 1
  fi

  local ver=$(cat Include/AppleSupportPkgVersion.h | grep APPLE_SUPPORT_VERSION | cut -f4 -d' ' | cut -f2 -d'"' | grep -E '^[0-9.]+$')
  if [ "$ver" = "" ]; then
    echo "Invalid version $ver"
  fi

  pushd "$1" || exit 1
  rm -rf tmp || exit 1
  mkdir -p tmp/Drivers || exit 1
  mkdir -p tmp/Tools   || exit 1
  cp AudioDxe.efi tmp/Drivers/          || exit 1
  cp ApfsDriverLoader.efi tmp/Drivers/  || exit 1
  cp VBoxHfs.efi tmp/Drivers/           || exit 1
  pushd tmp || exit 1
  zip -qry -FS ../"AppleSupport-${ver}-${2}.zip" * || exit 1
  popd || exit 1
  rm -rf tmp || exit 1
  popd || exit 1
}

cd $(dirname "$0")
ARCHS=(X64 IA32)
SELFPKG=AppleSupportPkg
DEPNAMES=('EfiPkg' 'OpenCorePkg')
DEPURLS=('https://github.com/acidanthera/EfiPkg' 'https://github.com/acidanthera/OpenCorePkg')
DEPBRANCHES=('master' 'master')
unset WORKSPACE
unset PACKAGES_PATH

BUILDDIR=$(pwd)

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
  if [ "$2" != "UDK" ]; then
    sym=$(find . -not -type d -exec file "{}" ";" | grep CRLF)
    if [ "${sym}" != "" ]; then
      echo "Repository $1 named $2 contains CRLF line endings"
      echo "$sym"
      exit 1
    fi
  fi
  popd >/dev/null
}

abortbuild() {
  echo "Build failed!"
  tail -500 build.log
  exit 1
}

pingme() {
  local timeout=200 # in 30s
  local count=0
  local cmd_pid=$1
  shift

  while [ $count -lt $timeout ]; do
    count=$(($count + 1))
    printf "."
    sleep 30
  done

  echo "\n\033[31;1mTimeout reached. Terminating $@.\033[0m"
  kill -9 $cmd_pid
}

buildme() {
  build "$@" &>build.log &
  local cmd_pid=$!

  pingme $! build "$@" &
  local mon_pid=$!
  local result

  { wait $cmd_pid 2>/dev/null; result=$?; ps -p$mon_pid 2>&1>/dev/null && kill $mon_pid; } || return 1
  return $result
}

if [ "${SELFPKG}" = "" ]; then
  echo "You are required to set SELFPKG variable!"
  exit 1
fi

if [ "${BUILDDIR}" != "$(printf "%s\n" ${BUILDDIR})" ]; then
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
  prompt "Install last tested version automatically?"
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
  prompt "Install prebuilt mtoc automatically?"
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

if [ "$RELPKG" = "" ]; then
  RELPKG="$SELFPKG"
fi

if [ "$ARCHS" = "" ]; then
  ARCHS=('X64')
fi

if [ "$TOOLCHAINS" = "" ]; then
  if [ "$(uname)" = "Darwin" ]; then
    TOOLCHAINS=('XCODE5')
  else
    TOOLCHAINS=('CLANGPDB' 'GCC5')
  fi
fi

if [ "$TARGETS" = "" ]; then
  TARGETS=('DEBUG' 'RELEASE' 'NOOPT')
fi

if [ "$RTARGETS" = "" ]; then
  RTARGETS=('DEBUG' 'RELEASE')
fi

SKIP_TESTS=0
SKIP_BUILD=0
SKIP_PACKAGE=0
MODE=""

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

echo "Primary toolchain ${TOOLCHAINS[0]} and arch ${ARCHS[0]}"

if [ ! -d "Binaries" ]; then
  mkdir Binaries || exit 1
  cd Binaries || exit 1
  for target in ${TARGETS[@]}; do
    ln -s ../UDK/Build/"${RELPKG}/${target}_${TOOLCHAINS[0]}/${ARCHS[0]}" "${target}" || exit 1
  done
  cd .. || exit 1
fi

if [ ! -f UDK/UDK.ready ]; then
  rm -rf UDK

  sym=$(find . -not -type d -exec file "{}" ";" | grep CRLF)
  if [ "${sym}" != "" ]; then
    echo "Error: the following files in the repository CRLF line endings:"
    echo "$sym"
    exit 1
  fi
fi

updaterepo "https://github.com/acidanthera/audk" UDK master || exit 1
cd UDK
HASH=$(git rev-parse origin/master)

if [ -d ../Patches ]; then
  if [ ! -f patches.ready ]; then
    for i in ../Patches/* ; do
      git apply --ignore-whitespace "$i" || exit 1
      git add * || exit 1
      git commit -m "Applied patch $i" || exit 1
    done
    touch patches.ready
  fi
fi

deps="${#DEPNAMES[@]}"
for ((i=0; $i<$deps; i++)); do
  updaterepo "${DEPURLS[$i]}" "${DEPNAMES[$i]}" "${DEPBRANCHES[$i]}" || exit 1
done

if [ ! -d "${SELFPKG}" ]; then
  ln -s .. "${SELFPKG}" || exit 1
fi

source edksetup.sh || exit 1

if [ "$SKIP_TESTS" != "1" ]; then
  echo "Testing..."
  make -C BaseTools -j || exit 1
  touch UDK.ready
fi

if [ "$SKIP_BUILD" != "1" ]; then
  echo "Building..."
  for arch in ${ARCHS[@]} ; do
    for toolchain in ${TOOLCHAINS[@]}; do
      for target in ${TARGETS[@]}; do
        if [ "$MODE" = "" ] || [ "$MODE" = "$target" ]; then
          echo "Building ${SELFPKG}/${SELFPKG}.dsc for $arch in $target with ${toolchain}..."
          buildme -a "$arch" -b "$target" -t "${toolchain}" -p "${SELFPKG}/${SELFPKG}.dsc" || abortbuild
          echo " - OK"
        fi
      done
    done
  done
fi

cd .. || exit 1

if [ "$(type -t package)" = "function" ]; then
  if [ "$SKIP_PACKAGE" != "1" ]; then
    echo "Packaging..."
    for rtarget in ${RTARGETS[@]}; do
      if [ "$PACKAGE" = "" ] || [ "$PACKAGE" = "$rtarget" ]; then
        package "Binaries/$rtarget" "$rtarget" "$HASH" || exit 1
      fi
    done
  fi
fi
