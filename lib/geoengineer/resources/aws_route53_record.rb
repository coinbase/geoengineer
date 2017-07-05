########################################################################
# AwsRoute53Record is the +aws_route53_record+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/route53_record.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsRoute53Record < GeoEngineer::Resource
  validate -> { validate_required_attributes([:zone_id, :name, :type]) }
  validate -> { validate_required_attributes([:ttl, :records]) unless self.alias }

  validate -> {
    if self.alias
      validate_subresource_required_attributes(:alias, [:name, :zone_id, :evaluate_target_health])
    end
  }

  after :initialize, -> { _terraform_id -> { "#{zone_id}_#{name}_#{record_type}" } }

  def record_type(val = nil)
    val ? self["type"] = val : self["type"]
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
    records = AwsClients.route53(provider).list_resource_record_sets({ hosted_zone_id: zone[:id] })
    records.resource_record_sets.map(&:to_h).map do |record|
      record.merge({ _terraform_id: "#{record[:zone_id]}_#{record[:name]}_#{record[:type]}" })
    end
  end
end
