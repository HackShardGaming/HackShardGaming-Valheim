#!/bin/bash

# exit on error
set -e

# this is loosely based on ubuntu. If you use a different linux distribution, this will likely be something else.
TERMINAL="xterm"

SERVER_NAME="1F31A"
# NOTE: UDP ports 2456-2458 must be forwarded by your firewall/router
SERVER_PORT=2456
WORLD_NAME="ValheimUltimate"
# NOTE: Minimum password length is 5 characters & Password cannot exist as part of the server name.
# if a password is not selected, a new, random one will be generated on startup
SERVER_PASS=""
SERVER_PUBLIC=1






########################
## END OF USER SETTINGS
########################

SCRIPT_NAME=$(readlink -nf "$0")
SCRIPT_DIR=$(dirname "${SCRIPT_NAME}")
RUNNING_USER=$(id -un)


VALHEIM_INSTALL_DIR="${SCRIPT_DIR}"
VALHEIM_EXE="${VALHEIM_INSTALL_DIR}/valheim_server.x86_64"



#NOTE: for Doorstop + BepInEx to work, you MUST have core_lib!
DOORSTOP_DLL="libdoorstop_x64.so"
DOORSTOP_DIR="${VALHEIM_INSTALL_DIR}/BepInEx/doorstop"
DOORSTOP_INJECT_DLL="${VALHEIM_INSTALL_DIR}/BepInEx/core/BepInEx.Preloader.dll"
CORE_DIR="${VALHEIM_INSTALL_DIR}/BepInEx/core_lib"


# make a random password if one is not set
SERVER_PASS=${SERVER_PASS:-$(head /dev/urandom | LC_ALL=C tr -dc A-Za-z0-9 | head -c10)}

# shellcheck disable=SC2089
START_COMMAND="${VALHEIM_EXE} \
-nographics -batchmode \
-name ${SERVER_NAME} \
-port ${SERVER_PORT} \
-world ${WORLD_NAME} \
-password ${SERVER_PASS} \
-public ${SERVER_PUBLIC}"

export SteamAppId=892970
export LD_LIBRARY_PATH="${VALHEIM_INSTALL_DIR}/linux64/:${LD_LIBRARY_PATH}"


# Running as root exposes your machine to malware and is unnecessary in a large majority of cases.
# For Valheim it is not required, however in those rare cases where you're an advanced user that
# requires root access, there is an override provided `UNSAFE_ROOT_EXECUTION`.
# This can be:
# 1) environment variable `UNSAFE_ROOT_EXECUTION=true ./valheim.sh`
# 2) command parameter `./valheim.sh UNSAFE_ROOT_EXECUTION`
for arg in "$@"; do
  case "$arg" in
  UNSAFE_ROOT_EXECUTION)
    UNSAFE_ROOT_EXECUTION=true
    break
    ;;

  *)
    break
    ;;

  esac
done

if [[ "${UNSAFE_ROOT_EXECUTION}" != true && "$(id -u)" == "0" ]]; then
  echo -ne "
ERROR: Running as root exposes your machine to malware and is unnecessary in a large majority of cases.
For Valheim it is not required, however in those rare cases where you're an advanced user that
requires root access, there is an override provided. Search the docs for UNSAFE_ROOT_EXECUTION.
" >&2
  exit 1
fi

# shellcheck disable=SC2009
PID=$(ps aux | grep -v grep | grep "${VALHEIM_EXE}" | grep ${SERVER_NAME} | grep "${WORLD_NAME}" | grep "${SERVER_PASS}" | grep ${SERVER_PORT} | awk '{print $2}')

if [ -n "${PID}" ]; then
  echo "Cannot start server. Valheim server is already running with PID: ${PID}.  Aborting!"
  exit 1
fi


# check if doorstop is installed (if yes, LD_PRELOAD stuff)
RUNNING_DOORSTOP=false
if [[ -f "${DOORSTOP_DIR}/${DOORSTOP_DLL}" && -f "${DOORSTOP_INJECT_DLL}" ]]; then
  RUNNING_DOORSTOP=true

  if [[ -d "${CORE_DIR}" ]]; then
    export DOORSTOP_CORLIB_OVERRIDE_PATH="${CORE_DIR}"
  fi
fi

LOCAL_VERSION=$(grep buildid "${VALHEIM_INSTALL_DIR}/steamapps/appmanifest_896660.acf" | cut -d'"' -f4)

# weird errors if we export this elsewhere
ORIG_TERM=${TERM}
export TERM="${TERMINAL}"

echo -e "
         Install Dir: ${VALHEIM_INSTALL_DIR}
                User: ${RUNNING_USER}

 Terminal (active)  : ${ORIG_TERM}
 Terminal (override): ${TERM}

             Version: ${LOCAL_VERSION}
              Server: ${SERVER_NAME}
                Port: ${SERVER_PORT}
               World: ${WORLD_NAME}
            Password: ${SERVER_PASS}
"

if [[ "${RUNNING_DOORSTOP}" == true ]]; then
  echo -e "\nInjecting preloader into Unity..."

  if [[ -d "${CORE_DIR}" ]]; then
    echo -e "Redirecting core libraries to: ${CORE_DIR}"
  fi
else
  echo -e "No valheim injector detected."
fi

# blank line
echo

# check if doorstop is installed (if yes, LD_PRELOAD stuff)
if [[ "${RUNNING_DOORSTOP}" == true ]]; then
  export LD_LIBRARY_PATH=${DOORSTOP_DIR}:${LD_LIBRARY_PATH}

  export DOORSTOP_ENABLE=TRUE
  export DOORSTOP_INVOKE_DLL_PATH="${DOORSTOP_INJECT_DLL}"

  if [ -n "${LD_PRELOAD}" ]; then
    PRELOAD="${DOORSTOP_DLL}:${LD_PRELOAD}"
  else
    PRELOAD="${DOORSTOP_DLL}"
  fi

  # we suppress junk unity debug info and blank lines
  # suppress any line that doesn't start with a word, then suppress any line that ends with 'Found UnityPlayer' 'Load DLL:' 'Base:' 'Fallback handler'
  LD_PRELOAD="${PRELOAD}" ${START_COMMAND}
else
  # we suppress junk unity debug info and blank lines
  # suppress any line that doesn't start with a word, then suppress any line that ends with 'Found UnityPlayer' 'Load DLL:' 'Base:' 'Fallback handler'
  ${START_COMMAND}
fi
