########################################################################
# AwsIamGroupPolicy +aws_iam_group_policy+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/iam_group_policy.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsIamGroupPolicy < GeoEngineer::Resource
  validate -> { validate_required_attributes([:name, :policy, :group]) }
  validate -> { validate_policy_length(self.policy) }

  after :initialize, -> {
    _terraform_id -> { "#{group}:#{name}" }
  }

  def to_terraform_state
    tfstate = super
    attributes = {
      'policy' => policy,
      'group' => group,
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
      .list_groups
      .groups
      .map(&:to_h)
      .map { |group| _get_group_policies(provider, group) }
      .flatten
      .compact
      .map { |group_policy| _get_policy(provider, group_policy) }
  end

  def self._get_group_policies(provider, group)
    AwsClients
      .iam(provider)
      .list_group_policies({ group_name: group[:group_name] })
      .map(&:policy_names)
      .flatten
      .map { |policy| { group_name: group[:group_name], policy_name: policy } }
  end

  def self._get_policy(provider, group_policy)
    AwsClients
      .iam(provider)
      .get_group_policy(group_policy)
      .to_h
      .merge({ _terraform_id: "#{group_policy[:group_name]}:#{group_policy[:policy_name]}",
               _geo_id: "#{group_policy[:group_name]}:#{group_policy[:policy_name]}" })
  end
end
