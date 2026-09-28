#!/usr/bin/env bash
set -e

# Find first free port starting at 5432
port=5432
while ss -ltn | grep -q ":$port "; do
  ((port++))
done

echo "Port $port is free."

read -rp "Use port $port? [Y/n] " ans
if [[ "$ans" =~ ^[Nn]$ ]]; then
  read -rp "Port: " port
  ss -ltn | grep -q ":$port " && { echo "Port $port is taken."; exit 1; }
fi

read -rp "Database [postgres]: " db
db=${db:-postgres}

read -rp "User [postgres]: " user
user=${user:-postgres}

read -rp "Generate password? [Y/n] " gen
if [[ ! "$gen" =~ ^[Nn]$ ]]; then
  password=$(openssl rand -base64 32)
else
  read -rsp "Password: " password
  echo
fi

file=".env.db$port"

umask 077
cat > "$file" <<EOF
POSTGRES_PORT=$port
POSTGRES_DB=$db
POSTGRES_USER=$user
POSTGRES_PASSWORD=$password
EOF

echo "Saved: $file"

read -rp "Make this .env and start? [Y/n] " start
if [[ ! "$start" =~ ^[Nn]$ ]]; then
  cp "$file" .env
  podman compose up -d
fi
