########################################################################
# AwsIamUser +aws_iam_user+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/iam_user.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsIamUser < GeoEngineer::Resource
  validate -> { validate_required_attributes([:name]) }

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
      'force_destroy' => (force_destroy || 'false')
    }
    tfstate
  end

  def support_tags?
    false
  end

  def self._all_remote_users
    AwsClients.iam.list_users.each.map(&:users).flatten.map(&:to_h)
  end

  def self._fetch_remote_resources
    _all_remote_users.map do |user|
      {
        _terraform_id: user[:user_name],
        _geo_id: user[:user_name],
        name: user[:user_name]
      }
    end
  end
end
