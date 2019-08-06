########################################################################
# AwsClients contains a list of aws-clients for use
# The main reason for their central management is their initialisation testing and stubbing
########################################################################
class AwsClients
  def self.stub!
    @stub_aws = true
  end

  def self.stubbed?
    @stub_aws || false
  end

  def self.client_params(provider = nil)
    client_params = { stub_responses: stubbed? }
    client_params[:region] = provider.region if provider
    client_params[:retry_limit] = Integer(ENV['AWS_RETRY_LIMIT']) if ENV['AWS_RETRY_LIMIT']
    client_params
  end

  def self.client_cache(provider, client)
    provider = nil if stubbed? # we ignore all providers if we are stubbing

    @client_cache ||= {}
    key = "#{client.name}_" + (provider&.terraform_id || GeoEngineer::Resource::DEFAULT_PROVIDER)
    @client_cache[key] ||= client.new(client_params(provider))
  end

  def self.clear_cache!
    @client_cache = {}
  end

  # Clients

  def self.alb(provider = nil)
    self.client_cache(
      provider,
      Aws::ElasticLoadBalancingV2::Client
    )
  end

  def self.api_gateway(provider = nil)
    self.client_cache(
      provider,
      Aws::APIGateway::Client
    )
  end

  def self.cloudfront(provider = nil)
    self.client_cache(
      provider,
      Aws::CloudFront::Client
    )
  end

  def self.cloudwatch(provider = nil)
    self.client_cache(
      provider,
      Aws::CloudWatch::Client
    )
  end

  def self.cloudwatchevents(provider = nil)
    self.client_cache(
      provider,
      Aws::CloudWatchEvents::Client
    )
  end

  def self.cloudwatchlogs(provider = nil)
    self.client_cache(
      provider,
      Aws::CloudWatchLogs::Client
    )
  end

  def self.directconnect(provider = nil)
    self.client_cache(
      provider,
      Aws::DirectConnect::Client
    )
  end

  def self.dax(provider = nil)
    self.client_cache(
      provider,
      Aws::DAX::Client
    )
  end

  def self.dynamo(provider = nil)
    self.client_cache(
      provider,
      Aws::DynamoDB::Client
    )
  end

  def self.ec2(provider = nil)
    self.client_cache(
      provider,
      Aws::EC2::Client
    )
  end

  def self.elasticache(provider = nil)
    self.client_cache(
      provider,
      Aws::ElastiCache::Client
    )
  end

  def self.elasticsearch(provider = nil)
    self.client_cache(
      provider,
      Aws::ElasticsearchService::Client
    )
  end

  def self.elb(provider = nil)
    self.client_cache(
      provider,
      Aws::ElasticLoadBalancing::Client
    )
  end

  def self.iam(provider = nil)
    self.client_cache(
      provider,
      Aws::IAM::Client
    )
  end

  def self.kafka(provider = nil)
    self.client_cache(
      provider,
      Aws::Kafka::Client
    )
  end

  def self.kinesis(provider = nil)
    self.client_cache(
      provider,
      Aws::Kinesis::Client
    )
  end

  def self.firehose(provider = nil)
    self.client_cache(
      provider,
      Aws::Firehose::Client
    )
  end

  def self.lambda(provider = nil)
    self.client_cache(
      provider,
      Aws::Lambda::Client
    )
  end

  def self.rds(provider = nil)
    self.client_cache(
      provider,
      Aws::RDS::Client
    )
  end

  def self.redshift(provider = nil)
    self.client_cache(
      provider,
      Aws::Redshift::Client
    )
  end

  def self.route53(provider = nil)
    self.client_cache(
      provider,
      Aws::Route53::Client
    )
  end

  def self.route53resolver(provider = nil)
    self.client_cache(
      provider,
      Aws::Route53Resolver::Client
    )
  end

  def self.s3(provider = nil)
    self.client_cache(
      provider,
      Aws::S3::Client
    )
  end

  def self.ses(provider = nil)
    self.client_cache(
      provider,
      Aws::SES::Client
    )
  end

  def self.states(provider = nil)
    self.client_cache(
      provider,
      Aws::States::Client
    )
  end

  def self.sns(provider = nil)
    self.client_cache(
      provider,
      Aws::SNS::Client
    )
  end

  def self.sqs(provider = nil)
    self.client_cache(
      provider,
      Aws::SQS::Client
    )
  end

  def self.cloudtrail(provider = nil)
    self.client_cache(
      provider,
      Aws::CloudTrail::Client
    )
  end

  def self.codebuild(provider = nil)
    self.client_cache(
      provider,
      Aws::CodeBuild::Client
    )
  end

  def self.kms(provider = nil)
    self.client_cache(
      provider,
      Aws::KMS::Client
    )
  end

  def self.waf(provider = nil)
    self.client_cache(
      provider,
      Aws::WAF::Client
    )
  end

  def self.emr(provider = nil)
    self.client_cache(
      provider,
      Aws::EMR::Client
    )
  end

  def self.efs(provider = nil)
    self.client_cache(
      provider,
      Aws::EFS::Client
    )
  end

  def self.codedeploy(provider = nil)
    self.client_cache(
      provider,
      Aws::CodeDeploy::Client
    )
  end

  def self.organizations(provider = nil)
    self.client_cache(
      provider,
      Aws::Organizations::Client
    )
  end

  def self.pinpoint(provider = nil)
    self.client_cache(
      provider,
      Aws::Pinpoint::Client
    )
  end
end
