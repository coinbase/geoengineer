########################################################################
# AwsLbSslNegotiationPolicy is the +aws_load_balancer_listener_policy+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/load_balancer_listener_policy.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsLoadBalancerListenerPolicy < GeoEngineer::Resource
  validate -> {
    validate_required_attributes([:load_balancer_name, :load_balancer_port, :policy_names])
  }

  after :initialize, -> { _terraform_id -> { "#{load_balancer_name}:#{load_balancer_port}" } }
  after :initialize, -> { _geo_id -> { "#{load_balancer_name}:#{load_balancer_port}" } }

  def support_tags?
    false
  end

  def self._merge_attributes(listener_desc, elb)
    listener = listener_desc[:listener]
    listener.merge(
        {
            _geo_id: "#{elb[:load_balancer_name]}::#{listener[:load_balancer_port]}",
            _terraform_id: "#{elb[:load_balancer_name]}:#{listener[:load_balancer_port]}",
            load_balancer_name: elb[:load_balancer_name],
            policy_names: listener_desc[:policy_names]
        }
    )
  end

  def self._fetch_remote_resources(provider)
    AwsClients
        .elb(provider)
        .describe_load_balancers
        .load_balancer_descriptions
        .map(&:to_h)
        .map { |elb| elb[:listener_descriptions].map {|listener_desc| _merge_attributes(listener_desc, elb)} }
        .flatten
        .compact
  end
end

