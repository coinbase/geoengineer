require_relative "./helpers"

########################################################################
# AwsCloudTrail is the +api_gatewat_rest_api+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/api_gateway_rest_api.html}
########################################################################
class GeoEngineer::Resources::AwsApiGatewayRestApi < GeoEngineer::Resource
  include GeoEngineer::ApiGatewayHelpers

  # Validations
  validate -> { validate_required_attributes([:name]) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { name } }

  # API Resource Methods
  attr_accessor :api_resources
  after :initialize, :initialize_children_resources

  def initialize_children_resources
    # { <class_name> : { <resource_id> : <resource>}
    @api_resources = {
      "aws_api_gateway_authorizer" => {},
      "aws_api_gateway_base_path_mapping" => {},
      "aws_api_gateway_deployment" => {},
      "aws_api_gateway_integration" => {},
      "aws_api_gateway_integration_response" => {},
      "aws_api_gateway_method" => {},
      "aws_api_gateway_method_response" => {},
      "aws_api_gateway_method_settings" => {},
      "aws_api_gateway_model" => {},
      "aws_api_gateway_resource" => {}
    }
  end

  def all_api_resources
    [self, @api_resources.values.map(&:values)].flatten
  end

  def all_core_api_resources
    [
      self,
      @api_resources["aws_api_gateway_integration"].values,
      @api_resources["aws_api_gateway_integration_response"].values,
      @api_resources["aws_api_gateway_method"].values,
      @api_resources["aws_api_gateway_method_response"].values,
      @api_resources["aws_api_gateway_model"].values,
      @api_resources["aws_api_gateway_resource"].values
    ].flatten
  end

  # End of API Resource Methods
  def support_tags?
    false
  end

  def root_resource_id
    NullObject.maybe(remote_resource).root_resource_id
  end

  def _policy_file(path, binding_obj = nil)
    _json_file(:policy, path, binding_obj)
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
    # Find all remote resources for this rest_api
    # Compare with api_resources hash
    # create resource in project tagged with deletion (this will only add them to tfstate)
  end

  def self._fetch_remote_resources(provider)
    _fetch_remote_rest_apis(provider)
  end
end
