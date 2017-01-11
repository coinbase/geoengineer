########################################################################
# AwsCloudwatchEventRule is the +aws_cloudwatch_event_rule+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/cloudwatch_event_rule.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsCloudwatchEventRule < GeoEngineer::Resource
  validate -> { validate_required_attributes([:name, :schedule_expression]) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id       -> { self[:name] } }

  def support_tags?
    false
  end

  def self._fetch_remote_resources
    AwsClients.cloudwatchevents.list_rules.rules.map(&:to_h).map do |cloudwatch_event_rule|
      cloudwatch_event_rule.merge(
        {
          _terraform_id: cloudwatch_event_rule[:name],
          _geo_id: cloudwatch_event_rule[:name]
        }
      )
    end
  end
end
