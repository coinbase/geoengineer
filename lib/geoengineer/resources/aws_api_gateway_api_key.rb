########################################################################
# AwsCloudTrail is the +aws_api_gateway_api_key+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/aws_api_gateway_api_key.html}
########################################################################
class GeoEngineer::Resources::AwsApiGatewayApiKey < GeoEngineer::Resource
  validate -> { validate_required_attributes([:name]) }
end
