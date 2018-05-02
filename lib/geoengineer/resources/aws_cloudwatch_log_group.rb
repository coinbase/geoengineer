########################################################################
# AwsCloudwatchLogGroup is the +aws_cloudwatch_log_group+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/cloudwatch_log_group.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsCloudwatchLogGroup < GeoEngineer::Resource
  validate -> { validate_required_attributes([:name]) }

  after :initialize, -> { _terraform_id -> { self[:name] } }
  after :initialize, -> { _geo_id       -> { self[:name] } }

  def support_tags?
    false
  end

  def self._fetch_remote_resources(provider)
    AwsClients
      .cloudwatchlogs(provider)
      .describe_log_groups.log_groups.map(&:to_h).map do |log_group|
      log_group.merge(
        {
          _terraform_id: log_group[:log_group_name],
          _geo_id: log_group[:log_group_name]
        }
      )
      log_group
    end
  end
end
