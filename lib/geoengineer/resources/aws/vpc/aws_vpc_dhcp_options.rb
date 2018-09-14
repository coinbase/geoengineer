########################################################################
# AwsVpcDhcpOptions is the +aws_vpc_dhcp_options+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/vpc_dhcp_options.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsVpcDhcpOptions < GeoEngineer::Resource
  validate -> { validate_has_tag(:Name) }
  validate -> {
    validate_at_least_one_present(
      %i[
        domain_name domain_name_servers ntp_servers netbios_name_servers netbios_node_type
      ]
    )
  }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { NullObject.maybe(tags)[:Name] } }

  def self._fetch_remote_resources(provider)
    AwsClients.ec2(provider).describe_dhcp_options['dhcp_options'].map(&:to_h).map do |options|
      options.merge(
        {
          _terraform_id: options[:dhcp_options_id],
          _geo_id: options[:tags]&.find { |tag| tag[:key] == "Name" }&.dig(:value)
        }
      )
    end
  end
end
