########################################################################
# AwsPlacementGroup is the +aws_placement_group+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/placement_group.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsPlacementGroup < GeoEngineer::Resource
  validate -> { validate_required_attributes([:name, :strategy]) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id       -> { name } }

  def support_tags?
    false
  end

  def self._fetch_remote_resources(provider)
    pgs = AwsClients.ec2(provider).describe_placement_groups['placement_groups']
    pgs.map(&:to_h).map do |group|
      group[:_terraform_id] = group[:group_name]
      group[:_geo_id] = group[:group_name]
      group[:name] = group[:group_name]
      group
    end
  end
end
