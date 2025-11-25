# Name of your service (from docker-compose.yml)
SERVICE=cuda-notebook

# Build the image
build:
	docker compose build

# Start the container (build if needed)
up:
	docker compose up

# Start in detached mode
upd:
	docker compose up -d

# Stop and remove the running containers
down:
	docker compose down

# Rebuild without cache
rebuild:
	docker compose build --no-cache

# Enter a shell inside the running container
shell:
	docker compose exec $(SERVICE) /bin/bash

# View logs
logs:
	docker compose logs -f

# Remove all containers + images created by this compose file
clean:
	docker compose down --rmi all --volumes
