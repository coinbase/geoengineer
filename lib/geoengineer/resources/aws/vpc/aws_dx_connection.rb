########################################################################
# AwsDxConnection is the +aws_dx_connection+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/dx_connection.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsDxConnection < GeoEngineer::Resource
  validate -> { validate_required_attributes([:name, :bandwidth, :location]) }
  validate -> { validate_has_tag(:Name) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { name } }

  def self._fetch_remote_resources(provider)
    AwsClients.directconnect(provider)
              .describe_connections['connections'].map(&:to_h).map do |connection|
      connection.merge(
        {
          _terraform_id: connection[:connection_id],
          _geo_id: connection[:connection_name]
        }
      )
    end
  end
end
