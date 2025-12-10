{
  // ==========================================================
  // KAFKA TASK — EC2 HOST MODE ONLY
  //
  // IMPORTANT:
  // Kafka CANNOT run on Fargate because:
  //   - It requires host networking
  //   - Needs stable ports 9092 / 9093
  //   - Needs persistent /var/lib/kafka/data
  //
  // This template replicates your Docker Compose setup:
  //
  //   - "PLAINTEXT://kafka-bpp:9092" → replaced by EC2 private IP
  //   - Controller quorum voters use $IP:9093
  //
  // PLACEHOLDERS:
  //   ${CPU}         → CPU units, provided by Terraform module
  //   ${MEMORY}      → Memory units, provided by Terraform module
  //   ${AWS_REGION}  → AWS provider region
  //
  // AUTO-WIRED VALUES:
  //   - Private IP is obtained dynamically using ECS metadata:
  //
  //       IP=$(curl -s $ECS_CONTAINER_METADATA_URI_V4 | jq -r '.Networks[0].IPv4Addresses[0]')
  //
  //   - Advertised listeners:
  //
  //       PLAINTEXT://$IP:9092
  //
  //   - Controller Quorum (KRaft):
  //
  //       1@$IP:9093
  //
  //   This ensures ANY ECS service (CDS, Onix, Redis, Kafka-UI) can reach Kafka.
  //
  // ==========================================================

  "family": "kafka-task",
  "networkMode": "host",              // REQUIRED for Kafka
  "requiresCompatibilities": ["EC2"], // Fargate does NOT support host mode
  "cpu": "${CPU}",
  "memory": "${MEMORY}",

  "containerDefinitions": [
    {
      "name": "kafka",
      "image": "confluentinc/cp-kafka:7.5.0",
      "essential": true,

      // ----------------------------------------------------------
      // PORT MAPPINGS
      // Host = Container because of host networking mode:
      //
      //   9092 → Kafka Broker (external client access)
      //   9093 → Kafka Controller (KRaft)
      // ----------------------------------------------------------
      "portMappings": [
        { "containerPort": 9092, "hostPort": 9092 },
        { "containerPort": 9093, "hostPort": 9093 }
      ],

      // ----------------------------------------------------------
      // PERSISTENT STORAGE
      // Kafka requires disk persistence under /var/lib/kafka/data
      // This is mounted from the EC2 instance (host)
      // ----------------------------------------------------------
      "mountPoints": [
        {
          "containerPath": "/var/lib/kafka/data",
          "sourceVolume": "kafka-data",
          "readOnly": false
        }
      ],

      // ----------------------------------------------------------
      // ENTRYPOINT OVERRIDE WITH METADATA IP DISCOVERY
      //
      // ECS provides ENI metadata (private IP):
      //   $ECS_CONTAINER_METADATA_URI_V4
      //
      // jq extracts:
      //   .Networks[0].IPv4Addresses[0] → Example: 10.0.3.25
      //
      // Then we export Kafka runtime variables dynamically.
      //
      // THIS IS MANDATORY FOR SINGLE-NODE KRAFT MODE
      // ----------------------------------------------------------
      "entryPoint": ["/bin/bash", "-c"],

      "command": [
        "IP=$(curl -s $ECS_CONTAINER_METADATA_URI_V4 | jq -r '.Networks[0].IPv4Addresses[0]'); \
         echo \"Kafka detected private IP: $IP\"; \
         \
         export KAFKA_PROCESS_ROLES=broker,controller; \
         export KAFKA_NODE_ID=1; \
         export KAFKA_CONTROLLER_QUORUM_VOTERS=\"1@$IP:9093\"; \
         \
         export KAFKA_LISTENERS=\"PLAINTEXT://0.0.0.0:9092,CONTROLLER://0.0.0.0:9093\"; \
         export KAFKA_ADVERTISED_LISTENERS=\"PLAINTEXT://$IP:9092\"; \
         \
         export KAFKA_INTER_BROKER_LISTENER_NAME=PLAINTEXT; \
         export KAFKA_CONTROLLER_LISTENER_NAMES=CONTROLLER; \
         export KAFKA_LISTENER_SECURITY_PROTOCOL_MAP=\"PLAINTEXT:PLAINTEXT,CONTROLLER:PLAINTEXT\"; \
         \
         export KAFKA_AUTO_CREATE_TOPICS_ENABLE=true; \
         export KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR=1; \
         export KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR=1; \
         export KAFKA_TRANSACTION_STATE_LOG_MIN_ISR=1; \
         \
         export KAFKA_LOG_DIRS=/var/lib/kafka/data; \
         export CLUSTER_ID=\"MkU3OEVBNTcwNTJENDM2Qk\"; \
         \
         # Start Confluent Kafka runner
         /etc/confluent/docker/run"
      ],

      // ----------------------------------------------------------
      // HEALTH CHECK
      // Matches Docker Compose equivalent
      // ----------------------------------------------------------
      "healthCheck": {
        "command": [
          "CMD-SHELL",
          "kafka-broker-api-versions --bootstrap-server localhost:9092 || exit 1"
        ],
        "interval": 10,
        "timeout": 5,
        "retries": 5
      },

      // ----------------------------------------------------------
      // LOGGING (CloudWatch)
      // ----------------------------------------------------------
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-region": "${AWS_REGION}",
          "awslogs-group": "/ecs/kafka",
          "awslogs-stream-prefix": "kafka"
        }
      }
    }
  ],

  // --------------------------------------------------------------
  // Host volume for Kafka persistence
  // --------------------------------------------------------------
  "volumes": [
    {
      "name": "kafka-data",
      "host": {
        "sourcePath": "/var/lib/kafka/data"
      }
    }
  ]
}
