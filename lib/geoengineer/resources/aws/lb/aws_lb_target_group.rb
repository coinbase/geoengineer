########################################################################
# AwsLbTargetGroup is the +aws_lb_target_group+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/lb_target_group.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsLbTargetGroup < GeoEngineer::Resource
  validate :validate_target_group_attributes
  validate -> { validate_subresource_required_attributes(:stickiness, [:type]) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id       -> { name } }

  MAX_RESOURCES_PER_REQUEST = 20

  def validate_target_group_attributes
    if attributes['target_type'] == 'lambda'
      validate_required_attributes([:name])
    else
      validate_required_attributes([:name, :port, :protocol, :vpc_id])
    end
  end

  def to_terraform_state
    tfstate = super
    tfstate[:primary][:attributes] = {
      'id' => _terraform_id,
      'deregistration_delay' => '300',
      'proxy_protocol_v2' => 'false',
      'slow_start' => '0'
    }
    tfstate
  end

  def short_type
    "lb_target_group"
  end

  def self._fetch_remote_resources(provider)
    client = AwsClients.alb(provider)

    _fetch_all_target_groups(true, [], client, nil).map(&:to_h).map do |target_group|
      target_group[:_terraform_id] = target_group[:target_group_arn]
      target_group[:_geo_id] = target_group[:target_group_name]
      target_group
    end
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
end
