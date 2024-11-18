locals {
  demo-analysis-columns = ["eventtime", "eventname", "useridentity", "requestparameters"]
}


resource "aws_s3_object" "file_upload" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id
  key    = "quicksight-manifest.json"
  source = "${path.module}/../quicksight-manifest.json"
  etag   = "${filemd5("${path.module}/../quicksight-manifest.json")}"
}

resource "aws_quicksight_data_source" "athena_data_source" {
  aws_account_id = "${data.aws_caller_identity.current.account_id}"
  data_source_id = aws_athena_workgroup.example.name
  name           = aws_athena_workgroup.example.name
  type           = "ATHENA"

  parameters {
    athena {
      work_group = aws_athena_workgroup.example.id
    }
  }

  permission {
    actions = [
      "quicksight:DescribeDataSource",
      "quicksight:DescribeDataSourcePermissions",
      "quicksight:PassDataSource",
      "quicksight:UpdateDataSource",
      "quicksight:DeleteDataSource",
      "quicksight:UpdateDataSourcePermissions"
    ]
    principal = data.aws_quicksight_user.demo.arn
  }
}


resource "aws_quicksight_data_set" "demo_quicksight_dataset" {
  data_set_id = "demo_quicksight_dataset"
  name        = "demo_quicksight_dataset"
  import_mode = "SPICE"

  physical_table_map {
    physical_table_map_id = "demo-quicksight-physical-table"
    relational_table {
      data_source_arn = aws_quicksight_data_source.athena_data_source.arn
      schema          = aws_athena_database.athena_database.name
      name            = aws_glue_catalog_table.cloudtrail.name

      input_columns {
        name = "eventtime"
        type = "STRING"
      }

      input_columns {
        name = "eventname"
        type = "STRING"
      }

      input_columns {
        name = "useridentity"
        type = "JSON"
      }

      input_columns {
        name = "requestparameters"
        type = "JSON"
      }
    }
  }

  logical_table_map {
    logical_table_map_id = "logical-table-id"
    alias                = aws_glue_catalog_table.cloudtrail.name
    data_transforms {
      project_operation {
        projected_columns = [
          "eventtime",
          "eventname",
          "username",
          "useridentity",
          "requestparameters"
        ]
      }
      create_columns_operation {
        columns {
          column_id = "username"
          column_name = "username"
          expression = "{useridentity.username}"
        }
      }
    } 

    source {
        physical_table_id  = "demo-quicksight-physical-table"
    }
  }

  permissions {
    actions = [
      "quicksight:ListIngestions",
      "quicksight:DeleteDataSet",
      "quicksight:UpdateDataSetPermissions",
      "quicksight:CancelIngestion",
      "quicksight:DescribeDataSetPermissions",
      "quicksight:UpdateDataSet",
      "quicksight:DescribeDataSet",
      "quicksight:PassDataSet",
      "quicksight:DescribeIngestion",
      "quicksight:CreateIngestion"
    ]
    principal = data.aws_quicksight_user.demo.arn
  }

  depends_on = [ aws_glue_catalog_table.cloudtrail ]
}


resource "aws_quicksight_analysis" "example" {
  analysis_id = "demo-analysis-id"
  name        = "demo-analysis"
  definition {
    data_set_identifiers_declarations {
      data_set_arn = aws_quicksight_data_set.demo_quicksight_dataset.arn
      identifier   = aws_quicksight_data_set.demo_quicksight_dataset.name
    }
    sheets {
      title    = "Demo Sheet"
      sheet_id = "demo_sheet"
      visuals {
        table_visual {
          visual_id = "demo-table-visual"
          title {
            format_text {
              plain_text = "Line Chart Example"
            }
          }
          chart_configuration {
            field_wells {
              table_unaggregated_field_wells {
                dynamic "values" {
                  for_each = local.demo-analysis-columns
                  content {
                    field_id = "${values.value}"
                    column {
                      column_name = "${values.value}"
                      data_set_identifier = aws_quicksight_data_set.demo_quicksight_dataset.data_set_id
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
  permissions {
    actions = ["quicksight:RestoreAnalysis", 
               "quicksight:UpdateAnalysisPermissions", 
               "quicksight:DeleteAnalysis", 
               "quicksight:QueryAnalysis", 
               "quicksight:DescribeAnalysisPermissions", 
               "quicksight:DescribeAnalysis", 
               "quicksight:UpdateAnalysis"]
    principal = data.aws_quicksight_user.demo.arn
  }
}