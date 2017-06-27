########################################################################
# AwsCustomerGateway is the +aws_customer_gateway+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/customer_gateway.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsCustomerGateway < GeoEngineer::Resource
  validate -> { validate_required_attributes([:bgp_asn, :ip_address, :type]) }
  validate -> { validate_has_tag(:Name) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { NullObject.maybe(tags)[:Name] } }

  def gateway_type(val=nil)
    val ? self["type"] = val : self["type"]
  end

  def self._fetch_remote_resources(provider)
    AwsClients.ec2(provider)
              .describe_customer_gateways['customer_gateways']
              .map(&:to_h).map do |gateway|
      gateway.merge(
        {
          _terraform_id: gateway[:customer_gateway_id],
          _geo_id: gateway[:tags]&.find { |tag| tag[:key] == "Name" }&.dig(:value)
        }
      )
    end
  end
end
