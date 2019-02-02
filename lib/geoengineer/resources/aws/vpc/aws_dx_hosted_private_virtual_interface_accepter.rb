########################################################################
# AwsDxHostedPrivateVirtualInterfaceAcceptor is the +aws_dx_hosted_private_virtual_interface_accepter+ terrform
# resource.
#
# {https://www.terraform.io/docs/providers/aws/r/dx_hosted_private_virtual_interface_accepter.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsDxHostedPrivateVirtualInterfaceAcceptor < GeoEngineer::Resource
  validate -> { validate_required_attributes([:virtual_interface_id]) }
  validate -> { validate_has_tag(:Name) }

  after :initialize, -> { _terraform_id -> { virtual_interface_id } }
  after :initialize, -> { _geo_id -> { virtual_interface_id } }

  def self._fetch_remote_resources(provider)
    AwsClients.directconnect(provider)
              .describe_virtual_interfaces['virtual_interfaces'].map(&:to_h).map do |connection|
      connection.merge(
        {
          _terraform_id: connection[:virtual_interface_id],
          _geo_id: connection[:virtual_interface_id],
          virtual_interface_id: connection[:virtual_interface_id]
        }
      )
    end
  end
end
