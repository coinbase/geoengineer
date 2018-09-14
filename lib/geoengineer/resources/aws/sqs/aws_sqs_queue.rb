########################################################################
# AwsSqsQueue is the +aws_sqs_queue+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/sqs_queue.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsSqsQueue < GeoEngineer::Resource
  validate -> { validate_required_attributes([:name]) }

  after :initialize, -> {
    _terraform_id -> {
      "https://sqs.#{environment.region}.amazonaws.com/#{environment.account_id}/#{name}"
    }
  }

  # The loadbalancer and the instance ports are necessary in the terraform state for the policy
  def to_terraform_state
    tfstate = super
    tfstate[:primary][:attributes] = {
      'name' => name
    }
    tfstate
  end

  def support_tags?
    false
  end

  def self._fetch_remote_resources(provider)
    AwsClients.sqs(provider).list_queues['queue_urls'].map do |queue|
      {
        _terraform_id: queue,
        _geo_id: queue,
        name: URI.parse(queue).path.split('/').last
      }
    end
  end
end
