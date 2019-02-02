########################################################################
# AwsDxLag is the +aws_dx_lag+ terrform resource.
#
# {https://www.terraform.io/docs/providers/aws/r/dx_lag.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsDxLag < GeoEngineer::Resource
  validate -> { validate_required_attributes([:name, :connections_bandwidth, :location]) }
  validate -> { validate_has_tag(:Name) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { name } }

  def self._fetch_remote_resources(provider)
    AwsClients.directconnect(provider).describe_lags['lags'].map(&:to_h).map do |lag|
      {
        _terraform_id: lag[:lag_id],
        _geo_id: lag[:lag_name],
        name: lag[:lag_name]
      }
    end
  end
end
