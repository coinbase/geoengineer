########################################################################
# AwsSnsTopic is the +aws_sns_topic+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/sns_topic.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsSnsTopic < GeoEngineer::Resource
  validate -> { validate_required_attributes([:name]) }

  after :initialize, -> {
    _terraform_id -> {
      "arn:aws:sns:#{environment.region}:#{environment.account_id}:#{name}"
    }
  }

  def support_tags?
    false
  end

  def self._fetch_remote_resources
    AwsClients.sns.list_topics.topics.map(&:to_h).map do |topic|
      {
        '_terraform_id' => topic[:topic_arn],
        '_geo_id' => topic[:topic_arn],
        'name' => topic[:topic_arn].split(':').last
      }
    end
  end
end
