########################################################################
# AwsKeyPair is the +aws_key_pair+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/key_pair.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsKeyPair < GeoEngineer::Resource
  validate -> { validate_required_attributes([:key_name, :public_key]) }

  after :initialize, -> {
    _terraform_id -> { key_name }
    _geo_id       -> { key_name }

    self.lifecycle {} unless self.lifecycle
    self.lifecycle.ignore_changes ||= []
    self.lifecycle.ignore_changes |= ["public_key", "fingerprint"]
  }

  def support_tags?
    false
  end
end
