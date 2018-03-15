########################################################################
# AwsLbTargetGroup is the +aws_lb_target_group+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/lb_target_group.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsLbTargetGroup < GeoEngineer::Resource
  validate -> {
    validate_required_attributes([:port, :protocol, :vpc_id])
  }
  validate -> { validate_subresource_required_attributes(:stickiness, [:type]) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id       -> { NullObject.maybe(tags)[:Name] } }

  def to_terraform_state
    tfstate = super
    tfstate[:primary][:attributes] = {
      'id' => _terraform_id,
      'deregistration_delay' => '300'
    }
    tfstate
  end

  def short_type
    "lb_target_group"
  end

  def self._merge_attributes(target_groups, tags)
    target_groups.map do |target_group|
      target_tags = tags.find { |desc| desc[:resource_arn] == target_group[:target_group_arn] }
      target_group.merge(
        {
          _terraform_id: target_group[:target_group_arn],
          _geo_id: (target_tags || {})[:tags]&.find { |tag| tag[:key] == "Name" }&.dig(:value)
        }
      )
    end
  end

  def self._fetch_remote_resources(provider)
    target_groups = AwsClients.alb(provider).describe_target_groups.target_groups
    return [] if target_groups.empty?

    tags = AwsClients.alb(provider)
                     .describe_tags({ resource_arns: target_groups.map(&:target_group_arn) })
                     .tag_descriptions
                     .map(&:to_h)

    _merge_attributes(target_groups.map(&:to_h), tags)
  end
end
