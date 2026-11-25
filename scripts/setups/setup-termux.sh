# Basic tools
pkg update && pkg upgrade

pkg install vim -y
pkg install git -y

# Python + pip
pkg install python -y
pkg install uv -y

# Node.js + npm
pkg install nodejs -y

# Linux distributions (Ubuntu, Debian, Arch, etc.)

# setup
bash ../dotenv/setup-dotenv.sh

# optional:
# pkg install proot-distro -y
# pkg install tmux
# pkg install openssh
# termux-setup-storage
# ansible?
# java
# udocker? 
# rsync ??
# ...