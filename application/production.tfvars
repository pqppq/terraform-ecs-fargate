# remote state conf.
remote_state_key="PROD/platform.tfstate"
remote_state_bucket=${BUCKET_NAME}

# service variables
ecs_task_definition_name="helloworld-app"
ecs_service_name="helloworld-app-service"
docker_container_port=8080
desired_task_number = 2
docker_image_url=${DOCKER_IMAGE_URL}
memory= 1024
essential=true
