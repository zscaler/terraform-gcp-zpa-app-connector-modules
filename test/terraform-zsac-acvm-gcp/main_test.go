package terraform_zsac_acvm_gcp

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

	migCountOK := terraform.Output(t, opts, "instance_group_count_correct")
	assert.Equal(t, "true", migCountOK, "Should create one MIG per zone")

	vmCountOK := terraform.Output(t, opts, "ac_vm_count_correct")
	assert.Equal(t, "true", vmCountOK, "Should create ac_count * az_count VMs")

	tplProjectOK := terraform.Output(t, opts, "instance_template_project_correct")
	assert.Equal(t, "true", tplProjectOK, "Instance template should live in the requested project")

	migs := terraform.OutputList(t, opts, "instance_group_names")
	assert.NotEmpty(t, migs, "MIG name list should not be empty")
	t.Logf("Created MIGs: %v", migs)

	ips := terraform.OutputList(t, opts, "ac_private_ip")
	assert.NotEmpty(t, ips, "App Connector private IP list should not be empty")
	t.Logf("App Connector IPs: %v", ips)
}

func TestIdempotence(t *testing.T) {
	opts := CreateTerraformOptions(t)
	defer terraform.Destroy(t, opts)
	terraform.InitAndApplyAndIdempotent(t, opts)
}
