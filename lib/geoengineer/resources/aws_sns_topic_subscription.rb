########################################################################
# AwsSnsSubscription is the +sns_topic_subscription+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/sns_topic_subscription.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsSnsTopicSubscription < GeoEngineer::Resource
  validate -> { validate_required_attributes([:protocol, :topic_arn, :endpoint]) }

  after :initialize, -> {
    _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id }
  }
  after :initialize, -> {
    _geo_id -> { "#{topic_arn}::#{protocol}::#{endpoint}" }
  }

  def to_terraform_state
    tfstate = super
    tfstate[:primary][:attributes] = {
      'topic_arn' => topic_arn,
      'endpoint' => endpoint,
      'protocol' => protocol,
      'confirmation_timeout_in_minutes' => "1",
      'endpoint_auto_confirms' => "false"
    }
    tfstate
  end

  def support_tags?
    false
  end

  def self._fetch_remote_resources
    AwsClients.sns.list_subscriptions.subscriptions.map(&:to_h).map do |subscription|
      {
        '_terraform_id' => subscription[:subscription_arn],
        '_geo_id' => "#{subscription[:topic_arn]}::" \
                     "#{subscription[:protocol]}::" \
                     "#{subscription[:endpoint]}"
      }
    end
  end
end
