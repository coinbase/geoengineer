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
    client_params
  end

  def self.client_cache(provider, client)
    @client_cache ||= {}
    key = "#{client.name}_" + (provider&.terraform_id || GeoEngineer::Resource::DEFAULT_PROVIDER)
    @client_cache[key] ||= client.new(client_params(provider))
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

  def self.kinesis(provider = nil)
    self.client_cache(
      provider,
      Aws::Kinesis::Client
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
end
