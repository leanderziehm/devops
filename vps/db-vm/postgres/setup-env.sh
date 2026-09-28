POSTGRES_PASSWORD=$(openssl rand -base64 140) podman compose up -d

# echo "POSTGRES_PASSWORD=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 32)" > .env
