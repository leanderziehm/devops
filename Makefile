sd sdf setupdotfiles:
	bash dotfiles/setup-dotfiles.sh

v vps:
	cd vps && cd $$(hostname) && ls && make

bp backup_postgres:
	bash scripts/backup-postgres.sh

sn setup-nginx:
	bash scripts/setup-nginx.sh

st setup-termux:
	bash setup/setup-termux.sh

n nt ntfy notify:
	bash scripts/utils/notify.sh "test :)"

q qr qrcode:
	python scripts/utils/qrcode-gen.py
