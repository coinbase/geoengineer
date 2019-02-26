########################################################################
# AwsIamBucketPolicy +aws_iam_bucket_policy+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/iam_bucket_policy.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsS3BucketPolicy < GeoEngineer::Resource
  validate -> { validate_required_attributes([:policy, :bucket]) }
  validate -> { validate_policy_length(self.policy) }

  after :initialize, -> {
    _terraform_id -> { bucket }
  }

  def to_terraform_state
    tfstate = super
    attributes = {
      'policy' => policy,
      'bucket' => bucket
    }

    tfstate[:primary][:attributes] = attributes

    tfstate
  end

  def support_tags?
    false
  end

  def _policy_file(path, binding_obj = nil)
    _json_file(:policy, path, binding_obj)
  end

  def self._fetch_remote_resources(provider)
    AwsClients
      .s3(provider)
      .list_buckets
      .buckets
      .map { |bucket| _get_bucket_policy(provider, bucket) }
      .flatten
      .compact
  end

  def self._get_bucket_policy(provider, bucket)
    AwsClients
      .s3(provider)
      .get_bucket_policy({ bucket: bucket.name.to_s })
      .to_h
      .merge({ _terraform_id: bucket.name })
  rescue Aws::S3::Errors::NoSuchBucketPolicy
    nil
  end
end
