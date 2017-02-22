########################################################################
# AwsS3Bucket is the +aws_s3_bucket+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/s3_bucket.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsS3Bucket < GeoEngineer::Resource
  validate -> { validate_required_attributes([:bucket]) }
  validate :validate_policy_json

  after  :initialize, -> { _terraform_id -> { bucket } }
  before :validation, -> {
    # AWS/Terraform reorganises and adds information to the policy that affects it
    # This adds that information to ensure unnecessary change
    if policy && validate_policy_json.nil?
      old_policy = self.policy
      policy_hash = JSON.parse(old_policy)
      # First each statement must have Sid
      (policy_hash["Statement"] || []).each { |s| s["Sid"] = s["Sid"] || "" }

      self.policy = policy_hash.to_json
    end
  }

  def validate_policy_json
    return unless policy
    JSON.parse(policy)
    return nil
  rescue JSON::ParserError
    return "Error: policy #{for_resource} invalid JSON"
  end

  def to_terraform_state
    tfstate = super
    tfstate[:primary][:attributes] = {
      'acl' => (acl || 'private'),
      'force_destroy' => (force_destroy || 'false'),
      'policy' => policy
    }
    tfstate
  end

  def short_type
    "s3"
  end

  def self._fetch_remote_resources(provider)
    AwsClients.s3(provider).list_buckets[:buckets].map(&:to_h).map do |s3b|
      s3b[:_terraform_id] = s3b[:name]
      s3b[:_geo_id] = s3b[:name]
      s3b[:bucket]  = s3b[:name]
      s3b
    end
  end
end
