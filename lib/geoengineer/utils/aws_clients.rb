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

  def self.client_cache(client_name, provider, client)
    @client_cache ||= {}
    key = "#{client_name}_" + (provider&.terraform_id || GeoEngineer::Resource::DEFAULT_PROVIDER)
    @client_cache[key] ||= client
  end

  # Clients
  def self.cloudwatch(provider = nil)
    self.client_cache(
      'cloudwatch',
      provider,
      Aws::CloudWatch::Client.new(client_params(provider))
    )
  end

  def self.cloudwatchevents(provider = nil)
    self.client_cache(
      'cloudwatchevents',
      provider,
      Aws::CloudWatchEvents::Client.new(client_params(provider))
    )
  end

  def self.dynamo(provider = nil)
    self.client_cache(
      'dynamo',
      provider,
      Aws::DynamoDB::Client.new(client_params(provider))
    )
  end

  def self.ec2(provider = nil)
    self.client_cache(
      'ec2',
      provider,
      Aws::EC2::Client.new(client_params(provider))
    )
  end

  def self.elasticache(provider = nil)
    self.client_cache(
      'elasticache',
      provider,
      Aws::ElastiCache::Client.new(client_params(provider))
    )
  end

  def self.elasticsearch(provider = nil)
    self.client_cache(
      'elasticsearch',
      provider,
      Aws::ElasticsearchService::Client.new(client_params(provider))
    )
  end

  def self.elb(provider = nil)
    self.client_cache(
      'elb',
      provider,
      Aws::ElasticLoadBalancing::Client.new(client_params(provider))
    )
  end

  def self.iam(provider = nil)
    self.client_cache(
      'iam',
      provider,
      Aws::IAM::Client.new(client_params(provider))
    )
  end

  def self.kinesis(provider = nil)
    self.client_cache(
      'kinesis',
      provider,
      Aws::Kinesis::Client.new(client_params(provider))
    )
  end

  def self.lambda(provider = nil)
    self.client_cache(
      'lambda',
      provider,
      Aws::Lambda::Client.new(client_params(provider))
    )
  end

  def self.rds(provider = nil)
    self.client_cache(
      'rds',
      provider,
      Aws::RDS::Client.new(client_params(provider))
    )
  end

  def self.redshift(provider = nil)
    self.client_cache(
      'redshift',
      provider,
      Aws::Redshift::Client.new(client_params(provider))
    )
  end

  def self.route53(provider = nil)
    self.client_cache(
      'route53',
      provider,
      Aws::Route53::Client.new(client_params(provider))
    )
  end

  def self.s3(provider = nil)
    self.client_cache(
      's3',
      provider,
      Aws::S3::Client.new(client_params(provider))
    )
  end

  def self.ses(provider = nil)
    self.client_cache(
      'ses',
      provider,
      Aws::SES::Client.new(client_params(provider))
    )
  end

  def self.sns(provider = nil)
    self.client_cache(
      'sns',
      provider,
      Aws::SNS::Client.new(client_params(provider))
    )
  end

  def self.sqs(provider = nil)
    self.client_cache(
      'sqs',
      provider,
      Aws::SQS::Client.new(client_params(provider))
    )
  end

  def self.cloudtrail(provider = nil)
    self.client_cache(
      'cloudtrail',
      provider,
      Aws::CloudTrail::Client.new(client_params(provider))
    )
  end

  def self.kms(provider = nil)
    self.client_cache(
      'kms',
      provider,
      Aws::KMS::Client.new(client_params(provider))
    )
  end
end
