########################################################################
# AwsCloudTrail is the +api_gatewat_rest_api+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/api_gateway_model.html}
########################################################################
class GeoEngineer::Resources::AwsApiGatewayModel < GeoEngineer::Resource

  validate -> { validate_required_attributes([:rest_api_id, :name, :content_type, :schema]) }

end
