########################################################################
# AwsRoute53ResolverEndpoint is the +aws_route53_resolver_endpoint+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/route53_resolver_endpoint.html Terraform Docs}
########################################################################

class GeoEngineer::Resources::AwsRoute53ResolverEndpoint < GeoEngineer::Resource
    validate -> { validate_required_attributes([:name, :direction, :ip_addresses, :security_group_ids]) }
   
    after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
    #after :initialize, -> { _geo_id -> { "#{direction}_#{self.name&.downcase}_#{record_type}" } }
    after :initialize, -> { name }

    
    def to_terraform_state
      tfstate = super
      #tfstate[:primary][:attributes] = {
      #'id' => _terraform_id,
      #'direction' => direction,
      #'ip_addresses' => ip_addresses,
      #  'security_group_ids' => security_group_ids,
      #  'allow_overwrite' => 'true'
      #}
      #tfstate
    end
  
    def record_direction
      self["direction"].upcase
    end
  
    def support_tags?
      true
    end
  end
