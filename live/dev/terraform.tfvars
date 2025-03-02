#================================
# Global
#================================
project_name       = "dhan-custom"                # Base name for all resources
availability_zones = ["us-east-2a", "us-east-2b"] # Multi-AZ deployment for high availability
environment        = "dev"                        # Environment identifier (dev/staging/prod)

#================================
# CodeBuild
#================================
create_codebuild      = true                 # Enable/disable CodeBuild creation
codebuild_name        = "codebuild"          # Name of the CodeBuild project
codebuild_description = "This is codebuild." # Description for the CodeBuild project

// For testing, set build_output_artifact_type = "NO_ARTIFACTS" and build_project_source_type = "NO_SOURCE"
// For production, set build_output_artifact_type = "CODEPIPELINE" and build_project_source_type = "CODEPIPELINE"

# Artifact
codebuild_build_output_artifact_type = "CODEPIPELINE" # Artifact output configuration for pipeline integration

# source
codebuild_build_project_source_type = "CODEPIPELINE"  # Source type for build project
codebuild_buildspec_file_location   = "buildspec.yml" # Location of buildspec file in repository

# Environment
codebuild_compute_type                = "BUILD_GENERAL1_SMALL"       # Build instance size (3GB memory, 2 vCPU)
codebuild_image                       = "aws/codebuild/standard:7.0" # Base image for build environment
codebuild_type                        = "LINUX_CONTAINER"            # Container type for builds
codebuild_image_pull_credentials_type = "CODEBUILD"                  # Credentials for pulling build images
codebuild_privileged_mode             = false                        # Docker daemon access (required for Docker builds)

#================================
# CodePipeline
#================================
create_codepipeline = true                                                                                             # Enable/disable CodePipeline creation
github_repo_id      = "CloudTechService/group-app-web"                                                                 # GitHub repository identifier
github_repo_branch  = "blue-green-codepipeline-demo"                                                                   # Source branch for deployments
codeconnection_arn  = "arn:aws:codeconnections:us-east-2:779846783124:connection/c28c391e-1a4c-4490-93e2-71b986b2180b" # AWS CodeStar GitHub connection
