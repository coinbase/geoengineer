########################################################################
# AwsIamGroup +aws_iam_group_membership+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/iam_group_membership.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsIamGroupMembership < GeoEngineer::Resource
  validate -> { validate_required_attributes([:name, :users, :group]) }

  before :validation, -> { group _group.to_ref(:name) if _group }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { name.to_s } }

  def to_terraform_state
    tfstate = super

    attributes = {
      'group' => _group.name.to_s,
      'name' => name.to_s
    }
    # attributes = { 'users.#' => users.count.to_s }
    # users.each_with_index { |u, i| attributes["users.#{i}"] = u }

    tfstate[:primary][:attributes] = attributes
    tfstate
  end

  def support_tags?
    false
  end

  def find_remote_as_individual?
    true
  end

  def remote_resource_params
    return {} unless _group
    return {} unless _group.remote_resource

    users = AwsClients.iam.get_group({ group_name: _group.name })['users']
    build_remote_resource_params(users)
  end

  def build_remote_resource_params(users)
    {
      name: _group.name,
      _terraform_id: name.to_s,
      _geo_id: name.to_s,
      users: users.map(&:user_name)
    }
  end
end
