########################################################################
# AwsSecurityGroup is the +aws_security_group+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/security_group.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsSecurityGroup < GeoEngineer::Resource
  validate :validate_correct_cidr_blocks
  validate :validate_rules_have_src_dest
  validate -> { validate_required_attributes([:name, :description]) }
  validate -> {
    validate_subresource_required_attributes(:ingress, [:from_port, :protocol, :to_port])
  }
  validate -> {
    validate_subresource_required_attributes(:egress, [:from_port, :protocol, :to_port])
  }
  validate -> {
    all_ingress.map do |i|
      if i.protocol.to_s == '-1' && !(i.to_port.to_s == '0' && i.from_port.to_s == '0')
        'Cannot specify protocol of -1 with a port number other than 0 ' \
        "(to_port = #{i.to_port} from_port = #{i.from_port})"
      end
    end
  }
  validate -> { validate_has_tag(:Name) }

  before :validation, -> { flatten_cidr_and_sg_blocks }
  before :validation, -> { uniq_cidr_and_sg_blocks }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id       -> { NullObject.maybe(tags)[:Name] } }

  def to_terraform_state
    tfstate = super

    egress_ingress = {
      "egress.#": all_egress.length.to_s,
      "ingress.#": all_ingress.length.to_s
    }

    c = 0
    all_egress.each do |e|
      c += 1
      add_egress_ingress_to_state(egress_ingress, "egress.#{c}", e, e.cidr_blocks || [], e.security_groups || [])
    end

    all_ingress.each do |e|
      c += 1
      add_egress_ingress_to_state(egress_ingress, "ingress.#{c}", e, e.cidr_blocks || [], e.security_groups || [])
    end

    tfstate[:primary][:attributes] = egress_ingress
    tfstate
  end

  def add_egress_ingress_to_state(egress_ingress, prefix, e, cb, sg)
    egress_ingress.merge!({
                            "#{prefix}.from_port" => e.from_port.to_s,
                            "#{prefix}.to_port" => e.to_port.to_s,
                            "#{prefix}.protocol" => e.protocol.to_s,
                            "#{prefix}.self" => e["self"].to_s,
                            "#{prefix}.cidr_blocks.#" => cb.length.to_s,
                            "#{prefix}.security_groups.#" => sg.length.to_s
                          })

    add_list_to_state(egress_ingress, prefix, cb, "cidr_blocks")
    add_list_to_state(egress_ingress, prefix, sg, "security_groups")
  end

  def add_list_to_state(egress_ingress, prefix, list, list_type)
    list.each_with_index do |r, i|
      egress_ingress["#{prefix}.#{list_type}.#{i}"] = r.to_s
    end
  end

  def flatten_cidr_and_sg_blocks
    (self.all_ingress + self.all_egress).each do |in_eg|
      in_eg.cidr_blocks      = in_eg.cidr_blocks.flatten      if in_eg.cidr_blocks
      in_eg.ipv6_cidr_blocks = in_eg.ipv6_cidr_blocks.flatten if in_eg.ipv6_cidr_blocks
      in_eg.security_groups  = in_eg.security_groups.flatten  if in_eg.security_groups
      in_eg.prefix_list_ids  = in_eg.prefix_list_ids.flatten  if in_eg.prefix_list_ids
    end
  end

  def uniq_cidr_and_sg_blocks
    (self.all_ingress + self.all_egress).each do |in_eg|
      in_eg.cidr_blocks      = in_eg.cidr_blocks.uniq.sort      if in_eg.cidr_blocks
      in_eg.ipv6_cidr_blocks = in_eg.ipv6_cidr_blocks.uniq.sort if in_eg.ipv6_cidr_blocks
      in_eg.security_groups  = in_eg.security_groups.uniq       if in_eg.security_groups
      in_eg.prefix_list_ids  = in_eg.prefix_list_ids.uniq       if in_eg.prefix_list_ids
    end
  end

  def validate_correct_cidr_blocks
    errors = []
    (self.all_ingress + self.all_egress).each do |in_eg|
      next unless in_eg.cidr_blocks
      in_eg.cidr_blocks.each do |cidr|
        error = validate_cidr_block(cidr)
        errors << error unless error.nil?
      end
    end
    errors
  end

  def validate_rules_have_src_dest
    errors = []

    self.all_ingress.map do |i|
      src_count = 0
      src_count += i.cidr_blocks.length      if i.cidr_blocks
      src_count += i.ipv6_cidr_blocks.length if i.ipv6_cidr_blocks
      src_count += i.security_groups.length  if i.security_groups
      src_count += i.prefix_list_ids.length  if i.prefix_list_ids
      src_count += 1                         if i['self'] == true

      if src_count.zero?
        errors << 'Security group ingress rules must specify at least one source ' \
        '(cidr_blocks, ipv6_cidr_blocks, prefix_list_ids, security_groups, or self)'
      end
    end

    self.all_egress.map do |e|
      dst_count = 0
      dst_count += e.cidr_blocks.length      if e.cidr_blocks
      dst_count += e.ipv6_cidr_blocks.length if e.ipv6_cidr_blocks
      dst_count += e.security_groups.length  if e.security_groups
      dst_count += e.prefix_list_ids.length  if e.prefix_list_ids
      dst_count += 1                         if e['self'] == true

      if dst_count.zero?
        errors << 'Security group egress rules must specify at least one destination ' \
        '(cidr_blocks, ipv6_cidr_blocks, prefix_list_ids, security_groups, or self)'
      end
    end

    errors
  end

  def short_type
    "sg"
  end

  def self._fetch_remote_resources(provider)
    AwsClients.ec2(provider).describe_security_groups['security_groups'].map(&:to_h).map do |sg|
      sg.merge(
        {
          name: sg[:group_name],
          _terraform_id: sg[:group_id],
          _geo_id: sg[:tags]&.find { |tag| tag[:key] == "Name" }&.dig(:value)
        }
      )
    end
  end
end
