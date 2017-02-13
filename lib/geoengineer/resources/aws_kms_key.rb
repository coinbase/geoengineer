########################################################################
# AwsKmsKey is the +aws_kms_key+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/kms_key.html}
########################################################################
class GeoEngineer::Resources::AwsKmsKey < GeoEngineer::Resource
  validate -> { validate_required_attributes([:description]) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { description } }

  def self._fetch_remote_resources
    keys = AwsClients.kms.list_keys[:keys].map do |i|
      AwsClients.kms.describe_key({ key_id: i.key_id }).key_metadata.to_h
    end

    keys.map do |k|
      k[:_terraform_id] = k[:key_id]
      k[:_geo_id] = k[:description]
      k
    end
  end

  def support_tags?
    false
  end
end
