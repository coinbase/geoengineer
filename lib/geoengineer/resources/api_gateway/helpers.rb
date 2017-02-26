########################################################################
# GeoEngineer::ApiGatewayHelpers Utility methods for ApiGateway resources
#
########################################################################
module GeoEngineer::ApiGatewayHelpers
  def _remote_rest_apis
    GeoEngineer::Resources::AwsApiGatewayRestApi.fetch_remote_resources
  end
end
