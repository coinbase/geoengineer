########################################################################
# AwsSfnActivity is the +aws_sfn_activity+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/sfn_activity.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsSfnActivity < GeoEngineer::Resource
  validate -> { validate_required_attributes([:name]) }

  after :initialize, -> {
    _terraform_id -> {
      "arn:aws:states:#{environment.region}:#{environment.account_id}:activity:#{name}"
    }
  }

  def support_tags?
    false
  end

  def self._fetch_remote_resources(provider)
    AwsClients.states(provider).list_activities.activities.map(&:to_h).map do |sm|
      {
        _terraform_id: sm[:activity_arn],
        _geo_id: sm[:activity_arn],
        name: sm[:name]
      }
    end
  end
end
