########################################################################
# AwsLbListener is the +aws_lb_listener+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/lb_listener.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsLbListener < GeoEngineer::Resource
  validate -> {
    validate_required_attributes([:_load_balancer_name, :load_balancer_arn, :port, :default_action])
  }
  validate -> {
    validate_subresource_required_attributes(:default_action, [:target_group_arn, :type])
  }

  # Since we can't know the ARN until the ALB exists, it is not a good candidate for the
  # _geo_id - instead we use the ALB name, which is also unique per region
  after :initialize, -> { _geo_id       -> { "#{_load_balancer_name}::#{port}" } }
  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }

  def short_type
    "lb_listener"
  end

  def support_tags?
    false
  end

  def self._merge_attributes(listener, alb)
    listener.merge(
      {
        _geo_id: "#{alb[:load_balancer_name]}::#{listener[:port]}",
        _terraform_id: listener[:listener_arn],
        load_balancer_arn: alb[:load_balancer_arn],
        load_balancer_name: alb[:load_balancer_name]
      }
    )
  end

  def self._fetch_remote_resources(provider)
    albs = AwsClients.alb(provider).describe_load_balancers['load_balancers'].map(&:to_h)
    albs.map do |alb|
      AwsClients
        .alb(provider)
        .describe_listeners({ load_balancer_arn: alb[:load_balancer_arn] })
        .listeners
        .map(&:to_h)
        .map { |listener| _merge_attributes(listener, alb) }
    end.flatten.compact
  end
end
