{
  // ============================================
  // REDIS TASK — Fargate
  //
  // Matches Docker Compose:
  //   - image: redis:7-alpine
  //   - healthcheck: redis-cli ping
  //
  // PLACEHOLDERS:
  //   ${CPU}            → Provided via Terraform variables
  //   ${MEMORY}         → Provided via Terraform variables
  //   ${AWS_REGION}     → From provider config
  //
  // No environment variables required.
  // ============================================

  "family": "redis-task",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "${CPU}",
  "memory": "${MEMORY}",

  "containerDefinitions": [
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
}
