#!/usr/bin/env bash
# =======================================================
# SDIIN INTERNET ILIMITADO - SSH Admin Script
# by Favio (botcito repo)
# =======================================================

USERS_GROUP="sshusers"
LIMITS_FILE="/etc/security/limits.conf"
MANAGED_FLAG="# managed-by-ssh-admin"

# --- Verificar root ---
if [ "$EUID" -ne 0 ]; then
  echo "⚠️  Ejecuta este script como root o con sudo."
  exit 1
fi

# --- Funciones auxiliares ---
ensure_group() {
  if ! getent group "$USERS_GROUP" >/dev/null; then
    groupadd "$USERS_GROUP"
  fi
}

add_limits_for_user() {
  local user="$1"
  local max="$2"
  sed -i "/^${user} .*maxlogins/ d" "$LIMITS_FILE"
  echo "${user} hard maxlogins ${max} ${MANAGED_FLAG}" >> "$LIMITS_FILE"
}

remove_limits_for_user() {
  local user="$1"
  sed -i "/^${user} .*maxlogins.*${MANAGED_FLAG}/ d" "$LIMITS_FILE"
}

# --- Crear usuario ---
create_user() {
  local user="$1"
  local pass="$2"
  local days="$3"
  local maxlogins="${4:-2}"

  if id "$user" &>/dev/null; then
    echo "❌ El usuario $user ya existe."
    return 1
  fi
