########################################################################
# AwsCloudwatchMetricAlarm is the +aws_cloudwatch_metric_alarm+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/aws_cloudwatch_metric_alarm.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsCloudwatchMetricAlarm < GeoEngineer::Resource
  validate -> {
    validate_required_attributes([
                                   :alarm_name,
                                   :comparison_operator,
                                   :evaluation_periods,
                                   :metric_name,
                                   :namespace,
                                   :period,
                                   :threshold
                                 ])
  }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id       -> { alarm_name } }

  def support_tags?
    false
  end

  def self._fetch_remote_resources
    _get_all_alarms.map { |alarm|
      {
        _terraform_id: alarm[:alarm_name],
        _geo_id: alarm[:alarm_name],
        alarm_name: alarm[:alarm_name]
      }
    }
  end

  def self._get_all_alarms
    alarm_page = AwsClients.cloudwatch.describe_alarms({ max_records: 100 })
    alarms = alarm_page.metric_alarms.map(&:to_h)
    while alarm_page.next_token
      alarm_page = AwsClients.cloudwatch.describe_alarms({
                                                           max_records: 100,
                                                           next_token: alarm_page.next_token
                                                         })
      alarms.concat alarm_page.metric_alarms.map(&:to_h)
    end
    alarms
  end
end
