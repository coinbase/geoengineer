########################################################################
# AwsDxPrivateVirtualInterface is the +aws_dx_private_virtual_interface+ terrform resource.
#
# {https://www.terraform.io/docs/providers/aws/r/dx_private_virtual_interface.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsDxPrivateVirtualInterface < GeoEngineer::Resource
  validate -> { validate_required_attributes([:address_family, :bgp_asn, :connection_id, :name, :vlan]) }
  validate -> { validate_has_tag(:Name) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { name } }

  def self._fetch_remote_resources(provider)
    AwsClients.directconnect(provider)
              .describe_virtual_interfaces['virtual_interfaces'].map(&:to_h).map do |connection|
      connection.merge(
        {
          _terraform_id: connection[:virtual_interface_id],
          _geo_id: connection[:virtual_interface_name],
          name: connection[:virtual_interface_name]
        }
      )
    end
  end
end
