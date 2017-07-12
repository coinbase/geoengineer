########################################################################
# AwsRoute53Record is the +aws_route53_record+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/route53_record.html Terraform Docs}
########################################################################

# Note: Currently, 'name' must be the fully qualified domain name.
class GeoEngineer::Resources::AwsRoute53Record < GeoEngineer::Resource
  validate -> { validate_required_attributes([:zone_id, :name, :type]) }
  validate -> { validate_required_attributes([:ttl, :records]) unless self.alias }

  validate -> {
    if self.alias
      validate_subresource_required_attributes(:alias, [:name, :zone_id, :evaluate_target_health])
    end
  }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { "#{zone_id}_#{self.name.downcase}_#{record_type}" } }

  def to_terraform_state
    tfstate = super
    tfstate[:primary][:attributes] = {
      'id' => _terraform_id,
      'name' => name,
      'type' => record_type
    }
    tfstate
  end

  def record_type(val=nil)
    val ? self["type"] = val : self["type"]
  end

  def fqdn
    self["name"].downcase
  end

  def support_tags?
    false
  end

  def self._fetch_remote_resources(provider)
    _fetch_zones(provider).map { |zone| _fetch_records_for_zone(provider, zone) }.flatten.compact
  end

  def self._fetch_zones(provider)
    AwsClients.route53(provider).list_hosted_zones.hosted_zones.map(&:to_h)
  end

  def self._fetch_records_for_zone(provider, zone)
    zone_id = zone[:id].gsub(/^\/hostedzone\//, '')
    response = AwsClients.route53(provider).list_resource_record_sets({ hosted_zone_id: zone_id })

    records = []
    response.each do |page|
      records += page.resource_record_sets.map(&:to_h).map do |record|
        name = _fetch_name(record, zone)
        id = "#{zone_id}_#{name}_#{record[:type]}"
        record.merge({ fqdn: name, _terraform_id: id, _geo_id: id })
      end
    end

    records
  end

  def self._fetch_name(record, zone)
    # Need to trim the trailing dot, as well as convert ASCII 42 (Octal 52) to
    # the wildcard star. Route53 uses that for wildcard records.
    name = record[:name].downcase.gsub(/\.$/, '').gsub(/^\\052/, '*')
    zone_name = zone[:name].gsub(/\.$/, '')
    if name !~ /#{zone_name}$/
      if name.empty?
        name = zone_name
      else
        name = "#{name}.#{zone_name}"
      end
    end
    name
  end

end
