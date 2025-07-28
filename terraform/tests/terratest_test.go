package test

import (
	"testing"
	"time"
	
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestTerraformAwsNetworkerLab(t *testing.T) {
	t.Parallel()
	
	// Pick a random AWS region to test in
	awsRegion := "us-east-1"
	
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../",
		
		Vars: map[string]interface{}{
			"aws_region":         awsRegion,
			"project_name":       "test-networker-lab",
			"environment":        "test",
			"use_spot_instances": true,
			"admin_ip_cidr":      "10.0.0.1/32",
		},
		
		VarFiles: []string{"terraform.tfvars.test"},
		
		// Only test core infrastructure
		Targets: []string{
			"aws_vpc.main",
			"aws_subnet.public",
			"aws_subnet.private",
			"aws_security_group.ddve",
			"aws_security_group.networker_server",
		},
		
		NoColor: true,
	})
	
	defer terraform.Destroy(t, terraformOptions)
	
	terraform.InitAndApply(t, terraformOptions)
	
	// Validate VPC
	vpcId := terraform.Output(t, terraformOptions, "vpc_id")
	vpc := aws.GetVpcById(t, vpcId, awsRegion)
	
	require.Equal(t, "10.0.0.0/16", vpc.CidrBlock)
	assert.True(t, vpc.EnableDnsSupport)
	assert.True(t, vpc.EnableDnsHostnames)
	
	// Validate Subnets
	publicSubnetId := terraform.Output(t, terraformOptions, "public_subnet_id")
	publicSubnet := aws.GetSubnetById(t, publicSubnetId, awsRegion)
	assert.Equal(t, "10.0.1.0/24", publicSubnet.CidrBlock)
	
	// Private subnet removed in simplified architecture
	// All instances now use public subnet with public IPs
}

func TestDDVEDeployment(t *testing.T) {
	t.Parallel()
	
	awsRegion := "us-east-1"
	
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../",
		
		Vars: map[string]interface{}{
			"aws_region":            awsRegion,
			"project_name":          "test-ddve",
			"environment":           "test",
			"use_spot_instances":    true,
			"use_marketplace_amis":  true,
			"admin_ip_cidr":         "10.0.0.1/32",
		},
		
		Targets: []string{
			"module.vpc",
			"aws_instance.ddve_spot",
			"aws_s3_bucket.ddve_cloud_tier",
			"aws_iam_role.ddve",
		},
		
		MaxRetries:         3,
		TimeBetweenRetries: 5 * time.Second,
		NoColor:            true,
	})
	
	defer terraform.Destroy(t, terraformOptions)
	
	terraform.InitAndApply(t, terraformOptions)
	
	// Validate S3 bucket
	bucketName := terraform.Output(t, terraformOptions, "s3_bucket_name")
	aws.AssertS3BucketExists(t, awsRegion, bucketName)
	
	// Validate bucket encryption
	actualStatus := aws.GetS3BucketServerSideEncryption(t, awsRegion, bucketName)
	expectedStatus := "AES256"
	assert.Equal(t, expectedStatus, actualStatus)
}

func TestSpotInstanceCreation(t *testing.T) {
	t.Parallel()
	
	awsRegion := "us-east-1"
	
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../",
		
		Vars: map[string]interface{}{
			"aws_region":         awsRegion,
			"project_name":       "test-spot",
			"environment":        "test",
			"use_spot_instances": true,
			"spot_price":         "0.5",
			"admin_ip_cidr":      "10.0.0.1/32",
		},
		
		MaxRetries:         3,
		TimeBetweenRetries: 5 * time.Second,
		NoColor:            true,
	})
	
	defer terraform.Destroy(t, terraformOptions)
	
	terraform.InitAndApply(t, terraformOptions)
	
	// Verify instance type mode
	instanceMode := terraform.Output(t, terraformOptions, "instance_type_mode")
	assert.Equal(t, "spot", instanceMode)
}