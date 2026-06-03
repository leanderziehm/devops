run:
	podman run --rm -it -v $PWD/postgresql/16/main:/var/lib/postgresql/data -p 5432:5432 docker.io/library/postgres:16

new:
	podman run --name pg16 \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_DB=postgres \
  -p 5432:5432 \
  -v pgdatafresh:/var/lib/postgresql/data \
  -d docker.io/library/postgres:16