/**
 * Copyright 2021 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

output "project_id" {
  description = "Project ID of the Alloy DB Cluster created"
  value       = var.project_id
}

output "cluster_primary" {
  description = "cluster"
  value       = module.alloydb_primary.cluster
  sensitive   = true // Add this line
}

output "primary_instance_primary" {
  description = "primary instance created"
  value       = module.alloydb_primary.primary_instance
}

output "cluster_id_primary" {
  description = "ID of the Alloy DB Cluster created"
  value       = module.alloydb_primary.cluster_id
}

output "primary_instance_id_primary" {
  description = "ID of the primary instance created"
  value       = module.alloydb_primary.primary_instance_id
}

output "read_instance_ids_primary" {
  description = "IDs of the read instances created"
  value       = module.alloydb_primary.read_instance_ids
}

output "cluster_name_primary" {
  description = "The name of the cluster resource"
  value       = module.alloydb_primary.cluster_name
}

output "primary_psc_attachment_link_primary" {
  description = "The private service connect (psc) attachment created for primary instance"
  value       = module.alloydb_primary.primary_psc_attachment_link
}

output "psc_dns_name_primary" {
  description = "he DNS name of the instance for PSC connectivity. Name convention: ...alloydb-psc.goog"
  value       = module.alloydb_primary.primary_instance.psc_instance_config[0].psc_dns_name
}

output "read_psc_attachment_links_primary" {
  value = module.alloydb_primary.read_psc_attachment_links
}

# output "cluster_replica" {
#   description = "cluster created"
#   value       = module.alloydb_replica.cluster
# }

output "cluster_id_replica" {
  value       = var.create_replica_cluster ? google_alloydb_cluster.replica_cluster[0].cluster_id : null
  description = "The ID of the replica AlloyDB cluster (if created)."
  sensitive   = false # Consider if this needs to be sensitive
}

output "kms_key_name_primary" {
  description = "he fully-qualified resource name of the KMS key"
  value       = google_kms_crypto_key.key_region_primary.id
}

output "kms_key_name_replica" {
  description = "he fully-qualified resource name of the Secondary clusterKMS key"
  value       = google_kms_crypto_key.key_region_replica.id
}

output "region_primary" {
  description = "The region for primary cluster"
  value       = var.region_primary
}

output "region_replica" {
  description = "The region for cross region replica secondary cluster"
  value       = var.region_replica
}