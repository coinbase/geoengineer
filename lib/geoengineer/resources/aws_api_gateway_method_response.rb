########################################################################
# AwsCloudTrail is the +api_gatewat_rest_api+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/api_gateway_method_response.html}
########################################################################
class GeoEngineer::Resources::AwsApiGatewayMethodResponse < GeoEngineer::Resource

  validate -> { validate_required_attributes([
                  :rest_api_id,
                  :resource_id,
                  :http_method,
                  :status_code
              ]) }

end
