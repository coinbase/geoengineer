########################################################################
# AwsLoadBalancerBackendServerPolicy is the
#  +aws_load_balancer_backend_server_policy+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/aws_load_balancer_backend_server_policy.html
#  Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsLoadBalancerBackendServerPolicy < GeoEngineer::Resource
  validate -> { validate_required_attributes([:instance_port, :load_balancer_name]) }

  after :initialize, -> {
    _terraform_id -> { "#{load_balancer_name}:#{instance_port}" }
  }
  after :initialize, -> {
    _geo_id -> { "#{load_balancer_name}:#{instance_port}" }
  }

  def to_terraform_state
    tfstate = super
    tfstate[:primary][:attributes] = {
      'load_balancer_name' => load_balancer_name,
      'instance_port' => instance_port.to_s
    }
    tfstate
  end

  def support_tags?
    false
  end

  def self._fetch_remote_resources
    load_balancer_name ||= ""

    AwsClients
      .elb.describe_load_balancers({ load_balancer_names: [load_balancer_name] })
      .load_balancer_descriptions
      .flatten
      .map(&:to_h)
      .map { |description| description[:backend_server_descriptions] }
      .flatten
      .compact
      .map do |policy|
        {
          '_terraform_id' => policy[:policy_names],
          '_geo_id' => policy[:policy_names]
        }
      end
  end
end
