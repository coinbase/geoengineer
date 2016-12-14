########################################################################
# AwsIamPolicyAttachment +aws_iam_policy_attachment+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/iam_policy_attachment.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsIamPolicyAttachment < GeoEngineer::Resource
  validate -> { validate_required_attributes([:name, :_policy]) }

  validate :shares_name_with_policy

  before :validation, -> { policy_arn _policy.to_ref(:arn) if _policy }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { name.to_s } }

  def validate_shares_name_with_policy
    return "Policy attachment must share a name with the policy" unless shares_name_with_policy?
    []
  end

  def shares_name_with_policy?
    policy && name.to_s == policy.name
  end

  def to_terraform_state
    tfstate = super

    attributes = { 'name' => name.to_s }
    attributes['policy_arn'] = remote_resource.policy_arn if remote_resource

    attributes = attributes
                 .merge(terraform_users_attributes)
                 .merge(terraform_groups_attributes)
                 .merge(terraform_roles_attributes)

    tfstate[:primary][:attributes] = attributes
    tfstate
  end

  def terraform_users_attributes
    return {} if users.nil?

    user_attributes = { 'users.#' => users.count.to_s }
    users.each_with_index { |u, i| user_attributes["users.#{i}"] = u }

    user_attributes
  end

  def terraform_groups_attributes
    return {} if groups.nil?

    groups_attributes = { 'groups.#' => groups.count.to_s }
    groups.each_with_index { |g, i| groups_attributes["groups.#{i}"] = g }

    groups_attributes
  end

  def terraform_roles_attributes
    return {} if roles.nil?

    roles_attributes = { 'roles.#' => roles.count.to_s }
    roles.each_with_index { |r, i| roles_attributes["roles.#{i}"] = r }

    roles_attributes
  end

  def support_tags?
    false
  end

  def find_remote_as_individual?
    true
  end

  def remote_resource_params
    return {} unless _policy
    return {} unless _policy.remote_resource

    arn = _policy.remote_resource._terraform_id
    entities = AwsClients.iam.list_entities_for_policy({ policy_arn: arn })
    build_remote_resource_params(arn, entities)
  end

  def build_remote_resource_params(arn, entities)
    {
      name: _policy.name,
      _terraform_id: arn,
      _geo_id: _policy.name,
      policy_arn: arn,
      users: entities[:policy_users].map(&:user_name),
      groups: entities[:policy_groups].map(&:group_name),
      roles: entities[:policy_roles].map(&:role_name)
    }
  end
end
