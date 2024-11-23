resource "aws_athena_workgroup" "example" {
  name          = "${var.athena_workgroup_name}"
  force_destroy = true

  configuration {
    enforce_workgroup_configuration = true

    result_configuration {
      encryption_configuration {
        encryption_option = "SSE_S3"
      }
      output_location = "s3://${aws_s3_bucket.athena_results_bucket.bucket}/"
    }
  }
}

resource "aws_s3_bucket" "athena_results_bucket" {
  bucket        = "${var.athena_results_bucket}"
  force_destroy = true
}


resource "aws_athena_database" "athena_database" {
  name   = "${var.athena_database_name}"
  bucket = aws_s3_bucket.athena_results_bucket.bucket
}

resource "aws_glue_catalog_table" "cloudtrail" {
  name          = "${var.athena_table_name}"
  database_name = aws_athena_database.athena_database.name
  table_type    = "EXTERNAL_TABLE"

  parameters = {
    "EXTERNAL"            = "TRUE"
    "parquet.compression" = "SNAPPY"
  }
  
  storage_descriptor {
    bucket_columns            = []
    compressed                = false
    input_format              = "com.amazon.emr.cloudtrail.CloudTrailInputFormat"
    location                  = "s3://${aws_s3_bucket.cloudtrail_bucket.bucket}/${aws_cloudtrail.demo_trail.s3_key_prefix}/AWSLogs/${data.aws_caller_identity.current.account_id}/CloudTrail"
    number_of_buckets         = -1
    output_format             = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"
    parameters                = {}
    stored_as_sub_directories = false

    columns {
      name = "eventtime"
      type = "string"
    }
    columns {
      name = "eventname"
      type = "string"
    }
    columns {
      name = "requestparameters"
      type = "string"
    }
    # to convert struct to json, use string here and org.openx.data.jsonserde.JsonSerDe in ser_de_info
    columns {
      name = "useridentity"
      type = "string"
    }

    ser_de_info {
      serialization_library = "org.openx.data.jsonserde.JsonSerDe"
    }
  }
}

resource "aws_s3_bucket_policy" "allow_access_quicksight" {
  bucket = aws_s3_bucket.athena_results_bucket.id
  policy = data.aws_iam_policy_document.bucket_policy_athena_results.json
}

data "aws_iam_policy_document" "bucket_policy_athena_results" {
  statement {
    sid    = "QuicksightAccess"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/service-role/aws-quicksight-service-role-v0",
                    "${data.aws_caller_identity.current.arn}"]
    }

    actions   = ["s3:*"]
    resources = [
      "${aws_s3_bucket.athena_results_bucket.arn}",
      "${aws_s3_bucket.athena_results_bucket.arn}/*"
    ]
  }
}