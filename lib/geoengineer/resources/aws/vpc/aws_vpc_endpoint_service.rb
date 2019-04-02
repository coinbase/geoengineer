########################################################################
# AwsVpcEndpointService is the +aws_vpc_endpoint_service+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/vpc_endpoint_service.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsVpcEndpointService < GeoEngineer::Resource
  validate -> { validate_required_attributes([:network_load_balancer_arns, :acceptance_required]) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { network_load_balancer_arns&.sort&.join('+') } }

  def support_tags?
    false
  end

  def self._fetch_remote_resources(provider)
    AwsClients.ec2(provider)
              .describe_vpc_endpoint_service_configurations
              .service_configurations
              .map(&:to_h)
              .map do |configuration|
      configuration.merge(
        {
          _terraform_id: configuration[:service_id],
          _geo_id: configuration[:network_load_balancer_arns].sort.join('+')
        }
      )
    end
  end
end
