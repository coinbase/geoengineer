########################################################################
# GeoEngineer::ApiGatewayHelpers Utility methods for ApiGateway resources
#
########################################################################
module GeoEngineer::ApiGatewayHelpers
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def _remote_rest_apis(provider)
      GeoEngineer::Resources::AwsApiGatewayRestApi.fetch_remote_resources(provider)
    end

    def _remote_rest_resources(provider)
      GeoEngineer::Resources::AwsApiGatewayResource.fetch_remote_resources(provider)
    end
  end
end
