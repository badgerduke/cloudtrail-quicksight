data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_region" "current" {}

data "aws_quicksight_user" "demo" {
  user_name = "${var.quicksight_username}"
}