########################################################################
# AwsKmsAlias is the +aws_kms_alias+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/kms_alias.html}
########################################################################
class GeoEngineer::Resources::AwsKmsAlias < GeoEngineer::Resource
  validate -> { validate_required_attributes([:name, :target_key_id]) }

  validate -> { "'name' must start with 'alias/'" unless name&.start_with?("alias/") }

  after :initialize, -> { _terraform_id -> { name } }

  def to_terraform_state
    tfstate = super
    attributes = { 'id' => name, "name" => name }
    tfstate[:primary][:attributes] = attributes
    tfstate
  end

  def self._fetch_remote_resources(provider)
    AwsClients.kms(provider).list_aliases[:aliases].map(&:to_h).map do |k|
      k[:_terraform_id] = k[:alias_name]
      k[:_geo_id] = k[:alias_name]
      k
    end
  end

  def support_tags?
    false
  end
end
