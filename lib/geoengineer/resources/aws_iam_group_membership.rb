########################################################################
# AwsIamGroup +aws_iam_group_membership+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/iam_group_membership.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsIamGroupMembership < GeoEngineer::Resource
  validate -> { validate_required_attributes([:name, :users, :group]) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { name.to_s } }

  def support_tags?
    false
  end

  def remote_resource
    return @_remote if @_remote
    @_remote = build_remote_resource
    @_remote&.local_resource = self
    @_remote
  end

  def build_remote_resource
    return nil unless _group
    return nil unless _group.remote_resource

    users = AwsClients.iam.get_group({ group_name: _group.name })
    remote_resource_params(group, users)
  end

  def remote_resource_params(group, users)
    {
      name: _group.name,
      _terraform_id: name.to_s,
      _geo_id: name.to_s,
      users: users.map(&:user_name)
    }
  end
end
