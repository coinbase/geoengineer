########################################################################
# AwsVpnGatewayAttachment is the +aws_vpn_gateway_attachment+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/vpn_gateway_attachment.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsVpnGatewayAttachment < GeoEngineer::Resource
  validate -> { validate_required_attributes([:vpc_id, :vpn_gateway_id]) }

  after :initialize, -> {
    _terraform_id -> { "vpn-attachment-#{Crc32.hashcode(vpc_id + '-' + vpn_gateway_id)}" }
  }
  after :initialize, -> { _geo_id -> { "#{vpc_id}::#{vpn_gateway_id}" } }

  def to_terraform_state
    tfstate = super
    tfstate[:primary][:attributes] = {
      'vpn_gateway_id' => vpn_gateway_id
    }
    tfstate
  end

  def support_tags?
    false
  end

  def self._fetch_remote_resources(provider)
    AwsClients
      .ec2(provider)
      .describe_vpn_gateways['vpn_gateways']
      .map(&:to_h)
      .reject { |gateway| gateway[:vpc_attachments].empty? }
      .map { |gateway| _generate_attachment(gateway) }
  end

  def self._generate_attachment(gateway)
    # Terraform ID generation via:
    # https://github.com/hashicorp/terraform/blob/master/builtin/providers/aws/resource_aws_vpn_gateway_attachment.go#L209
    vpc_id = gateway[:vpc_attachments].first[:vpc_id]
    id_string = "#{vpc_id}-#{gateway[:vpn_gateway_id]}"
    terraform_id = "vpn-attachment-#{Crc32.hashcode(id_string)}"

    {
      _terraform_id: terraform_id,
      _geo_id: "#{vpc_id}::#{gateway[:vpn_gateway_id]}",
      vpn_gateway_id: gateway[:vpn_gateway_id],
      vpc_id: vpc_id
    }
  end
end
