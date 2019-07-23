########################################################################
# AwsMskConfiguration is the +aws_msk_configuration+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/msk_configuration.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsMskConfiguration < GeoEngineer::Resource
  validate -> { validate_required_attributes([:server_properties, :kafka_versions, :name]) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { self[:name] } }

  def support_tags?
    false
  end

  def self._fetch_remote_resources(provider)
    AwsClients.kafka(provider).list_configurations['configurations'].map { |msk_config|
      {
        name: msk_config[:name],
        _terraform_id: msk_config[:arn],
        _geo_id: msk_config[:name]
      }
    }
  end
end
