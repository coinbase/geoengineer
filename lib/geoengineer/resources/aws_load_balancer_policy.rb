########################################################################
# AwsLoadBalancerPolicy is the +aws_load_balancer_policy+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/aws_load_balancer_policy.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsLoadBalancerPolicy < GeoEngineer::Resource
  validate -> { validate_required_attributes([:policy_name, :load_balancer_name]) }

  after :initialize, -> {
    _terraform_id -> { "#{load_balancer_name}:#{policy_name}" }
  }
  after :initialize, -> {
    _geo_id -> { "#{load_balancer_name}:#{policy_name}" }
  }

  def support_tags?
    false
  end

  def self._fetch_remote_resources
    load_balancer_name ||= ""

    AwsClients
      .elb.describe_load_balancer_policies({ load_balancer_name: load_balancer_name })
      .policy_descriptions.map(&:to_h)
      .map do |policy|
        {
          '_terraform_id' => policy[:policy_name],
          '_geo_id' => policy[:policy_name]
        }
      end
  end
end
