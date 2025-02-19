[
  {
    "name": "${container_name}",
    "image": "${app_image}",
    "entryPoint": [],
    "essential": true,
    "cpu": ${app_cpu},
    "memory": ${app_memory},
    "networkMode": "awsvpc",
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${log_group_name}",
        "awslogs-region": "${aws_region}",
        "awslogs-stream-prefix": "ecs"
      }
    },
    "portMappings": [
      {
        "containerPort": ${container_port},
        "hostPort": ${container_port}
      }
    ],
    "mountPoints": ${mount_points}
  }%{ if enable_newrelic_monitoring }
  ,
  {
    "name": "${container_name}-newrelic-infra",
    "image": "${new_relic_image}",
    "cpu": ${new_relic_cpu},
    "memoryReservation": ${new_relic_memory},
    "essential": true,
    "environment": [
      {
        "name": "NRIA_OVERRIDE_HOST_ROOT",
        "value": ""
      },
      {
        "name": "NRIA_IS_FORWARD_ONLY",
        "value": "true"
      },
      {
        "name": "FARGATE",
        "value": "true"
      },
      {
        "name": "NRIA_PASSTHROUGH_ENVIRONMENT",
        "value": "ECS_CONTAINER_METADATA_URI,ECS_CONTAINER_METADATA_URI_V4,FARGATE"
      },
      {
        "name": "NRIA_CUSTOM_ATTRIBUTES",
        "value": "{\"nrDeployMethod\":\"downloadPage\"}"
      }
    ],
    "secrets": [
      {
        "valueFrom": "${ssm_license_parameter_name}",
        "name": "NRIA_LICENSE_KEY"
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${new_relic_log_group_name}",
        "awslogs-region": "${aws_region}",
        "awslogs-stream-prefix": "ecs"
      }
    }
  }
  %{ endif }
]