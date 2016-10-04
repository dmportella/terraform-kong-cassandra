# Configure the Docker provider
provider "docker" {
	host = "unix:///var/run/docker.sock"
}

resource "docker_image" "cassandra" {
    name = "cassandra:2.2.7"
}

resource "docker_image" "kong" {
    depends_on = ["docker_container.database"]
    name = "mashape/kong:0.9.0"
}

resource "docker_container" "database" {
    image = "${docker_image.cassandra.latest}"
    name = "kong-database"

    count = 1

    ports {
    	internal = 9042
    	external = 9042
    }

    log_driver = "json-file"
    log_opts = {
        max-size = "1m"
        max-file = 2
    }
}

resource "docker_container" "kong" {
    image = "${docker_image.kong.latest}"
    name = "kong"

    count = 1

    privileged = true
    restart = "always"

    links = ["kong-database:kong-database"]

    ports {
    	internal = 8000
    	external = 8000
    }

    ports {
    	internal = 8443
    	external = 8443
    }

    ports {
    	internal = 8001
    	external = 8001
    }

    ports {
    	internal = 7946
    	external = 7946
    }

    ports {
    	internal = 7946
    	external = 7946
    	protocol = "udp"
    }

    env = ["KONG_LOG_LEVEL=debug",
    "KONG_DATABASE=cassandra",
    "KONG_CASSANDRA_CONTACT_POINTS=kong-database",
    "KONG_PG_HOST=kong-database"]

    log_driver = "json-file"
    log_opts = {
        max-size = "1m"
        max-file = 2
    }
}