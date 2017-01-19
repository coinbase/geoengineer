########################################################################
# AwsLoadBalancerBackendServerPolicy is the
#  +aws_load_balancer_backend_server_policy+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/aws_load_balancer_backend_server_policy.html
#  Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsLoadBalancerBackendServerPolicy < GeoEngineer::Resource
  validate -> { validate_required_attributes([:instance_port, :load_balancer_name, :policy_names]) }

  after :initialize, -> {
    _terraform_id -> { "#{load_balancer_name}:#{instance_port}" }
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
    AwsClients
      .elb
      .describe_load_balancers
      .load_balancer_descriptions
      .map { |load_balancer| _extract_backend_servers(load_balancer.to_h) }
      .flatten
      .compact
  end

  def self._extract_backend_servers(load_balancer)
    load_balancer[:backend_server_descriptions].map do |server|
      server.merge(
        {
          load_balancer_name: load_balancer[:load_balancer_name],
          _terraform_id: "#{load_balancer[:load_balancer_name]}:#{server[:instance_port]}"
        }
      )
    end
  end
end
