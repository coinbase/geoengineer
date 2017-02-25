########################################################################
# AwsCloudTrail is the +aws_api_gateway_base_path_mapping+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/aws_api_gateway_base_path_mapping.html}
########################################################################
class GeoEngineer::Resources::AwsApiGatewayBasePathMapping < GeoEngineer::Resource
validate -> { validate_required_attributes([:domain_name, :api_id]) }
end
