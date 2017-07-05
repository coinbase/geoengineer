########################################################################
# AwsWafWebAcl is the +aws_waf_web_acl+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/waf_web_acl.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsWafWebAcl < GeoEngineer::Resource
  validate -> { validate_required_attributes([:metric_name, :default_action, :name, :rules]) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { name } }

  def self._fetch_remote_resources(provider)
    AwsClients.waf(provider).list_web_acls['web_acls'].map(&:to_h).map do |acl|
      acl.merge(
        {
          _terraform_id: acl[:web_acl_id],
          _geo_id: acl[:name]
        }
      )
    end
  end

  def support_tags?
    false
  end
end
