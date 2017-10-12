########################################################################
# AwsAlbListener is the +aws_alb_listener+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/alb_listener.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsAlbListener < GeoEngineer::Resource
  validate -> { validate_required_attributes([:load_balancer_arn, :port, :default_action]) }
  validate -> {
    validate_subresource_required_attributes(:default_action, [:target_group_arn, :type])
  }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id       -> { "#{load_balancer_arn}::#{port}" } }

  def short_type
    "alb_listener"
  end

  def support_tags?
    false
  end

  def self._merge_attributes(listener)
    listener.merge(
      {
        _geo_id: "#{listener[:load_balancer_arn]}::#{listener[:port]}",
        _terraform_id: listener[:listener_arn]
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
        .map { |listener| _merge_attributes(listener) }
    end.flatten.compact
  end
end
