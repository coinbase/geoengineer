########################################################################
# AwsVpcEndpoint is the +aws_vpc_endpoint+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/vpc_endpoint.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsVpcEndpoint < GeoEngineer::Resource
  validate -> { validate_required_attributes([:vpc_id, :service_name]) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { "#{vpc_id}::#{service_name}" } }

  def self._fetch_remote_resources
    AwsClients.ec2.describe_vpc_endpoints['vpc_endpoints'].map(&:to_h).map do |endpoint|
      endpoint.merge(
        {
          _terraform_id: endpoint[:vpc_endpoint_id],
          _geo_id: "#{endpoint[:vpc_id]}::#{endpoint[:service_name]}"
        }
      )
    end
  end
end
