{
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
          "name": "APP_ARGS",
          "value": "${CDS_APP_ARGS}"
        },
        {
          "name": "SPRING_KAFKA_BOOTSTRAP",
          "value": "${KAFKA_IP}:9092"
        },
        {
          "name": "SPRING_DATASOURCE_URL",
          "value": "jdbc:postgresql://${RDS_ENDPOINT}:5432/cds_db"
        },
        {
          "name": "SPRING_REDIS_URL",
          "value": "redis://${REDIS_IP}:6379"
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
