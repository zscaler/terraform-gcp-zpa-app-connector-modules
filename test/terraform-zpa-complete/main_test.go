package terraform_zpa_complete

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

// TestValidate runs init + plan against the full e2e topology. This catches
// schema drift, provider download failures, and any module-to-module wiring
// breakage at the cheapest cost (no resources are created).
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

// TestApply spins up the entire base_ac topology in GCP + ZPA, asserts every
// module produced its expected outputs, then tears it all down. Expect 5-10
// minutes per run; do NOT enable on every PR — gate behind a label or
// workflow_dispatch.
func TestApply(t *testing.T) {
	opts := CreateTerraformOptions(t)
	defer terraform.Destroy(t, opts)
	terraform.InitAndApply(t, opts)

	checks := map[string]string{
		"vpc_network_valid":            "VPC self_link should be non-empty",
		"bastion_public_ip_valid":      "Bastion public IP should be non-empty",
		"app_connector_group_id_valid": "App Connector Group ID should be non-empty",
		"provisioning_key_valid":       "Provisioning key should be non-empty",
		"instance_group_count_correct": "Should create one MIG per zone",
		"ac_vm_count_correct":          "Should create ac_count * az_count VMs",
	}
	for outputName, msg := range checks {
		got := terraform.Output(t, opts, outputName)
		assert.Equal(t, "true", got, msg)
	}

	bastionIP := terraform.Output(t, opts, "bastion_public_ip")
	assert.NotEmpty(t, bastionIP, "Bastion public IP should not be empty")
	t.Logf("Bastion public IP: %s", bastionIP)

	groupID := terraform.Output(t, opts, "app_connector_group_id")
	assert.NotEmpty(t, groupID, "App Connector Group ID should not be empty")
	t.Logf("App Connector Group ID: %s", groupID)

	migs := terraform.OutputList(t, opts, "instance_group_names")
	assert.NotEmpty(t, migs, "MIG names should not be empty")
	t.Logf("MIGs: %v", migs)

	ips := terraform.OutputList(t, opts, "ac_private_ip")
	assert.NotEmpty(t, ips, "App Connector IPs should not be empty")
	t.Logf("App Connector IPs: %v", ips)
}

// TestIdempotence is the heaviest test — it applies, asserts no-diff on a
// second apply, then destroys. Use sparingly.
func TestIdempotence(t *testing.T) {
	opts := CreateTerraformOptions(t)
	defer terraform.Destroy(t, opts)
	terraform.InitAndApplyAndIdempotent(t, opts)
}
