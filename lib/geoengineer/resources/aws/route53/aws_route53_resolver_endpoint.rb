########################################################################
# AwsRoute53ResolverEndpoint is the +aws_route53_resolver_endpoint+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/route53_resolver_endpoint.html Terraform Docs}
########################################################################

class GeoEngineer::Resources::AwsRoute53ResolverEndpoint < GeoEngineer::Resource
    validate -> { validate_required_attributes([:name, :direction, :ip_address, :security_group_ids]) }
   
    after :initialize, -> { _terraform_id -> { name } }
    after :initialize, -> { _geo_id -> { name } }
    
    def support_tags?
      true
    end

    def self._fetch_remote_resources(provider)
      AwsClients.route53resolver(provider)
                .list_resolver_endpoints
                .map(&:to_h).map do |resolver|
        resolver.merge(
          {
            _terraform_id: resolver["Name"],
            _geo_id: resolver["Name"]
          }
        )
      end
  end

  end
