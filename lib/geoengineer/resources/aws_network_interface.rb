########################################################################
# AwsNetworkInterface is the +aws_network_interface+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/network_interface.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsNetworkInterface < GeoEngineer::Resource
  validate -> { validate_required_attributes([:subnet_id]) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id       -> { Array(private_ips).join(',') } }

  def self._fetch_remote_resources(provider)
    interfaces = AwsClients.ec2(provider).describe_network_interfaces

    interfaces['network_interfaces'].map(&:to_h).map do |interface|
      addresses = interface[:private_ip_addresses].collect { |a| a[:private_ip_address] }
      interface[:_terraform_id] = interface[:network_interface_id]
      interface[:_geo_id] = addresses.join(',')
      interface
    end
  end
end
