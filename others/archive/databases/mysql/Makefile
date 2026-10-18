
run:
	podman run -d \
	--name mysql-db \
	-e MYSQL_ROOT_PASSWORD=strongpassword \
	-p 3306:3306 \
	-v mysql_data:/var/lib/mysql \
	mysql:8


DB_CONTAINER=wordpress-stack_db_1
DB_USER=exampleuser
DB_PASS=examplepass
DB_NAME=new_exampledb
DUMP=wordpress_backup.sql

create-db:
	podman exec -e MYSQL_PWD=$(DB_PASS) $(DB_CONTAINER) \
	mysql -u $(DB_USER) -e "CREATE DATABASE IF NOT EXISTS $(DB_NAME);"

restore-db:
	cat $(DUMP) | podman exec -i -e MYSQL_PWD=$(DB_PASS) $(DB_CONTAINER) \
	mysql -u $(DB_USER) $(DB_NAME)

reset-db:
	podman exec -e MYSQL_PWD=$(DB_PASS) $(DB_CONTAINER) \
	mysql -u $(DB_USER) -e "DROP DATABASE IF EXISTS $(DB_NAME); CREATE DATABASE $(DB_NAME);"

restore: reset-db restore-db