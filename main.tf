
# Europe
module "k1" {
  source = "./kafka-service"  
  aiven_project_name = var.project_name
  kafka_service_name = "k1"
  deploy_mm2 = false
  mm2_service_name = ""
  mm2_source_kafka_name = ""
  site_cloud_name = var.a_cloud_name
}

module "k2" {
  source = "./kafka-service"  
  aiven_project_name = var.project_name
  kafka_service_name = "k2"
  deploy_mm2 = true
  mm2_service_name = "mm2-2"
  mm2_source_kafka_name = module.k1.kafka_service_name
  site_cloud_name = var.b_cloud_name
}

# US
module "k3" {
  source = "./kafka-service"  
  aiven_project_name = var.project_name
  kafka_service_name = "k3"
  deploy_mm2 = true
  mm2_service_name = "mm2-3"
  mm2_source_kafka_name = module.k1.kafka_service_name
  site_cloud_name = var.c_cloud_name
}

module "k4" {
  source = "./kafka-service"  
  aiven_project_name = var.project_name
  kafka_service_name = "k4"
  deploy_mm2 = true
  mm2_service_name = "mm2-4"
  mm2_source_kafka_name = module.k3.kafka_service_name
  site_cloud_name = var.d_cloud_name
}