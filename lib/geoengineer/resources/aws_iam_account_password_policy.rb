########################################################################
# AwsIamPasswordPolicy +aws_iam_password_policy+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/iam_account_password_policy.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsIamAccountPasswordPolicy < GeoEngineer::Resource
  # There can only be a single IAM account password policy - use this constant as the Geo ID
  SINGLETON_ID = 'GEO_SINGLETON_RESOURCE_ID'.freeze

  validate -> { validate_required_attributes([:allow_users_to_change_password]) }

  after :initialize, -> {
    _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id }
  }

  after :initialize, -> { _geo_id -> { SINGLETON_ID } }

  def support_tags?
    false
  end

  def find_remote_as_individual?
    true
  end

  def remote_resource_params
    password_policy = AwsClients.iam.get_account_password_policy.password_policy.to_h
    password_policy.merge({ _geo_id: SINGLETON_ID, _terraform_id: SINGLETON_ID })
  rescue Aws::IAM::Errors::NoSuchEntity
    {}
  end
end
