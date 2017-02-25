########################################################################
# AwsCloudTrail is the +aws_api_gateway_authorizer+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/aws_api_gateway_authorizer.html}
########################################################################
class GeoEngineer::Resources::AwsApiGatewayauthorizer < GeoEngineer::Resource
validate -> { validate_required_attributes([:authorizer_uri, :name, :rest_api_id]) }
end
