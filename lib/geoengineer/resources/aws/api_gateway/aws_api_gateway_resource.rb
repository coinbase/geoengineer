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
  after :initialize, -> do
    self.parent_id =
      if _parent
        _parent.to_ref
      else
        _rest_api.to_ref("root_resource_id")
      end
  end

  after :initialize, -> { depends_on [_rest_api.terraform_name] }

  after :initialize, -> { depends_on [_parent.terraform_name] if _parent }

  # The geo id for each resource is the geo id of its parent concatenated with the path_part of this
  # resource. If a resource has no parent, then fall back to the geo id of the root API gateway.
  after :initialize, -> {
    _geo_id -> {
      if _parent
        "#{_parent._geo_id}::#{path_part}"
      else
        "#{_rest_api._geo_id}::#{path_part}"
      end
    }
  }

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
