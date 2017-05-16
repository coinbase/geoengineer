########################################################################
# AwsAlbTargetGroup is the +aws_alb_target_group+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/alb_target_group.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsAlbTargetGroup < GeoEngineer::Resource
  validate -> {
    validate_required_attributes([:port, :protocol, :vpc_id])
  }
  validate -> { validate_subresource_required_attributes(:stickiness, [:type]) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id       -> { "#{vpc_id}::#{protocol}::#{port}" } }

  def short_type
    "alb_target_group"
  end

  def self._fetch_remote_resources(provider)
    target_groups = AwsClients.alb(provider).describe_target_groups.target_groups.map(&:to_h)
    target_groups.map do |group|
      group.merge(
        {
          _geo_id: "#{group[:vpc_id]}::#{group[:protocol]}::#{group[:port]}",
          _terraform_id: group[:target_group_arn]
        }
      )
    end
  end
end
