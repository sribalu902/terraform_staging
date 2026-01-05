[
  {
    "name": "kafka",
    "image": "confluentinc/cp-kafka:7.5.0",
    "essential": true,

    "portMappings": [
      { "containerPort": 9092, "hostPort": 9092 },
      { "containerPort": 9093, "hostPort": 9093 }
    ],

    "mountPoints": [
      {
        "containerPath": "/var/lib/kafka/data",
        "sourceVolume": "kafka-data",
        "readOnly": false
      }
    ],

    "entryPoint": ["/bin/bash", "-c"],

    "command": [
      "IP=$(curl -s $ECS_CONTAINER_METADATA_URI_V4 | jq -r '.Networks[0].IPv4Addresses[0]'); echo Kafka IP=$IP; export KAFKA_PROCESS_ROLES=broker,controller; export KAFKA_NODE_ID=1; export KAFKA_CONTROLLER_QUORUM_VOTERS=1@$IP:9093; export KAFKA_LISTENERS=PLAINTEXT://0.0.0.0:9092,CONTROLLER://0.0.0.0:9093; export KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://$IP:9092; export KAFKA_INTER_BROKER_LISTENER_NAME=PLAINTEXT; export KAFKA_CONTROLLER_LISTENER_NAMES=CONTROLLER; export KAFKA_LISTENER_SECURITY_PROTOCOL_MAP=PLAINTEXT:PLAINTEXT,CONTROLLER:PLAINTEXT; export KAFKA_AUTO_CREATE_TOPICS_ENABLE=true; export KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR=1; export KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR=1; export KAFKA_TRANSACTION_STATE_LOG_MIN_ISR=1; export KAFKA_LOG_DIRS=/var/lib/kafka/data; export CLUSTER_ID=MkU3OEVBNTcwNTJENDM2Qk; /etc/confluent/docker/run"
    ],

    "healthCheck": {
      "command": [
        "CMD-SHELL",
        "kafka-broker-api-versions --bootstrap-server localhost:9092 || exit 1"
      ],
      "interval": 10,
      "timeout": 5,
      "retries": 5
    },

    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-region": "${AWS_REGION}",
        "awslogs-group": "/ecs/kafka",
        "awslogs-stream-prefix": "kafka"
      }
    }
  }
]
