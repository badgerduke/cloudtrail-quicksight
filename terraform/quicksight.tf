locals {
  demo-analysis-columns = ["eventtime", "eventname", "username", "requestparameters"]
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
  import_mode = "DIRECT_QUERY"

  physical_table_map {
    physical_table_map_id = "demo-quicksight-physical-table"

    custom_sql {
      data_source_arn = aws_quicksight_data_source.athena_data_source.arn
      name = "Custom SQL"
      sql_query = "SELECT eventtime, eventname, useridentity, requestparameters FROM demo_athena_database.demo_athena_table WHERE eventname = '${var.cloudtrail_event_name}'"

      columns {
        type = "STRING"
        name = "eventtime"
      }

      columns {
        type = "STRING"
        name = "eventname"
      }

      columns {
        type = "STRING"
        name = "useridentity"
      }

     columns {
        type = "STRING"
        name = "requestparameters"
      }     
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


resource "aws_quicksight_analysis" "demo_analysis" {
  analysis_id = "demo-analysis-id"
  name        = "demo-analysis"
  definition {
    data_set_identifiers_declarations {
      data_set_arn = aws_quicksight_data_set.demo_quicksight_dataset.arn
      identifier   = aws_quicksight_data_set.demo_quicksight_dataset.name
    }
    calculated_fields {
      data_set_identifier = aws_quicksight_data_set.demo_quicksight_dataset.data_set_id
      name = "username"
      expression = "parseJson({useridentity}, \"${var.quicksight_username_path}\")"
    }
    sheets {
      title    = "Demo Sheet"
      sheet_id = "demo_sheet"
      visuals {
        table_visual {
          visual_id = "demo-table-visual"
          title {
            format_text {
              plain_text = "Demo Sheet"
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

resource "aws_quicksight_template" "demo_template" {
  template_id         = "demo-template-id"
  name                = "demo-template-name"
  version_description = "version"

  source_entity {
    source_analysis {
      arn = aws_quicksight_analysis.demo_analysis.arn
      data_set_references {
        data_set_arn = aws_quicksight_data_set.demo_quicksight_dataset.arn
        data_set_placeholder = "Data Set Placeholder"
      }
    }
  }

  permissions {
    actions = [
      "quicksight:UpdateTemplatePermissions", 
      "quicksight:DescribeTemplatePermissions",
      "quicksight:UpdateTemplateAlias", 
      "quicksight:DeleteTemplateAlias", 
      "quicksight:DescribeTemplateAlias", 
      "quicksight:ListTemplateAliases", 
      "quicksight:ListTemplates", 
      "quicksight:CreateTemplateAlias", 
      "quicksight:DeleteTemplate", 
      "quicksight:UpdateTemplate", 
      "quicksight:ListTemplateVersions", 
      "quicksight:DescribeTemplate", 
      "quicksight:CreateTemplate"
    ]
    principal = data.aws_quicksight_user.demo.arn
  }
}

resource "aws_quicksight_dashboard" "demo_dashboard" {
  dashboard_id        = "demo-dashboard-id"
  name                = "demo-dashboard-name"
  version_description = "version"
  source_entity {
    source_template {
      arn = aws_quicksight_template.demo_template.arn
      data_set_references {
        data_set_arn = aws_quicksight_data_set.demo_quicksight_dataset.arn
        data_set_placeholder = "Data Set Placeholder"
      }
    }
  }

  permissions {
    actions = [
      "quicksight:DescribeDashboard", 
      "quicksight:ListDashboardVersions", 
      "quicksight:UpdateDashboardPermissions", 
      "quicksight:QueryDashboard", 
      "quicksight:UpdateDashboard", 
      "quicksight:DeleteDashboard", 
      "quicksight:UpdateDashboardPublishedVersion", 
      "quicksight:DescribeDashboardPermissions"
    ]
    principal = data.aws_quicksight_user.demo.arn
  }
}
