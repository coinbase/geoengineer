########################################################################
# AwsRoute53ResolverEndpoint is the +aws_route53_resolver_endpoint+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/route53_resolver_endpoint.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsRoute53ResolverEndpoint < GeoEngineer::Resource
  validate -> { validate_required_attributes([:name, :direction, :ip_address, :security_group_ids]) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { NullObject.maybe(tags)[:Name] } }

  def self._fetch_remote_resources(provider)
    AwsClients.route53resolver(provider)
              .list_resolver_endpoints[:resolver_endpoints]
              .map(&:to_h).map do |resolver|
      resolver.merge(
        {
          _terraform_id: resolver[:id],
          _geo_id: resolver[:name]
        }
      )
    end
  end
end
