########################################################################
# AwsOrganizationsOrganization is the +aws_organizations_organization+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/organizations_organization.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsOrganizationsOrganization < GeoEngineer::Resource
  after :initialize, -> {
    _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id }
  }

  # A fixed string is used here because an account can only have one
  # organization, so if multiple get defined, we want geo to error.
  after :initialize, -> { _geo_id -> { "aws_organization" } }

  def support_tags?
    false
  end

  def self._fetch_remote_resources(provider)
    org = AwsClients.organizations(provider).describe_organization().organization.to_h

    [{
      _terraform_id: org[:id],
      _geo_id: "aws_organization"
    }]
  rescue Aws::Organizations::Errors::AWSOrganizationsNotInUseException
    # Exception is thrown when the account is not already in an organization
    []
  end
end
