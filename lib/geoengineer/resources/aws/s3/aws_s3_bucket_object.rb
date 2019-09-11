########################################################################
# AwsS3Bucket is the +aws_s3_bucket_object+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/s3_bucket_object.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsS3BucketObject < GeoEngineer::Resource
  validate -> { validate_required_attributes([:bucket]) }

  after :initialize, -> { _terraform_id -> { "#{bucket}_#{key}" } }

  def to_terraform_state
    tfstate = super
    tfstate[:primary][:attributes] = {
      'bucket' => bucket,
      'key'    => key,
      'source' => source
    }
    tfstate
  end

  def short_type
    's3_object'
  end
end
