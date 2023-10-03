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

# create service accounts and workloads identity
locals {
  _role_sa = toset(flatten([
    for p, r in var.profile_roles : [
      for role in r : {
        role = role
        sa   = p
      }
    ]
  ]))

  role_sa_map = {
    for r in local._role_sa : "${r.role}:${r.sa}" => r
  }

  # helm charts uses 15 letter short name and the first 7 characters
  # of the sha256 hash of the organization name to build k8s service 
  # account names.

  apigee_org     = var.project_id
  org_hash       = substr(sha256(local.apigee_org), 0, 7)
  org_short_name = substr(local.apigee_org, 0, 15)
  gen_name       = format("%s-%s", local.org_short_name, local.org_hash)

  ksa_gsa_map = {
    "apigee-logger" : "apigee-logger"
    "apigee-watcher" : "apigee-watcher"
    "apigee-udca" : "apigee-udca"
    "apigee-connect-agent" : "apigee-mart"
    "apigee-mart" : "apigee-mart"
    "apigee-metrics" : "apigee-metrics"
  }

  env_hash = { for k, v in var.apigee_environments : k => format("%s-%s", substr(k, 0, 15), substr(sha256(format("%s:%s", local.apigee_org, k)), 0, 7)) }

  # in order to avoid recreating service accounts, we will read the service
  # accounts with data apigee_sa_precheck, then loop through the list of 
  # profiles to build a new profile list which only conains the SAs to be 
  # created. After that we will use another data source to read all SAs
  profiles = toset(flatten([
    for p in var.profiles : [
      data.google_service_account.apigee_sa_precheck[p] != null ? [] : [p]
    ]
  ]))

}

# pull SA data before creating new ones
data "google_service_account" "apigee_sa_precheck" {
  for_each = var.profiles

  project    = var.project_id
  account_id = each.value
}

# pull all SAs data after ceation
data "google_service_account" "apigee_sa" {
  for_each = var.profiles

  project    = var.project_id
  account_id = each.value

  depends_on = [
    local.profiles,
    google_service_account.apigee_sa
  ]
}

# create GCP service accounts for the ones do not exist 

resource "google_service_account" "apigee_sa" {
  for_each = local.profiles

  account_id   = each.value
  display_name = "${each.value}-apigee-sa"
  project      = var.project_id
}

# create GCP service accounts role bindings

resource "google_project_iam_member" "apigee_sa" {
  for_each = local.role_sa_map
  project  = var.project_id
  role     = each.value.role
  member   = "serviceAccount:${data.google_service_account.apigee_sa[each.value.sa].email}"
}


# bind KSA to GSA at org level

resource "google_service_account_iam_binding" "sa_binding" {
  for_each           = local.ksa_gsa_map
  service_account_id = data.google_service_account.apigee_sa[each.value].name
  role               = "roles/iam.workloadIdentityUser"
  members            = ["serviceAccount:${var.project_id}.svc.id.goog[apigee/-${each.key}-${local.gen_name}-sa]"]
  depends_on = [
    google_project_iam_member.apigee_sa
  ]
}

# bind KSA to GSA at env level

resource "google_service_account_iam_binding" "env_runtime_sa_binding" {
  for_each           = local.env_hash
  service_account_id = data.google_service_account.apigee_sa["apigee-runtime"].name
  role               = "roles/iam.workloadIdentityUser"
  members            = ["serviceAccount:${var.project_id}.svc.id.goog[apigee/apigee-runtime-${local.gen_name}-${each.value}-sa]"]
  depends_on = [
    google_project_iam_member.apigee_sa
  ]
}

resource "google_service_account_iam_binding" "env_synchronizer_sa_binding" {
  for_each           = local.env_hash
  service_account_id = data.google_service_account.apigee_sa["apigee-synchronizer"].name
  role               = "roles/iam.workloadIdentityUser"
  members            = ["serviceAccount:${var.project_id}.svc.id.goog[apigee/apigee-synchronizer-${local.gen_name}-${each.value}-sa]"]
  depends_on = [
    google_project_iam_member.apigee_sa
  ]
}

resource "google_service_account_iam_binding" "env_udca_sa_binding" {
  for_each           = local.env_hash
  service_account_id = data.google_service_account.apigee_sa["apigee-udca"].name
  role               = "roles/iam.workloadIdentityUser"
  members            = ["serviceAccount:${var.project_id}.svc.id.goog[apigee/apigee-udca-${local.gen_name}-${each.value}-sa]"]
  depends_on = [
    google_project_iam_member.apigee_sa
  ]
}