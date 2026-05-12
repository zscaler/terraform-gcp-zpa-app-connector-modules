package terraform_zsac_network_gcp

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func CreateTerraformOptions(t *testing.T) *terraform.Options {
	return terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: ".",
		VarFiles:     []string{"test.tfvars"},
		Logger:       logger.Default,
		Lock:         true,
		Upgrade:      true,
	})
}

func TestValidate(t *testing.T) {
	opts := CreateTerraformOptions(t)
	terraform.Init(t, opts)
	terraform.Plan(t, opts)
}

func TestPlan(t *testing.T) {
	opts := CreateTerraformOptions(t)
	terraform.Init(t, opts)
	terraform.Plan(t, opts)
}

func TestApply(t *testing.T) {
	opts := CreateTerraformOptions(t)
	defer terraform.Destroy(t, opts)
	terraform.InitAndApply(t, opts)

	vpcValid := terraform.Output(t, opts, "vpc_network_valid")
	assert.Equal(t, "true", vpcValid, "VPC self_link should be non-empty")

	acSubnetValid := terraform.Output(t, opts, "ac_subnet_valid")
	assert.Equal(t, "true", acSubnetValid, "App Connector subnet self_link should be non-empty")

	bastionCountOK := terraform.Output(t, opts, "bastion_subnet_count_correct")
	assert.Equal(t, "true", bastionCountOK, "Bastion subnet count should match bastion_enabled")

	natValid := terraform.Output(t, opts, "nat_gateway_valid")
	assert.Equal(t, "true", natValid, "Cloud NAT gateway ID should be non-empty in greenfield mode")

	vpcName := terraform.Output(t, opts, "vpc_network_name")
	assert.NotEmpty(t, vpcName, "VPC name should not be empty")
	t.Logf("Created VPC: %s", vpcName)
}

func TestIdempotence(t *testing.T) {
	opts := CreateTerraformOptions(t)
	defer terraform.Destroy(t, opts)
	terraform.InitAndApplyAndIdempotent(t, opts)
}
