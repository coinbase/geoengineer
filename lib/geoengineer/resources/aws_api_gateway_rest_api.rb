########################################################################
# AwsCloudTrail is the +api_gatewat_rest_api+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/api_gateway_rest_api.html}
########################################################################
class GeoEngineer::Resources::AwsApiGatewayRestApi < GeoEngineer::Resource
  include GeoEngineer::ApiGatewayHelpers

  validate -> { validate_required_attributes([:name]) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { name } }

  def support_tags?
    false
  end

  def root_resource_id
    NullObject.maybe(remote_resource).root_resource_id
  end

  def to_terraform_state
    tfstate = super
    tfstate[:primary][:attributes] = {
      "root_resource_id" => root_resource_id
    }
    tfstate
  end

  # This method will tag for deletion all remote resources that are not codeified
  def delete_uncodified_children_resoures
  end

  def self._fetch_remote_resources(provider)
    AwsClients.api_gateway(provider).get_rest_apis['items'].map(&:to_h).map do |api|
      api[:_terraform_id]    = api[:id]
      api[:_geo_id]          = api[:name]
      api[:root_resource_id] = _fetch_root_resource_id(provider, api)
      api
    end
  end

  def self._fetch_root_resource_id(provider, api)
    AwsClients.api_gateway(provider).get_resources({ rest_api_id: api[:id] })['items'].map do |res|
      return res.id if res.path == '/'
    end
    return nil
  end

end
