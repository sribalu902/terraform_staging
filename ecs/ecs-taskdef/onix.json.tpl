{
  // ==========================================================
  // ONIX PLUGIN — Fargate
  //
  // FROM DOCKER COMPOSE:
  //   image: onix:latest
  //   ports: 8002:8002
  //   volumes: config + schemas
  //   environment: CONFIG_FILE (points to a YAML config inside container)
  //
  // PLACEHOLDERS:
  //   ${CPU}             → module input
  //   ${MEMORY}          → module input
  //   ${AWS_REGION}      → provider region
  //   ${ONIX_CONFIG_FILE} → provided by user (path inside container)
  //
  // NOTES:
  //   - Fargate does NOT allow bind mounts → config must be:
  //       A) baked into Docker image, or
  //       B) stored in S3 and downloaded at startup, or
  //       C) stored in EFS (optional)
  // ==========================================================

  "family": "onix-task",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "${CPU}",
  "memory": "${MEMORY}",

  "containerDefinitions": [
    {
      "name": "onix",
      "image": "${ONIX_IMAGE}",
      "essential": true,

      "portMappings": [
        { "containerPort": 8002, "protocol": "tcp" }
      ],

      "environment": [
        {
          "name": "CONFIG_FILE",
          "value": "${ONIX_CONFIG_FILE}"
        }
      ],

      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-region": "${AWS_REGION}",
          "awslogs-group": "/ecs/onix",
          "awslogs-stream-prefix": "onix"
        }
      }
    }
  ]
}
