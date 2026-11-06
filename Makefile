v vps:
	cd vps && cd $$(hostname) && ls && make

bp backup_postgres:
	bash scripts/backup-postgres.sh

sn setup-nginx:
	bash scripts/setup-nginx.sh

st setup-termux
	bash scripts/setups/setup-termux.sh

nt ntfy notify:
	bash scripts/utils/notify.sh "test :)"
