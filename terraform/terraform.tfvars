# The name of the custom Cloudtrail trail
custom_trail_name = "demo-trail"

# The S3 prefix in the bucket storing CloudTrail logs
custom_trail_s3_prefix = "demo-trail"

# The name of the S3 bucket storing the custom trail logs
custom_trail_S3_name = "cloudtrail-eventbridge-example"

# The metric filter pattern 
cloudtrail_event_name = "ModifySecurityGroupRules"

# The name of the security group
security_group_name = "demo-sg"

# The name of the Athena workgroup
athena_workgroup_name = "demo_athena_workgroup"

# The name of the S3 bucket to store the results of the Athena query
athena_results_bucket = "demo-hamacher-athena-results"

# The name of the Athena database
athena_database_name = "demo_athena_database"

# The name of the Athena table
athena_table_name = "demo_athena_table"

# The Quicksight user name
quicksight_username = ""

# The JSON path within useridentity field for username (this will vary for different event names)
quicksight_username_path = "$.username"