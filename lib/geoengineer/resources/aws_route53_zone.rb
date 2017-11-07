########################################################################
# AwsRoute53Zone is the +aws_route53_zone+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/route53_zone.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsRoute53Zone < GeoEngineer::Resource
  validate -> { validate_required_attributes([:name]) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { "#{self._public_or_private}-#{self.name}." } }

  def _public_or_private
    self.vpc_id.nil? ? 'public' : self.vpc_id
  end

  def to_terraform_state
    tfstate = super
    tfstate[:primary][:attributes] = {
      'name' => name,
      'vpc_id' => vpc_id,
      'force_destroy' => (force_destroy || 'false')
    }
    tfstate
  end

  def self._fetch_remote_resources(provider)
    _fetch_zones(provider).map { |zone| _generate_remote_zone(provider, zone) }
  end

  def self._fetch_zones(provider)
    AwsClients.route53(provider).list_hosted_zones.hosted_zones.map(&:to_h)
  end

  def self._generate_remote_zone(provider, zone)
    is_private_zone = zone.dig(:config, :private_zone) || false

    zone[:id] = zone[:id].gsub(%r{^/hostedzone/}, '')
    zone[:zone_id]       = zone[:id]
    zone[:_terraform_id] = zone[:id]
    zone[:vpc_id]        = _get_zone_vpc_id(provider, zone[:id]) if is_private_zone
    zone[:_geo_id]       = "#{is_private_zone ? zone[:vpc_id] : 'public'}-#{zone[:name]}"
    zone
  end

  def self._get_zone_vpc_id(provider, zone_id)
    AwsClients.route53(provider).get_hosted_zone({ id: zone_id }).to_h[:vp_cs].first[:vpc_id]
  end
end
