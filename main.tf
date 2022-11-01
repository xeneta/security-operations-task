terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "2.22.0"
    }
  }
}


provider "docker" {
  host = "unix:///var/run/docker.sock"
}

resource "docker_image" "sec" {
  name = "sec:1.0"
  build {
    path = "."
    tag  = ["sec:1.0"]
  }
}

resource "docker_container" "app_container" {
  name = "app_container"
  image = docker_image.sec.latest
  ports {
    internal = "3000"
    external = "3000"
  }
}

# Populating postsql with the data dump cannot happen before the db service is up, so this data hydration operation
# cannot be easily crammed into Dockerfile. So the following hack wait until the container is ready.
# the api server shall not spin up before the db is ready, here another local hack. In AWS environments, db and api
# are usually separated and these hacks will not be necessary.
resource "null_resource" "provision" {
  depends_on = [docker_container.app_container]
  provisioner "local-exec" {
    command = "sleep 5"
  }
  provisioner "local-exec" {
    command = "docker exec `docker ps|grep '${docker_container.app_container.name}' | awk '{print $1}'` /usr/bin/psql -U postgres -f /opt/db/rates.sql"
  }
  provisioner "local-exec" {
    command = "docker exec `docker ps|grep '${docker_container.app_container.name}' | awk '{print $1}'` /usr/local/bin/gunicorn -b :3000 wsgi"
  }
}