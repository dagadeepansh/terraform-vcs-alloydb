<!-- BEGIN_TF_DOCS -->
Copyright 2023 Google LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | 6.18.0 |
| <a name="provider_google-beta"></a> [google-beta](#provider\_google-beta) | 6.18.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.6.3 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_alloydb_primary"></a> [alloydb\_primary](#module\_alloydb\_primary) | GoogleCloudPlatform/alloy-db/google | ~> 3.0 |

## Resources

| Name | Type |
|------|------|
| [google-beta_google_project_service_identity.alloydb_sa](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_project_service_identity) | resource |
| [google_alloydb_cluster.replica_cluster](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/alloydb_cluster) | resource |
| [google_alloydb_instance.replica_instance](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/alloydb_instance) | resource |
| [google_kms_crypto_key.key_region_primary](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_crypto_key) | resource |
| [google_kms_crypto_key.key_region_replica](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_crypto_key) | resource |
| [google_kms_crypto_key_iam_member.alloydb_sa_iam](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_crypto_key_iam_member) | resource |
| [google_kms_crypto_key_iam_member.alloydb_sa_iam_secondary](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_crypto_key_iam_member) | resource |
| [google_kms_key_ring.keyring_region_primary](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_key_ring) | resource |
| [google_kms_key_ring.keyring_region_replica](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_key_ring) | resource |
| [random_string.key_suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |


This directory contains Terraform configurations for deploying an AlloyDB cluster with a cross-region replica.  The configurations are designed to be modular and reusable.

## Directory Structure:

*   `main.tf`: Main Terraform configuration file.  This file defines the primary AlloyDB cluster.
*   `variables.tf`: Defines variables used in the Terraform configuration.  This allows for easy customization of the deployment.
*   `outputs.tf`: Defines the outputs of the Terraform configuration.  This provides easy access to important information about the deployed resources.
*   `cross_region_replica.tf`: Defines the cross-region replica cluster.
*   `terraform.auto.tfvars`: Example of auto generated tfvars file.
*   `README.md`: This file.


## How to Use:

1.  Configure Variables: Update the variables in `variables.tf` and `terraform.auto.tfvars` to match your environment.  Pay close attention to the following:
    *   `project_id`: Your Google Cloud project ID.
    *   `region_primary`: The region for your primary AlloyDB cluster.
    *   `region_replica`: The region for your replica AlloyDB cluster.
    *   `cluster_id`: A unique ID for your AlloyDB cluster.
    *   `cluster_name`: A user-friendly name for your AlloyDB cluster.
    *   `primary_instance`: Configuration for your primary instance.
    *   `read_pool_instances`: Configuration for your read pool instances (optional).
    *   `replica_instance_id`: The ID for your replica instance.
    *   `psc_enabled`: Whether to enable Private Service Connect.
    *   `psc_attachment_project_number`: The project number for PSC attachment.
    *   `psc_vpc_network`: The name of the VPC network for PSC.

2.  Initialize Terraform: Run `terraform init` to initialize the Terraform providers.

3.  Plan the Deployment: Run `terraform plan` to see what resources will be created or modified.

4.  Apply the Deployment: Run `terraform apply` to deploy the resources.

5.  Destroy the Deployment: Run `terraform destroy` to delete the deployed resources.


## Examples:

    Example 1: Basic Deployment (Single Primary Instance):

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alloydb_sa_iam_role"></a> [alloydb\_sa\_iam\_role](#input\_alloydb\_sa\_iam\_role) | The IAM role to assign to the AlloyDB service account. | `list(string)` | <pre>[<br/>  "roles/cloudkms.cryptoKeyEncrypterDecrypter"<br/>]</pre> | no |
| <a name="input_automated_backup_enabled"></a> [automated\_backup\_enabled](#input\_automated\_backup\_enabled) | Whether automated backup is enabled. | `bool` | `true` | no |
| <a name="input_backup_labels"></a> [backup\_labels](#input\_backup\_labels) | Labels to apply to the backups. | `map(string)` | <pre>{<br/>  "test": "alloydb-cluster-with-prim"<br/>}</pre> | no |
| <a name="input_backup_window"></a> [backup\_window](#input\_backup\_window) | The backup window time (e.g., 1800s). | `string` | `"1800s"` | no |
| <a name="input_cluster_depends_on"></a> [cluster\_depends\_on](#input\_cluster\_depends\_on) | n/a | `any` | `[]` | no |
| <a name="input_cluster_id"></a> [cluster\_id](#input\_cluster\_id) | The ID of the AlloyDB cluster. | `string` | `"primary-central-cluster-id"` | no |
| <a name="input_cluster_id_replica"></a> [cluster\_id\_replica](#input\_cluster\_id\_replica) | The ID of the AlloyDB cluster in the east region. | `string` | `"cluster-replica-psc"` | no |
| <a name="input_cluster_initial_password"></a> [cluster\_initial\_password](#input\_cluster\_initial\_password) | The password for the initial user. | `string` | `"postgres123"` | no |
| <a name="input_cluster_initial_user"></a> [cluster\_initial\_user](#input\_cluster\_initial\_user) | The initial user for the cluster. | `string` | `"postgres"` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of cluster | `string` | `"primary-cluster-psc"` | no |
| <a name="input_continuous_backup_enable"></a> [continuous\_backup\_enable](#input\_continuous\_backup\_enable) | Whether to enable continuous backup for the replica cluster. | `bool` | `true` | no |
| <a name="input_continuous_backup_recovery_window_days"></a> [continuous\_backup\_recovery\_window\_days](#input\_continuous\_backup\_recovery\_window\_days) | The number of days for the continuous backup recovery window. | `number` | `10` | no |
| <a name="input_create_replica_cluster"></a> [create\_replica\_cluster](#input\_create\_replica\_cluster) | Whether to create a cross-region replica cluster. | `bool` | `false` | no |
| <a name="input_key_suffix_length"></a> [key\_suffix\_length](#input\_key\_suffix\_length) | The length of the random suffix for KMS key and key ring names. | `number` | `3` | no |
| <a name="input_key_suffix_special"></a> [key\_suffix\_special](#input\_key\_suffix\_special) | Whether to include special characters in the random suffix. | `bool` | `false` | no |
| <a name="input_key_suffix_upper"></a> [key\_suffix\_upper](#input\_key\_suffix\_upper) | Whether to include uppercase characters in the random suffix. | `bool` | `false` | no |
| <a name="input_primary_instance"></a> [primary\_instance](#input\_primary\_instance) | n/a | <pre>object({<br/>    instance_id        = string<br/>    display_name       = string<br/>    database_flags     = map(string)<br/>    labels             = map(string)<br/>    annotations        = map(string)<br/>    gce_zone           = string<br/>    availability_type  = string<br/>    machine_cpu_count  = number<br/>    ssl_mode           = string<br/>    require_connectors = bool<br/>    query_insights_config = object({<br/>      query_string_length     = number<br/>      record_application_tags = bool<br/>      record_client_address   = bool<br/>      query_plans_per_minute  = number<br/>    })<br/>    enable_public_ip = bool<br/>    cidr_range       = list(string)<br/>  })</pre> | <pre>{<br/>  "annotations": {},<br/>  "availability_type": "ZONAL",<br/>  "cidr_range": [],<br/>  "database_flags": {},<br/>  "display_name": "Default Instance",<br/>  "enable_public_ip": false,<br/>  "gce_zone": null,<br/>  "instance_id": "default-instance-id",<br/>  "labels": {},<br/>  "machine_cpu_count": 2,<br/>  "query_insights_config": {<br/>    "query_plans_per_minute": 5,<br/>    "query_string_length": 1024,<br/>    "record_application_tags": false,<br/>    "record_client_address": false<br/>  },<br/>  "require_connectors": false,<br/>  "ssl_mode": "ENCRYPTED_ONLY"<br/>}</pre> | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The ID of the project in which to provision resources. | `string` | `"cloudlake-dev-1"` | no |
| <a name="input_psc_attachment_project_id"></a> [psc\_attachment\_project\_id](#input\_psc\_attachment\_project\_id) | The ID of the project in which attachment will be provisioned | `string` | `"terraform-cloudbuild"` | no |
| <a name="input_psc_attachment_project_number"></a> [psc\_attachment\_project\_number](#input\_psc\_attachment\_project\_number) | The project number in which attachment will be provisioned | `string` | `"805128748265"` | no |
| <a name="input_psc_enabled"></a> [psc\_enabled](#input\_psc\_enabled) | Whether to enable PSC for the cluster. | `bool` | `true` | no |
| <a name="input_psc_vpc_network"></a> [psc\_vpc\_network](#input\_psc\_vpc\_network) | The name of the VPC network for PSC. | `string` | `"psc-vpc"` | no |
| <a name="input_quantity_based_retention_count"></a> [quantity\_based\_retention\_count](#input\_quantity\_based\_retention\_count) | The number of backups to retain based on quantity. | `number` | `1` | no |
| <a name="input_read_pool_instances"></a> [read\_pool\_instances](#input\_read\_pool\_instances) | Read pool instance configurations. | <pre>list(object({<br/>    instance_id        = string<br/>    display_name       = string<br/>    node_count         = number<br/>    database_flags     = map(string)<br/>    availability_type  = string<br/>    gce_zone           = string // Corrected typo: tring -> string<br/>    machine_cpu_count  = number<br/>    ssl_mode           = string<br/>    require_connectors = bool<br/>    query_insights_config = object({<br/>      query_string_length     = number<br/>      record_application_tags = bool<br/>      record_client_address   = bool<br/>      query_plans_per_minute  = number<br/>    })<br/>    enable_public_ip = bool<br/>    cidr_range       = list(string)<br/>  }))</pre> | `[]` | no |
| <a name="input_region_primary"></a> [region\_primary](#input\_region\_primary) | The region for cluster in central us | `string` | `"us-central1"` | no |
| <a name="input_region_replica"></a> [region\_replica](#input\_region\_replica) | The region for cluster in east us | `string` | `"us-east1"` | no |
| <a name="input_replica_gce_zone"></a> [replica\_gce\_zone](#input\_replica\_gce\_zone) | The zone to place the replica instance. | `string` | `""` | no |
| <a name="input_replica_instance"></a> [replica\_instance](#input\_replica\_instance) | Replica primary instance configuration. | <pre>object({<br/>    require_connectors = bool<br/>    ssl_mode           = string<br/>    machine_cpu_count  = number<br/>  })</pre> | <pre>{<br/>  "machine_cpu_count": 2,<br/>  "require_connectors": false,<br/>  "ssl_mode": "ENCRYPTED_ONLY"<br/>}</pre> | no |
| <a name="input_replica_instance_id"></a> [replica\_instance\_id](#input\_replica\_instance\_id) | The ID of the primary instance for the cross-region replica cluster. | `string` | `"cluster-replica-east-instance1-psc"` | no |
| <a name="input_time_based_retention_count"></a> [time\_based\_retention\_count](#input\_time\_based\_retention\_count) | The number of backups to retain based on time. | `number` | `null` | no |
| <a name="input_weekly_schedule"></a> [weekly\_schedule](#input\_weekly\_schedule) | The weekly schedule for backups. | <pre>object({<br/>    days_of_week = list(string)<br/>    start_times  = list(string)<br/>  })</pre> | <pre>{<br/>  "days_of_week": [<br/>    "Friday"<br/>  ],<br/>  "start_times": [<br/>    "03:00:00:000"<br/>  ]<br/>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_id_primary"></a> [cluster\_id\_primary](#output\_cluster\_id\_primary) | ID of the Alloy DB Cluster created |
| <a name="output_cluster_id_replica"></a> [cluster\_id\_replica](#output\_cluster\_id\_replica) | The ID of the replica AlloyDB cluster (if created). |
| <a name="output_cluster_name_primary"></a> [cluster\_name\_primary](#output\_cluster\_name\_primary) | The name of the cluster resource |
| <a name="output_cluster_primary"></a> [cluster\_primary](#output\_cluster\_primary) | cluster |
| <a name="output_kms_key_name_primary"></a> [kms\_key\_name\_primary](#output\_kms\_key\_name\_primary) | he fully-qualified resource name of the KMS key |
| <a name="output_kms_key_name_replica"></a> [kms\_key\_name\_replica](#output\_kms\_key\_name\_replica) | he fully-qualified resource name of the Secondary clusterKMS key |
| <a name="output_primary_instance_id_primary"></a> [primary\_instance\_id\_primary](#output\_primary\_instance\_id\_primary) | ID of the primary instance created |
| <a name="output_primary_instance_primary"></a> [primary\_instance\_primary](#output\_primary\_instance\_primary) | primary instance created |
| <a name="output_primary_psc_attachment_link_primary"></a> [primary\_psc\_attachment\_link\_primary](#output\_primary\_psc\_attachment\_link\_primary) | The private service connect (psc) attachment created for primary instance |
| <a name="output_project_id"></a> [project\_id](#output\_project\_id) | Project ID of the Alloy DB Cluster created |
| <a name="output_psc_dns_name_primary"></a> [psc\_dns\_name\_primary](#output\_psc\_dns\_name\_primary) | he DNS name of the instance for PSC connectivity. Name convention: ...alloydb-psc.goog |
| <a name="output_read_instance_ids_primary"></a> [read\_instance\_ids\_primary](#output\_read\_instance\_ids\_primary) | IDs of the read instances created |
| <a name="output_read_psc_attachment_links_primary"></a> [read\_psc\_attachment\_links\_primary](#output\_read\_psc\_attachment\_links\_primary) | n/a |
| <a name="output_region_primary"></a> [region\_primary](#output\_region\_primary) | The region for primary cluster |
| <a name="output_region_replica"></a> [region\_replica](#output\_region\_replica) | The region for cross region replica secondary cluster |
<!-- END_TF_DOCS -->
