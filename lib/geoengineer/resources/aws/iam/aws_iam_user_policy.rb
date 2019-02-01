########################################################################
# AwsIamUserPolicy +aws_iam_user_policy+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/iam_user_policy.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsIamUserPolicy < GeoEngineer::Resource
  validate -> { validate_required_attributes([:name, :policy, :user]) }
  validate -> { validate_policy_length(self.policy) }

  after :initialize, -> {
    _terraform_id -> { "#{user}:#{name}" }
  }

  def to_terraform_state
    tfstate = super
    attributes = {
      'policy' => policy,
      'user' => user,
      'name' => name
    }

    tfstate[:primary][:attributes] = attributes

    tfstate
  end

  def support_tags?
    false
  end

  def _policy_file(path, binding_obj = nil)
    _json_file(:policy, path, binding_obj)
  end

  def self._fetch_remote_resources(provider)
    AwsClients
      .iam(provider)
      .list_users
      .users
      .map(&:to_h)
      .map { |user| _get_user_policies(provider, user) }
      .flatten
      .compact
      .map { |user_policy| _get_policy(provider, user_policy) }
  end

  def self._get_user_policies(provider, user)
    AwsClients
      .iam(provider)
      .list_user_policies({ user_name: user[:user_name] })
      .map(&:policy_names)
      .flatten
      .map { |policy| { user_name: user[:user_name], policy_name: policy } }
  end

  def self._get_policy(provider, user_policy)
    AwsClients
      .iam(provider)
      .get_user_policy(user_policy)
      .to_h
      .merge({ _terraform_id: "#{user_policy[:user_name]}:#{user_policy[:policy_name]}",
               _geo_id: "#{user_policy[:user_name]}:#{user_policy[:policy_name]}" })
  end
end
