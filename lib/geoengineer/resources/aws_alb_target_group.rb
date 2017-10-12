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
  after :initialize, -> { _geo_id       -> { NullObject.maybe(tags)[:Name] } }

  def short_type
    "alb_target_group"
  end

  def self._merge_attributes(target_groups, tags)
    target_groups.map do |target_group|
      target_group_tags = tags.find do |desc|
        desc[:resource_arn] == target_group[:target_group_arn]
      end

      target_group.merge(
        {
          _terraform_id: target_group[:target_group_arn],
          _geo_id: target_group_tags[:tags]&.find { |tag| tag[:key] == "Name" }.dig(:value)
        }
      )
    end
  end

  def self._fetch_remote_resources(provider)
    target_groups = AwsClients.alb(provider).describe_target_groups.target_groups
    tags = AwsClients.alb(provider)
                     .describe_tags({ resource_arns: target_groups.map(&:target_group_arn) })
                     .tag_descriptions
                     .map(&:to_h)

    _merge_attributes(target_groups.map(&:to_h), tags)
  end
end
