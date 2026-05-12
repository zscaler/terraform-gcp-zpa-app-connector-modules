package terraform_zsac_bastion_gcp

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

	publicIPValid := terraform.Output(t, opts, "public_ip_valid")
	assert.Equal(t, "true", publicIPValid, "Bastion public IP should be non-empty")

	vpcValid := terraform.Output(t, opts, "vpc_network_valid")
	assert.Equal(t, "true", vpcValid, "Upstream VPC self_link should be non-empty")

	publicIP := terraform.Output(t, opts, "public_ip")
	assert.NotEmpty(t, publicIP, "Bastion public IP should not be empty")
	t.Logf("Bastion reachable at: %s", publicIP)
}

func TestIdempotence(t *testing.T) {
	opts := CreateTerraformOptions(t)
	defer terraform.Destroy(t, opts)
	terraform.InitAndApplyAndIdempotent(t, opts)
}
