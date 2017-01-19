########################################################################
# AwsLoadBalancerPolicy is the +aws_load_balancer_policy+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/aws_load_balancer_policy.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsLoadBalancerPolicy < GeoEngineer::Resource
  validate -> {
    validate_required_attributes([:policy_name, :policy_type_name, :load_balancer_name])
  }

  after :initialize, -> { _terraform_id -> { "#{load_balancer_name}:#{policy_name}" } }

  def support_tags?
    false
  end

  def self._fetch_remote_resources
    AwsClients
      .elb
      .describe_load_balancers
      .load_balancer_descriptions
      .map(&:to_h)
      .map { |load_balancer| _policies_for_load_balancer(load_balancer) }
      .flatten
      .compact
  end

  def self._policies_for_load_balancer(load_balancer)
    AwsClients
      .elb
      .describe_load_balancer_policies({ load_balancer_name: load_balancer[:load_balancer_name] })
      .policy_descriptions
      .map(&:to_h)
      .map do |policy|
        policy.merge(
          {
            _terraform_id: "#{load_balancer[:load_balancer_name]}:#{policy[:policy_name]}",
            load_balancer_name: load_balancer[:load_balancer_name]
          }
        )
      end
  end
end
