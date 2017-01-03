########################################################################
# AwsNetworkAclRule is the +aws_network_acl_rule+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/network_acl_rule.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsNetworkAclRule < GeoEngineer::Resource
  validate -> {
    validate_required_attributes(
      [:network_acl_id, :rule_number, :protocol, :rule_action, :cidr_block]
    )
  }

  after :initialize, -> {
    _terraform_id -> {
      terraform_id_components = [
        "#{network_acl_id}-",
        "#{rule_number}-",
        "#{egress}-",
        "#{self.class._number_for_protocol(protocol)}-"
      ]
      "nacl-#{Crc32.hashcode(terraform_id_components.join)}"
    }
  }

  def to_terraform_state
    tfstate = super
    tfstate[:primary][:attributes] = {
      'network_acl_id' => network_acl_id,
      'rule_number' => rule_number,
      'egress' => egress
    }
    tfstate
  end

  def support_tags?
    false
  end

  def self._fetch_remote_resources
    AwsClients
      .ec2
      .describe_network_acls['network_acls']
      .map(&:to_h)
      .select { |network_acl| !network_acl[:entries].empty? }
      .map { |network_acl| _generate_rules(network_acl) }
      .flatten
  end

  def self._generate_rules(network_acl)
    network_acl[:entries].map do |rule|
      terraform_id_components = [
        "#{network_acl[:network_acl_id]}-",
        "#{rule[:rule_number]}-",
        "#{rule[:egress]}-",
        "#{_number_for_protocol(rule[:protocol])}-"
      ]
      rule.merge({ _terraform_id: "nacl-#{Crc32.hashcode(terraform_id_components.join)}" })
    end
  end

  def self._number_for_protocol(protocol)
    protocols = {
      ah: 51,
      esp: 50,
      udp: 17,
      tcp: 6,
      icmp: 1,
      all: -1
    }
    return unless protocol
    return protocol if protocols.values.map(&:to_s).include?(protocol.to_s)
    protocols[protocol.to_s.downcase.to_sym]
  end
end
