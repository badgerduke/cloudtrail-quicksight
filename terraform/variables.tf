variable "custom_trail_name" {
 type = string
 description = "The name of the custom Cloudtrail trail"
}

variable "custom_trail_s3_prefix" {
 type = string
 description = "The S3 prefix in the bucket storing CloudTrail logs"
}

variable "custom_trail_S3_name" {
 type = string
 description = "The name of the S3 bucket storing the custom trail logs"
}

variable "cloudtrail_event_name" {
 type = string
 description = "The cloudtrail event name to search for"
}

variable "security_group_name" {
 type = string
 description = "The name of the security group"
}

variable "athena_workgroup_name" {
 type = string
 description = "The name of the Athena workgroup"
}

variable "athena_results_bucket" {
 type = string
 description = "The name of the S3 bucket to store the results of the Athena query"
}

variable "athena_database_name" {
 type = string
 description = "The name of the Athena database"
}

variable "athena_table_name" {
 type = string
 description = "The name of the Athena table"
}

variable "quicksight_username" {
 type = string
 description = "The Quicksight user name"
}

variable "quicksight_username_path" {
 type = string
 description = "The JSON path within useridentity for username"
}