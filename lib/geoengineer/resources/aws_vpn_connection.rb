########################################################################
# AwsVpnConnection is the +aws_vpn_connection+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/vpn_connection.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsVpnConnection < GeoEngineer::Resource
  validate -> { validate_required_attributes([:customer_gateway_id, :vpn_gateway_id, :type]) }
  validate -> { validate_has_tag(:Name) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { NullObject.maybe(tags)[:Name] } }

  def self._fetch_remote_resources(provider)
    AwsClients
      .ec2(provider)
      .describe_vpn_connections['vpn_connections']
      .reject { |connection| connection['state'] == 'deleted' } # Necessary for development
      .map(&:to_h)
      .map do |connection|
        connection.merge(
          {
            _terraform_id: connection[:vpn_connection_id],
            _geo_id: connection[:tags].find { |tag| tag[:key] == "Name" }&.dig(:value)
          }
        )
      end
  end
end
