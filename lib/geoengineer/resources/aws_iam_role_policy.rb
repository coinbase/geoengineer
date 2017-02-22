########################################################################
# AwsIamRolePolicy +aws_iam_role_policy+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/iam_role_policy.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsIamRolePolicy < GeoEngineer::Resource
  validate -> { validate_required_attributes([:name, :policy, :role]) }
  validate -> { validate_policy_length(self.policy) }

  after :initialize, -> {
    _terraform_id -> { "#{role}:#{name}" }
  }

  def to_terraform_state
    tfstate = super
    attributes = {
      'policy' => policy,
      'role' => role,
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
      .list_roles
      .roles
      .map(&:to_h)
      .map { |role| _get_role_policies(provider, role) }
      .flatten
      .compact
      .map { |role_policy| _get_policy(provider, role_policy) }
  end

  def self._get_role_policies(provider, role)
    AwsClients
      .iam(provider)
      .list_role_policies({ role_name: role[:role_name] })
      .map(&:policy_names)
      .flatten
      .map { |policy| { role_name: role[:role_name], policy_name: policy } }
  end

  def self._get_policy(provider, role_policy)
    AwsClients
      .iam(provider)
      .get_role_policy(role_policy)
      .to_h
      .merge({ _terraform_id: "#{role_policy[:role_name]}:#{role_policy[:policy_name]}" })
  end
end
