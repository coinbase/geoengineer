########################################################################
# AwsCloudwatchEventTarget is the +aws_cloudwatch_event_target+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/cloudwatch_event_target.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsCloudwatchEventTarget < GeoEngineer::Resource
  validate -> { validate_required_attributes([:rule, :arn, :target_id]) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id       -> { "#{self.rule}-#{self.target_id}" } }

  def to_terraform_state
    tfstate = super
    tfstate[:primary][:attributes] = {
      'target_id' => self.target_id,
      'rule' => self.rule
    }
    tfstate
  end

  def support_tags?
    false
  end

  def self._fetch_remote_resources(provider)
    AwsClients
      .cloudwatchevents(provider)
      .list_rules
      .rules
      .map(&:to_h)
      .map { |rule| _get_rule_targets(provider, rule) }
      .flatten
      .map do |rule_target|
      rule_target.merge(
        {
          _terraform_id: "#{rule_target[:rule_name]}-#{rule_target[:id]}",
          _geo_id: "#{rule_target[:rule_name]}-#{rule_target[:id]}"
        }
      )
    end
  end

  def self._get_rule_targets(provider, rule)
    AwsClients
      .cloudwatchevents(provider)
      .list_targets_by_rule({ rule: rule[:name] })[:targets]
      .map(&:to_h)
      .map { |target| target.merge({ rule_name: rule[:name] }) }
  end
end
