#================================
# Global
#================================
project_name       = "dhan-custom"
availability_zones = ["us-east-2a", "us-east-2b"]
environment        = "dev"

#================================
# CodeBuild
#================================
create_codebuild      = true
codebuild_name        = "codebuild"
codebuild_description = "This is codebuild."

// For testing, set build_output_artifact_type = "NO_ARTIFACTS" and build_project_source_type = "NO_SOURCE"
// For production, set build_output_artifact_type = "CODEPIPELINE" and build_project_source_type = "CODEPIPELINE"

# Artifact
codebuild_build_output_artifact_type = "CODEPIPELINE"

# source
codebuild_build_project_source_type = "CODEPIPELINE"

codebuild_buildspec_file_location = "buildspec.yml" # file from the codecommit repo.

# Environment
codebuild_compute_type                = "BUILD_GENERAL1_SMALL"
codebuild_image                       = "aws/codebuild/standard:7.0"
codebuild_type                        = "LINUX_CONTAINER"
codebuild_image_pull_credentials_type = "CODEBUILD"
codebuild_privileged_mode             = false


#================================
# CodePipeline
#================================
create_codepipeline = true
github_repo_id      = "CloudTechService/group-app-web"
github_repo_branch  = "blue-green-codepipeline-demo"
codeconnection_arn  = "arn:aws:codeconnections:us-east-2:779846783124:connection/c28c391e-1a4c-4490-93e2-71b986b2180b"
