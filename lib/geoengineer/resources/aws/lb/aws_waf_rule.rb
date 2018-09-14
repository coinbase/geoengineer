########################################################################
# AwsWafRule is the +aws_waf_rule+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/waf_rule.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsWafRule < GeoEngineer::Resource
  validate -> { validate_required_attributes([:metric_name, :name]) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { name } }

  def self._fetch_remote_resources(provider)
    AwsClients.waf(provider).list_rules['rules'].map(&:to_h).map do |s|
      s.merge(
        {
          _terraform_id: s[:rule_id],
          _geo_id: s[:name]
        }
      )
    end
  end

  def support_tags?
    false
  end
end
