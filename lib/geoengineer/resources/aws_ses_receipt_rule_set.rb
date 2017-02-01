########################################################################
# AwsSesReceiptRuleSet is the +ses_receipt_rule_set+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/ses_receipt_rule_set.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsSesReceiptRuleSet < GeoEngineer::Resource
  validate -> { validate_required_attributes([:rule_set_name]) }

  after :initialize, -> {
    _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id }
  }
  after :initialize, -> {
    _geo_id -> { rule_set_name.to_s }
  }

  def support_tags?
    false
  end

  def self._fetch_remote_resources
    AwsClients.ses.list_receipt_rule_sets.rule_sets.map(&:to_h).map do |rule_set|
      {
        _terraform_id: rule_set[:name],
        _geo_id: rule_set[:name]
      }
    end
  end
end
