require_relative "./helpers"

########################################################################
# AwsApiGatewayResource is the +api_gateway_rest_api+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/api_gateway_resource.html}
########################################################################
class GeoEngineer::Resources::AwsApiGatewayResource < GeoEngineer::Resource
  include GeoEngineer::ApiGatewayHelpers

  # The Rest API resource object and the parent resource object must be passed
  validate -> { validate_required_attributes([:rest_api_id, :parent_id, :path_part]) }

  after :initialize, -> { self.rest_api_id = _rest_api.to_ref }
  after :initialize, -> { _rest_api.api_resources[self._type][self.id] = self }

  # Users get the root resource ('/') as parent by default, but can optionally set
  # it to another resource. This allows for hierarchically organizing API gateway
  # routes by simply setting `parent_id other_resource.to_ref` in your plan.
  after :initialize, -> { self.parent_id ||= _rest_api.to_ref("root_resource_id") }

  after :initialize, -> { depends_on [_rest_api.terraform_name] }

  after :initialize, -> { _geo_id -> { "#{_rest_api._geo_id}::#{path_part}" } }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _id -> { _terraform_id } }

  def to_terraform_state
    tfstate = super
    tfstate[:primary][:attributes] = {
      "rest_api_id" => _rest_api._terraform_id
    }
    tfstate
  end

  def support_tags?
    false
  end

  def self._fetch_remote_resources(provider)
    rest_api_resources = []
    _remote_rest_api_resource(provider) do |rr, res|
      rest_api_resources << res
    end
    rest_api_resources
  end
end
