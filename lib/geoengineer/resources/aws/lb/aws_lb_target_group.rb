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

  MAX_RESOURCES_PER_REQUEST = 20

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
    client = AwsClients.alb(provider)

    target_groups = _fetch_all_target_groups(true, [], client, nil)
    return [] if target_groups.empty?

    tags = _fetch_all_target_groups_tags(target_groups, client)

    _merge_attributes(target_groups.map(&:to_h), tags)
  end

  def self._fetch_all_target_groups(continue, target_groups, client, marker)
    return target_groups unless continue
    target_group_resp = client.describe_target_groups({ marker: marker,
                                                        page_size: MAX_RESOURCES_PER_REQUEST })
    _fetch_all_target_groups(target_group_resp.next_page?,
                             target_groups + target_group_resp['target_groups'],
                             client,
                             target_group_resp.next_marker)
  end

  def self._fetch_all_target_groups_tags(target_groups, client)
    arn_chunks = target_groups.each_slice(MAX_RESOURCES_PER_REQUEST).map do |chunk|
      chunk.map(&:target_group_arn)
    end

    Parallel.map(arn_chunks, { in_threads: Parallel.processor_count }) do |target_group_arns|
      client.describe_tags({ resource_arns: target_group_arns })
            .tag_descriptions
            .map(&:to_h)
    end.flatten
  end
end
