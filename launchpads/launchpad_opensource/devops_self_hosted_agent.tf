
locals {

    run_devops_command = <<EOT
        docker run -d -e AZP_URL=${var.azure_devops_url_organization} -e AZP_TOKEN=${var.azure_devops_pat_token} -e AZP_POOL="${var.azure_devops.agent_pools.level0.name}" ${module.blueprint_container_registry.object.login_server}/devops
EOT
}

##
#   4 - Connect to the Azure devops server and pull the devops container from the registry
##
resource "null_resource" "run_devops_container" {
    depends_on = [
        null_resource.pull_docker_image
    ]

    connection {
        type        = "ssh"
        user        = module.blueprint_devops_self_hosted_agent.object.admin_username
        host        = module.blueprint_devops_self_hosted_agent.object.public_ip_address
        private_key = file("~/.ssh/${module.blueprint_devops_self_hosted_agent.object.public_ip_address}.private")
        agent       = false 
    }

    provisioner "remote-exec" {
        inline = [
            local.run_devops_command
        ]
        on_failure = fail
    }

    triggers = {
        docker_build_command    = sha256(local.run_devops_command)

        # Triggers from the dependency
        docker_build_command    = sha256(local.docker_build_command)
        login_server            = module.blueprint_container_registry.object.login_server
        admin_username          = module.blueprint_container_registry.object.admin_username
        admin_password          = module.blueprint_container_registry.object.admin_password
        azure_devops_agent_pool = var.azure_devops.agent_pools.level0.name
    }
}


