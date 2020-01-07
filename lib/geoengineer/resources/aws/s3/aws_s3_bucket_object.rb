########################################################################
# AwsS3BucketObject is the +aws_s3_bucket_object+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/s3_bucket_object.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsS3BucketObject < GeoEngineer::Resource
  validate -> { validate_required_attributes([:bucket]) }
  validate -> { validate_required_attributes([:key]) }

  after :initialize, -> { _terraform_id -> { key } }
  after :initialize, -> { _geo_id -> { key } }

  def to_terraform_state
    tfstate = super
    tfstate[:primary][:attributes] = {
      'bucket'       => bucket,
      'key'          => key,
      'acl'          => 'private',
      'content'      => remote_resource.content,
      'content_type' => remote_resource.content_type
    }

    tfstate[:primary][:attributes]['force_destroy'] =
      force_destroy.nil? || force_destroy == '' ? 'false' : force_destroy
    tfstate
  end

  def find_remote_as_individual?
    true
  end

  def remote_resource_params
    resp = AwsClients.s3(provider).get_object({ bucket: bucket, key: key })
    content = resp.body.read
    content_type = resp.content_type
    {
      _terraform_id: key,
      _geo_id: key,
      content: content,
      content_type: content_type
    }
  rescue Aws::S3::Errors::NoSuchKey
    {
      _terraform_id: key,
      _geo_id: key,
      content: nil,
      content_type: nil
    }
  end

  def short_type
    's3_object'
  end
end
