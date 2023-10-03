/**
 * Copyright 2023 Google LLC
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


# TF service account
variable "tf_service_account" {
  description = "Terraform Service Account"
  type        = string
}

# Project ID
variable "project_id" {
  description = "Project id (also used for the Apigee Organization)."
  type        = string
}

# region
variable "region" {
  description = "Region."
  type        = string
  default     = "us-central1"
}

# Analytics region
variable "ax_region" {
  description = "GCP region for storing Apigee analytics data (see https://cloud.google.com/apigee/docs/api-platform/get-started/install-cli)."
  type        = string
  default     = "us-central1"
}

# Apigee Environment and Environment Groups
variable "apigee_envgroups" {
  description = "Apigee Environment Groups."
  type = map(object({
    hostnames = list(string)
  }))
  default = {}
}

variable "apigee_environments" {
  description = "Apigee Environments."
  type = map(object({
    display_name = optional(string)
    description  = optional(string)
    iam          = optional(map(list(string)))
    envgroups    = list(string)
  }))
  default = null
}

# required if a new project is created
variable "billing_account" {
  description = "Billing account id."
  type        = string
  default     = null
}

# required if a new project is created
variable "project_parent" {
  description = "Parent folder or organization in 'folders/folder_id' or 'organizations/org_id' format."
  type        = string
  default     = null
  validation {
    condition     = var.project_parent == null || can(regex("(organizations|folders)/[0-9]+", var.project_parent))
    error_message = "Parent must be of the form folders/folder_id or organizations/organization_id."
  }
}

# by default we expect a project already exists
variable "project_create" {
  description = "Create project. When set to false, uses a data source to reference existing project."
  type        = bool
  default     = false
}

# Service Accounts
variable "profiles" {
  description = "supported profiles"
  type        = set(string)
  default = [
    "apigee-logger",
    "apigee-metrics",
    "apigee-cassandra",
    "apigee-udca",
    "apigee-synchronizer",
    "apigee-mart",
    "apigee-watcher",
    "apigee-runtime",
  ]
}

variable "profile_roles" {
  description = "Roles to be assigned to the service accounts"
  type        = map(list(string))
  default = {
    "apigee-logger" = [
      "roles/logging.logWriter",
    ],
    "apigee-metrics" = [
      "roles/monitoring.metricWriter",
    ],
    "apigee-cassandra" = [
      "roles/storage.objectAdmin",
    ],
    "apigee-udca" = [
      "roles/apigee.analyticsAgent",
    ],
    "apigee-synchronizer" = [
      "roles/apigee.synchronizerManager",
    ]
    "apigee-mart" = [
      "roles/apigeeconnect.Agent",
    ]
    "apigee-watcher" = [
      "roles/apigee.runtimeAgent"
    ],
    "apigee-runtime" = [
    ]
  }
}

variable "supported_env" {
  description = "Supported environments"
  type        = list(string)
  default = [
    "prod",
    "staging",
    "dev",
  ]
}

variable "gsa-ksa-mapping" {
  description = "GCP SA to K8S SA Mapping"
  type        = map(string)
  default = {
    "apigee-logger"        = "apigee-logger"
    "apigee-metrics"       = "apigee-metrics"
    "apigee-cassandra"     = "apigee-cassandra"
    "apigee-udca"          = "apigee-udca"
    "apigee-synchronizer"  = "apigee-synchronizer"
    "apigee-mart"          = "apigee-mart"
    "apigee-watcher"       = "apigee-watcher"
    "apigee-connect-agent" = "apigee-mart"
  }
}
