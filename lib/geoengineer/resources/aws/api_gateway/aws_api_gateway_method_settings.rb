require_relative "./helpers"

########################################################################
# AwsApiGatewayMethodSettings is the +api_gateway_method_settings+ terrform
# resource.
#
# {https://www.terraform.io/docs/providers/aws/r/api_gateway_method_settings.html}
########################################################################
class GeoEngineer::Resources::AwsApiGatewayMethodSettings < GeoEngineer::Resource
  include GeoEngineer::ApiGatewayHelpers

  validate -> {
    validate_required_attributes([
                                   :rest_api_id,
                                   :stage_name,
                                   :method_path,
                                   :settings
                                 ])
  }

  # Must pass the rest_api as _rest_api resource for additional information
  after :initialize, -> { self.rest_api_id = _rest_api.to_ref }
  after :initialize, -> { _rest_api.api_resources[self._type][self.id] = self }

  after :initialize, -> {
    self.stage_name = _stage.to_ref
    if _resource && _method
      self.method_path = "#{_resource.path_part}/#{_method.http_method}"
    end
  }
  after :initialize, -> { depends_on [_rest_api].map(&:terraform_name) }

  after :initialize, -> {
    _geo_id -> {
      "#{_rest_api._geo_id}::#{_stage._geo_id}::#{method_path}"
    }
  }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }

  def to_terraform_state
    tfstate = super
    tfstate[:primary][:attributes] = {
      "rest_api_id" => _rest_api._terraform_id,
      "stage_name"  => stage_name,
      "method_path" => method_path,
      "settings"    => settings
    }
    tfstate
  end

  def support_tags?
    false
  end

  def self._fetch_deployments(provider, rr)
    _client(provider).get_deployments({
                                        rest_api_id: rr[:_terraform_id]
                                      })['items'].map(&:to_h)
  end

  def self._fetch_stage_info(provider, rr, deployment)
    _client(provider).get_stages({
                                   rest_api_id: rr[:_terraform_id],
                                   deployment_id: deployment[:id]
                                 }).item.first.to_h
  end

  def self._fetch_remote_resources(provider)
    _fetch_remote_rest_apis(provider).map do |rr|
      _fetch_deployments(provider, rr).map do |deployment|
        stage_info = _fetch_stage_info(provider, rr, deployment)
        next unless stage_info
        method_settings = stage_info[:method_settings]
        next unless method_settings
        method_settings[:_geo_id] = "#{rr[:_geo_id]}::#{stage_info[:_geo_id]}::#{stage_info[:method_path]}"
        method_settings
      end
    end.flatten.compact
  end
end
