########################################################################
# AwsLb is the +aws_lb+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/lb.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsLb < GeoEngineer::Resource
  validate -> { validate_required_attributes([:name, :load_balancer_type , :subnets]) }
  validate -> { validate_subresource_required_attributes(:access_logs, [:bucket]) }
  validate -> { validate_subresource_required_attributes(:subnet_mapping, [:subnet_id]) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id       -> { "#{name}::#{load_balancer_type}" } }

  # The ALB client only allows fetching the tags from 20 ALBs at once
  MAXIMUM_FETCHABLE_ALBS = 20

  def to_terraform_state
    tfstate = super
    tfstate[:primary][:attributes] = {
      'id' => _terraform_id,
      'idle_timeout' => '60',
      'enable_deletion_protection' => 'false',
      'enable_http2' => 'true',
      'enable_cross_zone_load_balancing' => 'false'
    }
    tfstate
  end

  def short_type
    "lb"
  end

  def self._fetch_remote_resources(provider)
    client = AwsClients.alb(provider)
    client.describe_load_balancers['load_balancers'].map(&:to_h).map do |lb|
      lb[:_terraform_id] = lb[:load_balancer_arn]
      lb[:_geo_id] = "#{lb[:load_balancer_name]}::#{lb[:type]}"
      lb
    end
  end
end
