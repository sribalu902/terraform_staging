[
  {
    "name": "redis",
    "image": "redis:7-alpine",
    "essential": true,

    "portMappings": [
      {
        "containerPort": 6379,
        "protocol": "tcp"
      }
    ],

    "healthCheck": {
      "command": ["CMD", "redis-cli", "ping"],
      "interval": 5,
      "timeout": 3,
      "retries": 5
    },

    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-region": "${AWS_REGION}",
        "awslogs-group": "/ecs/redis",
        "awslogs-stream-prefix": "redis"
      }
    }
  }
]
