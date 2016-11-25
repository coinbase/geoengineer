########################################################################
# AwsSesReceiptRule is the +ses_receipt_rule+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/ses_receipt_rule.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsSesReceiptRule < GeoEngineer::Resource
  validate -> { validate_required_attributes([:name, :rule_set_name]) }

  after :initialize, -> {
    _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id }
  }
  after :initialize, -> {
    _geo_id -> { name.to_s }
  }

  def to_terraform_state
    tfstate = super
    tfstate[:primary][:attributes] = {
      'name' => name,
      'rule_set_name' => rule_set_name,
      'enabled' => (enabled || 'false')
    }
    tfstate
  end

  def support_tags?
    false
  end

  def self._fetch_remote_resources
    AwsClients.ses.describe_active_receipt_rule_set.rules.map(&:to_h).map do |rule|
      {
        '_terraform_id' => rule[:name],
        '_geo_id' => rule[:name]
      }
    end
  end
end
