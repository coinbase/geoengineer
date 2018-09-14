########################################################################
# AwsS3BucketNotification is the +aws_s3_bucket_notification+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/s3_bucket_notification.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsS3BucketNotification < GeoEngineer::Resource
  validate -> { validate_required_attributes([:bucket]) }

  after :initialize, -> { _terraform_id -> { _bucket.bucket } }

  # Setting _bucket
  after :initialize, -> { self.bucket = _bucket.bucket }
  after :initialize, -> { depends_on [_bucket.terraform_name] }

  validate -> {
    validate_subresource_required_attributes(:lambda_function, [:lambda_function_arn, :events])
  }

  validate -> {
    validate_subresource_required_attributes(:queue, [:queue_arn, :events])
  }

  validate -> {
    validate_subresource_required_attributes(:topic, [:topic_arn, :events])
  }

  def support_tags?
    false
  end

  def to_terraform_state
    tfstate = super
    tfstate[:primary][:attributes] = {
      'bucket' => bucket
    }
    tfstate
  end
end
