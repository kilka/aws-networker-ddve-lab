plugin "aws" {
  enabled = true
  version = "0.27.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

# Terraform version constraint
rule "terraform_required_version" {
  enabled = true
}

# Ensure all resources are tagged
rule "aws_resource_missing_tags" {
  enabled = true
  tags = ["Name", "Environment", "ManagedBy"]
}

# Naming conventions
rule "terraform_naming_convention" {
  enabled = true
  
  # Enforce lowercase letters, numbers, and hyphens
  variable {
    format = "snake_case"
  }
  
  locals {
    format = "snake_case"
  }
  
  output {
    format = "snake_case"
  }
  
  resource {
    format = "snake_case"
  }
}

# Documentation requirements
rule "terraform_documented_variables" {
  enabled = true
}

rule "terraform_documented_outputs" {
  enabled = true
}

# Best practices
rule "terraform_unused_declarations" {
  enabled = true
}

rule "terraform_deprecated_interpolation" {
  enabled = true
}

rule "terraform_module_pinned_source" {
  enabled = true
}

# AWS specific rules
rule "aws_instance_invalid_type" {
  enabled = true
}

rule "aws_instance_previous_type" {
  enabled = true
}

rule "aws_db_instance_previous_type" {
  enabled = true
}

rule "aws_elasticache_cluster_previous_type" {
  enabled = true
}

# Security rules
rule "aws_iam_policy_document_gov_friendly_arns" {
  enabled = true
}

rule "aws_iam_role_policy_gov_friendly_arns" {
  enabled = true
}

rule "aws_s3_bucket_public_read_prohibited" {
  enabled = true
}

rule "aws_security_group_rule_invalid_protocol" {
  enabled = true
}