resource "aws_codecommit_repository" "api" {
  repository_name = "http-api"
  description     = "repo for the api"

  default_branch = "main"
}

resource "aws_codebuild_project" "py_deploy" {
  name = "container-app-build"
  #badge_enabled  = false
  #build_timeout  = 60
  #queued_timeout = 480
  service_role = aws_iam_role.build_project_role.arn

  artifacts {
    encryption_disabled = false
    # name                   = "http-api-code"
    # override_artifact_name = false
    packaging = "NONE"
    type      = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true
    type                        = "LINUX_CONTAINER"
  }

  logs_config {
    cloudwatch_logs {
      status = "ENABLED"
    }

    s3_logs {
      encryption_disabled = false
      status              = "DISABLED"
    }
  }

  source {
    git_clone_depth     = 0
    insecure_ssl        = false
    report_build_status = false
    type                = "CODEPIPELINE"
  }
}

resource "aws_s3_bucket" "cicd_bucket" {
  bucket = "s3-picccard-artifacts"

  force_destroy = true
}

resource "aws_s3_bucket_acl" "cicd_bucket" {
  bucket = aws_s3_bucket.cicd_bucket.id
  acl    = "private"
}

resource "aws_codepipeline" "python_app_pipeline" {
  name     = "python-app-pipeline"
  role_arn = aws_iam_role.apps_codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.cicd_bucket.id
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      category = "Source"
      configuration = {
        "BranchName" = aws_codecommit_repository.api.default_branch
        "PollForSourceChanges" = "false" # true starts pipeline on every codechange, no need for event
        "RepositoryName" = aws_codecommit_repository.api.repository_name
      }
      #input_artifacts = []
      name             = "Source"
      output_artifacts = ["SourceArtifact", ]
      owner            = "AWS"
      provider         = "CodeCommit"
      version   = "1"
      #run_order = 1
    }
  }

  stage {
    name = "Build"

    action {
      category = "Build"
      configuration = {
        "EnvironmentVariables" = jsonencode(
          [
            {
              name  = "LAMBDA_FUNCTION_NAME"
              type  = "PLAINTEXT"
              value = "hello"
            },
            {
              name  = "LAMBDA_CODE_ZIP_FILE_NAME"
              type  = "PLAINTEXT"
              value = "lambda_code.zip"
            },
            {
              name  = "LAMBDA_REGION"
              type  = "PLAINTEXT"
              value = "us-east-1"
            },
          ]
        )
        "ProjectName" = aws_codebuild_project.py_deploy.name
      }
      input_artifacts  = ["SourceArtifact", ]
      name             = "Build"
      output_artifacts = ["BuildArtifact", ]
      owner            = "AWS"
      provider         = "CodeBuild"
      version   = "1"
      #run_order = 1
    }
  }
}

resource "aws_cloudwatch_event_rule" "startpipeline" {
  name        = "start-cicd-pipeline"
  description = "start-cicd-pipeline"

  event_pattern = jsonencode({
    "source" : ["aws.codecommit"],
    "detail-type" : ["CodeCommit Repository State Change"],
    "resources" : ["${aws_codecommit_repository.api.arn}"],
    "detail" : {
      "event" : ["referenceCreated", "referenceUpdated"],
      "referenceType" : ["branch"],
      "referenceName" : ["main"]
    }
  })
}

resource "aws_cloudwatch_event_target" "pipeline" {
  rule      = aws_cloudwatch_event_rule.startpipeline.name
  arn       = aws_codepipeline.python_app_pipeline.arn

  role_arn = aws_iam_role.event_role.arn
}