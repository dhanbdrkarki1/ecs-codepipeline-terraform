{
  "family": "blog-task-family",
  "containerDefinitions": [
    {
      "name": "${container_name}",
      "image": "${app_image}",
      "essential": true,
      "entryPoint": ["./entrypoint.sh"],
      "command": ["./wait-for-it.sh", "${DB_HOST}:5432", "--", "uwsgi", "--ini", "/code/config/uwsgi/uwsgi.ini"],
      "portMappings": [
        {
          "containerPort": ${container_port},
          "hostPort": ${container_port}
        }
      ],
      "mountPoints": ${mount_points},
      "environment": [
        { "name": "DB_NAME", "value": "${DB_NAME}" },
        { "name": "DB_USER", "value": "${DB_USER}" },
        { "name": "DB_PASSWORD", "value": "${DB_PASSWORD}" },
        { "name": "DB_HOST", "value": "${DB_HOST}" },
        { "name": "DB_PORT", "value": "${DB_PORT}" }
      ]
    },
    {
      "name": "nginx",
      "image": "nginx:latest",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 80,
          "hostPort": 80
        }
      ],
      "mountPoints": [
        {
          "sourceVolume": "nginx-config",
          "containerPath": "/etc/nginx/templates"
        },
        {
          "sourceVolume": "code",
          "containerPath": "/code"
        }
      ]
    }
  ],
  "volumes": [
    {
      "name": "code",
      "host": {
        "sourcePath": "."
      }
    },
    {
      "name": "nginx-config",
      "host": {
        "sourcePath": "./config/nginx"
      }
    }
  ]
}
