########################################################################
# AwsOrganizationsPolicy is the +aws_organizations_policy+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/organizations_policy.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsOrganizationsPolicy < GeoEngineer::Resource
  validate -> { validate_required_attributes([:name, :content]) }

  after :initialize, -> {
    _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id }
  }
  after :initialize, -> {
    _geo_id -> { name }
  }

  def support_tags?
    false
  end

  def self._fetch_remote_resources(provider)
    response = AwsClients.organizations(provider).list_policies({ filter: "SERVICE_CONTROL_POLICY" })
    response.policies.map(&:to_h).map do |pol|
      {
        _terraform_id: pol[:id],
        _geo_id: pol[:name],
        name: pol[:name]
      }
    end
  end
end
