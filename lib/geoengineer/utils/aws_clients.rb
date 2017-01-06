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

  # Clients

  def self.dynamo
    @aws_dynamo ||= Aws::DynamoDB::Client.new({ stub_responses: stubbed? })
  end

  def self.ec2
    @aws_ec2 ||= Aws::EC2::Client.new({ stub_responses: stubbed? })
  end

  def self.elasticache
    @aws_elasticache ||= Aws::ElastiCache::Client.new({ stub_responses: stubbed? })
  end

  def self.elasticsearch
    @aws_elasticsearch ||= Aws::ElasticsearchService::Client.new({ stub_responses: stubbed? })
  end

  def self.elb
    @aws_elb ||= Aws::ElasticLoadBalancing::Client.new({ stub_responses: stubbed? })
  end

  def self.iam
    @aws_iam ||= Aws::IAM::Client.new({ stub_responses: stubbed? })
  end

  def self.kinesis
    @aws_kinesis ||= Aws::Kinesis::Client.new({ stub_responses: stubbed? })
  end

  def self.lambda
    @aws_lambda ||= Aws::Lambda::Client.new({ stub_responses: stubbed? })
  end

  def self.rds
    @aws_rds ||= Aws::RDS::Client.new({ stub_responses: stubbed? })
  end

  def self.redshift
    @aws_redshift ||= Aws::Redshift::Client.new({ stub_responses: stubbed? })
  end

  def self.route53
    @aws_route53 ||= Aws::Route53::Client.new({ stub_responses: stubbed? })
  end

  def self.s3
    @aws_s3 ||= Aws::S3::Client.new({ stub_responses: stubbed? })
  end

  def self.ses
    @aws_ses ||= Aws::SES::Client.new({ stub_responses: stubbed? })
  end

  def self.sns
    @aws_sns ||= Aws::SNS::Client.new({ stub_responses: stubbed? })
  end

  def self.sqs
    @aws_sqs ||= Aws::SQS::Client.new({ stub_responses: stubbed? })
  end
end
