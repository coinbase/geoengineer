########################################################################
# AwsVpcEndpoint is the +aws_vpc_endpoint+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/vpc_endpoint.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsVpcEndpoint < GeoEngineer::Resource
  validate -> { validate_required_attributes([:vpc_id, :service_name]) }
  validate -> { validate_has_tag(:Name) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { "#{vpc_id}::#{service_name}::#{NullObject.maybe(tags)[:Name]}" } }

  def self._fetch_remote_resources(provider)
    AwsClients.ec2(provider).describe_vpc_endpoints['vpc_endpoints'].map(&:to_h).map do |endpoint|
      tag_name = endpoint[:tags]&.find { |tag| tag[:key] == 'Name' }&.dig(:value)
      endpoint.merge(
        {
          _terraform_id: endpoint[:vpc_endpoint_id],
          _geo_id: "#{endpoint[:vpc_id]}::#{endpoint[:service_name]}::#{tag_name}"
        }
      )
    end
  end
end
