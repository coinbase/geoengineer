########################################################################
# AwsDxHostedPrivateVirtualInterface is the +aws_dx_hosted_private_virtual_interface+ terrform resource.
#
# {https://www.terraform.io/docs/providers/aws/r/dx_hosted_private_virtual_interface.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsDxHostedPrivateVirtualInterface < GeoEngineer::Resource
  validate -> {
    validate_required_attributes([:address_family, :bgp_asn, :connection_id, :name, :vlan, :owner_account_id])
  }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { name } }

  def support_tags?
    false
  end

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
