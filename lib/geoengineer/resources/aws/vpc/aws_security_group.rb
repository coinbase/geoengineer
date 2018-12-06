########################################################################
# AwsSecurityGroup is the +aws_security_group+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/security_group.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsSecurityGroup < GeoEngineer::Resource
  validate :validate_correct_cidr_blocks
  validate -> { validate_required_attributes([:name, :description]) }
  validate -> {
    validate_subresource_required_attributes(:ingress, [:from_port, :protocol, :to_port])
  }
  validate -> {
    validate_subresource_required_attributes(:egress, [:from_port, :protocol, :to_port])
  }
  validate -> { validate_has_tag(:Name) }

  before :validation, -> { flatten_cidr_and_sg_blocks }
  before :validation, -> { uniq_cidr_and_sg_blocks }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id       -> { NullObject.maybe(tags)[:Name] } }

  def flatten_cidr_and_sg_blocks
    (self.all_ingress + self.all_egress).each do |in_eg|
      in_eg.cidr_blocks      = in_eg.cidr_blocks.flatten     if in_eg.cidr_blocks
      in_eg.security_groups  = in_eg.security_groups.flatten if in_eg.security_groups
    end
  end

  def uniq_cidr_and_sg_blocks
    (self.all_ingress + self.all_egress).each do |in_eg|
      in_eg.cidr_blocks      = in_eg.cidr_blocks.uniq.sort if in_eg.cidr_blocks
      in_eg.security_groups  = in_eg.security_groups.uniq if in_eg.security_groups
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
