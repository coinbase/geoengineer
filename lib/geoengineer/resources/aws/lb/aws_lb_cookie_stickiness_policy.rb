########################################################################
# AwsLbCookieStickinessPolicy is the +aws_lb_cookie_stickiness_policy+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/lb_cookie_stickiness_policy.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsLbCookieStickinessPolicy < GeoEngineer::Resource
  validate -> { validate_required_attributes([:name, :load_balancer, :lb_port]) }

  after :initialize, -> { _terraform_id -> { "#{load_balancer}:#{lb_port}:#{name}" } }

  def support_tags?
    false
  end

  def short_type
    "elbcookiepolicy"
  end

  def self._generate_policies(elb, policies)
    policies&.map do |policy|
      listener = elb[:listener_descriptions]
                 .find { |desc| desc[:policy_names].include?(policy[:policy_name]) }

      next unless listener

      id = "#{elb[:load_balancer_name]}:#{listener[:load_balancer_port]}:#{policy[:policy_name]}"
      {
        load_balancer: elb[:load_balancer_name],
        lb_port: listener[:listener][:load_balancer_port],
        name: policy[:policy_name],
        cookie_expiration_period: policy[:cookie_expiration_period],
        _terraform_id: id
      }
    end
  end

  def self._fetch_remote_resources(provider)
    AwsClients
      .elb(provider)
      .describe_load_balancers['load_balancer_descriptions']
      .map(&:to_h)
      .reject { |elb| elb.dig(:policies, :lb_cookie_stickiness_policies)&.empty? }
      .map { |elb| _generate_policies(elb, elb.dig(:policies, :lb_cookie_stickiness_policies)) }
      .flatten
      .compact
  end
end
