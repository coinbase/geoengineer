########################################################################
# AwsIamAccountAlias +aws_iam_account_alias+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/iam_account_alias.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsIamAccountAlias < GeoEngineer::Resource
  validate -> { validate_required_attributes([:account_alias]) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { account_alias.to_s } }

  def support_tags?
    false
  end

  def self._fetch_remote_resources(provider)
    aliases = AwsClients.iam(provider).list_account_aliases['account_aliases'].to_a

    aliases.map do |a|
      { name: a, _geo_id: a, _terraform_id: a }
    end
  end
end
