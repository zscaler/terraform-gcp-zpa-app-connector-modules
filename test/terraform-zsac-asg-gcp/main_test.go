package terraform_zsac_asg_gcp

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

	asCountOK := terraform.Output(t, opts, "autoscaler_count_correct")
	assert.Equal(t, "true", asCountOK, "Should create one autoscaler per MIG")

	tplProjectOK := terraform.Output(t, opts, "instance_template_project_correct")
	assert.Equal(t, "true", tplProjectOK, "Instance template should live in the requested project")

	autoscalers := terraform.OutputList(t, opts, "autoscaler_names")
	assert.NotEmpty(t, autoscalers, "Autoscaler name list should not be empty")
	t.Logf("Created autoscalers: %v", autoscalers)
}

func TestIdempotence(t *testing.T) {
	opts := CreateTerraformOptions(t)
	defer terraform.Destroy(t, opts)
	terraform.InitAndApplyAndIdempotent(t, opts)
}
