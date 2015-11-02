docker kill co-postgres
docker rm co-postgres

docker \
	run \
		--name co-postgres \
		-e POSTGRES_PASSWORD=Initial1 \
		-d torpedro/postgres
		
