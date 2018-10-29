########################################################################
# AwsVpcIpv4CidrBlockAssociation is the +aws_vpc_ipv4_cidr_block_association+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/vpc_ipv4_cidr_block_association.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsVpcIpv4CidrBlockAssociation < GeoEngineer::Resource
  validate -> { validate_required_attributes([:vpc_id, :cidr_block]) }
  validate -> { validate_cidr_block(self.cidr_block) if self.cidr_block }
  validate -> {
    if self.vpc_id.is_a?(GeoEngineer::Resource)
      primary_cidr = self.vpc_id.cidr_block
      validate_cidr_restrictions(primary_cidr, self.cidr_block) if self.cidr_block && primary_cidr
    end
  }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { "#{_vpc_id}::#{cidr_block}" } }

  def _vpc_id
    self.vpc_id && self.vpc_id.is_a?(GeoEngineer::Resource) ? self.vpc_id._terraform_id : self.vpc_id
  end

  def cidr(range)
    NetAddr::CIDR.create(range)
  end

  def range_size(errors, additional_cidr)
    msg = "The allowed block size is between a /28 netmask and /16 netmask."
    errors << err_msg(msg) if additional_cidr.bits < 16 || additional_cidr.bits > 28
  end

  def single_restricted_range(errors, primary_cidr, additional_cidr)
    restricted_ranges = [cidr("10.0.0.0/8"),
                         cidr("172.16.0.0/12"),
                         cidr("192.168.0.0/16"),
                         cidr("198.19.0.0/16")]
    remaining_restricted_ranges = restricted_ranges.reject { |r| r.contains?(primary_cidr) }

    remaining_restricted_ranges.each do |r|
      if r.contains?(additional_cidr)
        errors << err_msg("Primary VPC range [#{primary_cidr}] Cannot add additional CIDR blocks from the restricted "\
          "ranges [ #{remaining_restricted_ranges.join(', ')} ]")
      end
    end
  end

  def no_overlap(errors, primary_cidr, additional_cidr)
    msg = "The additional CIDR cannot overlap the primary VPC range"
    errors << err_msg(msg) if primary_cidr.contains?(additional_cidr)
  end

  def special_ranges(errors, primary_cidr, additional_cidr)
    rule1 = cidr("10.0.0.0/15").contains?(primary_cidr) && cidr("10.0.0.0/16").contains?(additional_cidr)
    msg1 = "primary CIDR in 10.0.0.0/15. cannot add a CIDR block from the 10.0.0.0/16 range."
    errors << err_msg(msg1) if rule1

    rule2 = cidr("172.16.0.0/12").contains?(primary_cidr) && cidr("172.31.0.0/16").contains?(additional_cidr)
    msg2 = "primary CIDR in 172.16.0.0/12. cannot add a CIDR block from the 172.31.0.0/16 range"
    errors << err_msg(msg2) if rule2
  end

  def err_msg(msg)
    link = "https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html#add-cidr-block-restrictions"
    "#{for_resource} : #{msg} See #{link} for more info."
  end

  def validate_cidr_restrictions(primary, cidr_block)
    errors = []
    begin
      primary_cidr = cidr(primary)
    rescue NetAddr::ValidationError
      return errors
    end
    additional_cidr = cidr(cidr_block)

    range_size(errors, additional_cidr)

    no_overlap(errors, primary_cidr, additional_cidr)

    return errors if cidr("100.64.0.0/10").contains?(additional_cidr)

    single_restricted_range(errors, primary_cidr, additional_cidr)

    special_ranges(errors, primary_cidr, additional_cidr)

    errors
  end

  def to_terraform_state
    tfstate = super
    tfstate[:primary][:attributes] = {
      'vpc_id' => vpc_id,
      'cidr_block' => cidr_block
    }
    tfstate
  end

  def support_tags?
    false
  end

  def self._fetch_remote_resources(provider)
    AwsClients.ec2(provider)
              .describe_vpcs['vpcs']
              .map(&:to_h)
              .flat_map do |vpc|
      vpc[:cidr_block_association_set].map do |cidr_assoc|
        {
          vpc_id: vpc[:vpc_id],
          cidr_block: cidr_assoc[:cidr_block],
          _geo_id: "#{vpc[:vpc_id]}::#{cidr_assoc[:cidr_block]}",
          _terraform_id: cidr_assoc[:association_id]
        }
      end
    end
  end
end
