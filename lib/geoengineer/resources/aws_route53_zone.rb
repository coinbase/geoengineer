########################################################################
# AwsRoute53Zone is the +aws_route53_zone+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/route53_zone.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsRoute53Zone < GeoEngineer::Resource
  validate -> { validate_required_attributes([:name]) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { self.name } }

  def self._fetch_remote_resources(provider)
    hosted_zones = AwsClients.route53(provider).list_hosted_zones.hosted_zones.map(&:to_h)

    hosted_zones.map do |zone|
      zone[:_terraform_id] = zone[:id]
      zone[:_geo_id]       = zone[:name]
      zone
    end
  end
end
