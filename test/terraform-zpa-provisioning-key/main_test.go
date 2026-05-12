package terraform_zpa_provisioning_key

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

	groupIDValid := terraform.Output(t, opts, "app_connector_group_id_valid")
	assert.Equal(t, "true", groupIDValid, "App Connector Group ID should be valid")

	pkeyValid := terraform.Output(t, opts, "provisioning_key_valid")
	assert.Equal(t, "true", pkeyValid, "Provisioning key should be non-empty")

	groupID := terraform.Output(t, opts, "app_connector_group_id")
	assert.NotEmpty(t, groupID, "App Connector Group ID should not be empty")

	// Provisioning key is marked sensitive in outputs.tf so terratest will mask
	// it; we still assert the raw length via the validation output above.
	t.Logf("Provisioning key bound to App Connector Group: %s", groupID)
}

func TestIdempotence(t *testing.T) {
	opts := CreateTerraformOptions(t)
	defer terraform.Destroy(t, opts)
	terraform.InitAndApplyAndIdempotent(t, opts)
}
