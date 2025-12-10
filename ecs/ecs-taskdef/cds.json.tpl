{
  // ==========================================================
  // CDS APPLICATION TASK — Fargate
  //
  // FROM DOCKER COMPOSE:
  //   - image: cds:latest
  //   - ports: 8080:8080
  //   - JAVA_OPTS
  //   - APP_ARGS (multi-line arguments → Terraform converts to single-line)
  //
  // PLACEHOLDERS:
  //   ${CPU}               → module input
  //   ${MEMORY}            → module input
  //   ${AWS_REGION}        → provider region
  //
  //   ${CDS_JAVA_OPTS}     → provided via tfvars (copied from docker compose)
  //   ${CDS_APP_ARGS}      → **multi-line input** with placeholders:
  //
  //       --spring.kafka.consumer.bootstrap-servers=${KAFKA_IP}:9092
  //       --spring.datasource.url=jdbc:postgresql://${RDS_ENDPOINT}:5432/cds_db
  //       --spring.data.redis.url=redis://${REDIS_IP}:6379
  //
  //   These are replaced by ECS module dynamically.
  //
  // ==========================================================

  "family": "cds-task",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "${CPU}",
  "memory": "${MEMORY}",

  "containerDefinitions": [
    {
      "name": "cds",
      "image": "${CDS_IMAGE}",
      "essential": true,

      "portMappings": [
        { "containerPort": 8080, "protocol": "tcp" }
      ],

      "environment": [
        {
          "name": "JAVA_OPTS",
          "value": "${CDS_JAVA_OPTS}"
        },
        {
          // APP_ARGS becomes **single line** when rendered by Terraform
          "name": "APP_ARGS",
          "value": "${CDS_APP_ARGS}"
        }
      ],

      "healthCheck": {
        "command": [
          "CMD-SHELL",
          "nc -z localhost 8080 || exit 1"
        ],
        "interval": 30,
        "timeout": 10,
        "retries": 3,
        "startPeriod": 40
      },

      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-region": "${AWS_REGION}",
          "awslogs-group": "/ecs/cds",
          "awslogs-stream-prefix": "cds"
        }
      }
    }
  ]
}
