########################################################################
# AwsCloudTrail is the +api_gatewat_rest_api+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/api_gateway_rest_api.html}
########################################################################
class GeoEngineer::Resources::AwsApiGatewayRestApi < GeoEngineer::Resource
  validate -> { validate_required_attributes([:name]) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { name } }
  after :initialize, -> { _id -> { _terraform_id } }

  def support_tags?
    false
  end

  def self._fetch_remote_resources(provider)
    AwsClients.api_gateway(provider).get_rest_apis['items'].map(&:to_h).map do |api|
      api[:_terraform_id] = api[:id]
      api[:_geo_id]       = api[:name]
      api
    end
  end
end
