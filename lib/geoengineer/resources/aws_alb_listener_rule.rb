########################################################################
# AwsAlbListenerRule is the +aws_alb_listener_rule+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/alb_listener_rule.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsAlbListenerRule < GeoEngineer::Resource
  validate -> { validate_required_attributes([:listener_arn, :priority, :action, :condition]) }
  validate -> {
    validate_subresource_required_attributes(:action, [:target_group_arn, :type])
  }
  validate -> {
    validate_subresource_required_attributes(:condition, [:field, :values])
  }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id       -> { "#{listener_arn}::#{priority}" } }

  def short_type
    "alb_listener_rule"
  end

  def self._merge_attributes(rule, listener)
    rule.merge(
      {
        _geo_id: "#{listener[:listener_arn]}::#{rule[:priority]}",
        _terraform_id: rule[:rule_arn]
      }
    )
  end

  def self._fetch_remote_resources(provider)
    listeners = GeoEngineer::Resources::AwsAlbListener._fetch_remote_resources(provider)
    listeners.map do |listener|
      AwsClients
        .alb(provider)
        .describe_rules({ listener_arn: listener[:listener_arn] })
        .rules
        .map(&:to_h)
        .map { |rule| _merge_attributes(rule, listener) }
    end.flatten.compact
  end
end
