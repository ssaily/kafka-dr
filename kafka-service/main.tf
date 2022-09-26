# Kafka service
resource "aiven_kafka" "dr-demo-kafka" {
    project         = var.aiven_project_name
    service_name    = var.kafka_service_name
    cloud_name      = var.site_cloud_name
    plan = "startup-2"
    maintenance_window_dow = "monday"
    maintenance_window_time = "10:00:00"
    default_acl = false

    kafka_user_config {
        // Enables Kafka Schemas
        schema_registry = true    
        kafka {
            group_max_session_timeout_ms = 70000
            log_retention_bytes = 1000000000
        }
    }
}

resource "aiven_kafka_topic" "mytopic" {
    project         = var.aiven_project_name
    service_name    = aiven_kafka.dr-demo-kafka.service_name
    topic_name      = "mytopic"
    partitions      = 20
    replication     = 3
    config {
        retention_ms = 259200000
        cleanup_policy = "delete"
        min_insync_replicas = 1
    }  

}

resource "aiven_kafka_mirrormaker" "dr-demo-mm2" {
    count           = var.deploy_mm2 ? 1 : 0
    project         = var.aiven_project_name
    service_name    = var.mm2_service_name
    cloud_name      = var.site_cloud_name
    plan = "startup-4"
    kafka_mirrormaker_user_config {
        ip_filter = ["0.0.0.0/0"]

        kafka_mirrormaker {
            refresh_groups_enabled          = true
            refresh_groups_interval_seconds = 5
            refresh_topics_enabled          = true
            refresh_topics_interval_seconds = 5
            emit_checkpoints_enabled        = true
            emit_checkpoints_interval_seconds = 5            
        }
  }
}

resource "aiven_service_integration" "i1" {
    count           = var.deploy_mm2 ? 1 : 0
    project                  = var.aiven_project_name
    integration_type         = "kafka_mirrormaker"
    source_service_name      = var.mm2_source_kafka_name
    destination_service_name = aiven_kafka_mirrormaker.dr-demo-mm2[0].service_name

    kafka_mirrormaker_user_config {
        cluster_alias = var.mm2_source_kafka_name
    }
}

resource "aiven_service_integration" "i2" {
    count           = var.deploy_mm2 ? 1 : 0
    project                  = var.aiven_project_name
    integration_type         = "kafka_mirrormaker"
    source_service_name      = aiven_kafka.dr-demo-kafka.service_name
    destination_service_name = aiven_kafka_mirrormaker.dr-demo-mm2[0].service_name

    kafka_mirrormaker_user_config {
        cluster_alias = aiven_kafka.dr-demo-kafka.service_name
    }
}

# ingress flow from source
resource "aiven_mirrormaker_replication_flow" "f1" {
    count           = var.deploy_mm2 ? 1 : 0
    project        = var.aiven_project_name
    service_name   = aiven_kafka_mirrormaker.dr-demo-mm2[0].service_name
    source_cluster = var.mm2_source_kafka_name
    target_cluster = aiven_kafka.dr-demo-kafka.service_name
    enable         = true
    sync_group_offsets_enabled      = true
    sync_group_offsets_interval_seconds = 1

    topics = [
    ".*mytopic",
    ]

}

resource "aiven_mirrormaker_replication_flow" "f2" {
    count           = var.deploy_mm2 ? 1 : 0
    project        = var.aiven_project_name
    service_name   = aiven_kafka_mirrormaker.dr-demo-mm2[0].service_name
    source_cluster = aiven_kafka.dr-demo-kafka.service_name
    target_cluster = var.mm2_source_kafka_name
    enable         = true
    sync_group_offsets_enabled      = true
    sync_group_offsets_interval_seconds = 1

    topics = [
    ".*mytopic",
    ]

}

output "kafka_service_name" {
    value = aiven_kafka.dr-demo-kafka.service_name
}