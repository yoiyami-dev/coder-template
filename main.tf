terraform {
  required_providers {
    coder = {
      source = "coder/coder"
    }
    docker = {
      source = "kreuzwerker/docker"
    }
  }
}

locals {
  workspace_name = data.coder_workspace.me.name
  username = data.coder_workspace_owner.me.name
  work_dir = "/home/${local.username}"
  GIT_AUTHOR_NAME = data.coder_workspace_owner.me.full_name
  GIT_AUTHOR_EMAIL = data.coder_workspace_owner.me.email
  GIT_COMMITTER_NAME = data.coder_workspace_owner.me.full_name
  GIT_COMMITTER_EMAIL = data.coder_workspace_owner.me.email
}

data "coder_provisioner" "me" {
}

provider "docker" {
}

data "coder_workspace" "me" {
}
data "coder_workspace_owner" "me" {}


resource "docker_volume" "yy-home" {
    name = "${local.workspace_name}-home"
    lifecycle {
        ignore_changes = all
    }
    # Add labels in Docker to keep track of orphan resources.
    labels {
        label = "coder.owner"
        value = data.coder_workspace_owner.me.name
    }
    labels {
        label = "coder.owner_id"
        value = data.coder_workspace_owner.me.id
    }
    labels {
        label = "coder.workspace_id"
        value = data.coder_workspace.me.id
    }
}

resource "docker_image" "yoiyami" {
    name = "${local.workspace_name}-image"
    build {
        context = "./build"
        dockerfile = "Dockerfile"
        build_args = {
            USER = local.username
        }
    }
    triggers = {
        dir_sha1 = sha1(file("./build/Dockerfile")) # workaround
    }
}

resource "coder_script" "post" {
    display_name = "Post Provisioning"
    agent_id = coder_agent.yoiyami.id
    run_on_start = true
    script = file("./build/post.sh")
}

resource "docker_container" "yoiyami" {
    name = "${local.workspace_name}-container"
    image = docker_image.yoiyami.name
    hostname = local.workspace_name
    restart = "always"
    env = [
        "CODER_AGENT_TOKEN=${coder_agent.yoiyami.token}"
    ]
    entrypoint = ["sh", "-c", replace(coder_agent.yoiyami.init_script, "/localhost|127\\.0\\.0\\.1/", "host.docker.internal")]
    host {
        host    = "host.docker.internal"
        ip      = "host-gateway"
    }
    runtime = "sysbox-runc"

    volumes {
        volume_name = docker_volume.yy-home.name
        container_path = local.work_dir
    }

    dns = ["1.1.1.1"]
}

resource "coder_agent" "yoiyami" {
    arch = "amd64"
    os = "linux"

        env = {
        # Git configuration
        GIT_AUTHOR_NAME = local.GIT_AUTHOR_NAME
        GIT_AUTHOR_EMAIL = local.GIT_AUTHOR_EMAIL
        GIT_COMMITTER_NAME = local.GIT_COMMITTER_NAME
        GIT_COMMITTER_EMAIL = local.GIT_COMMITTER_EMAIL
    }
    # TODO: Metadata
    metadata {
        display_name = "CPU Usage"
        key          = "cpu_usage"
        script       = "coder stat cpu"
        interval     = 10
        timeout      = 1
        order        = 2
    }

    metadata {
        display_name = "RAM Usage"
        key          = "1_ram_usage"
        script       = "coder stat mem"
        interval     = 10
        timeout      = 1
    }

    metadata {
        display_name = "Home Disk"
        key          = "3_home_disk"
        script       = "coder stat disk --path $${HOME}"
        interval     = 60
        timeout      = 1
    }
}
