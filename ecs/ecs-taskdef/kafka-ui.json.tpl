{
  // ==========================================================
  // KAFKA UI TASK — Fargate
  //
  // Matches Docker Compose:
  //   - image: provectuslabs/kafka-ui:latest
  //   - containerPort: 8080
  //
  // PLACEHOLDERS:
  //   ${CPU}             → from module input
  //   ${MEMORY}          → from module input
  //   ${AWS_REGION}      → provider region
  //   ${KAFKA_IP}        → auto-injected by module (Kafka EC2 private IP)
  //
  // NOTES:
  //   - Kafka UI is PUBLIC or INTERNAL based on module config.
  //   - ECS service will attach to ALB if enabled.
  // ==========================================================

  "family": "kafka-ui-task",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "${CPU}",
  "memory": "${MEMORY}",

  "containerDefinitions": [
    {
      "name": "kafka-ui",
      "image": "provectuslabs/kafka-ui:latest",
      "essential": true,

      "portMappings": [
        { "containerPort": 8080, "protocol": "tcp" }
      ],

      "environment": [
        {
          // Kafka cluster name shown in UI
          "name": "KAFKA_CLUSTERS_0_NAME",
          "value": "bpp"
        },
        {
          // ECS module injects ${KAFKA_IP} at runtime
          "name": "KAFKA_CLUSTERS_0_BOOTSTRAPSERVERS",
          "value": "${KAFKA_IP}:9092"
        }
      ],

      "dependsOn": [
        {
          "containerName": "kafka-ui",
          "condition": "START"
        }
      ],

      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-region": "${AWS_REGION}",
          "awslogs-group": "/ecs/kafka-ui",
          "awslogs-stream-prefix": "kafka-ui"
        }
      }
    }
  ]
}
