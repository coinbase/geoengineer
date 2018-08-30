########################################################################
# CloudflareClient exposes a set of API calls to fetch data from
# Cloudflare.
# The primary reason for centralizing them here is testing and stubbing.
########################################################################
class CloudflareClient
  def self.zones
    @_zones ||= Cloudflair.zones
  end

  def self.zones_by_name
    @_zones_by_name ||= self.zones.each_with_object({}) { |zone, hash| hash[zone.name] = zone }
  end

  def self.zone_by_name(zone_name)
    self.zones_by_name[zone_name]
  end

  def self.records
    records = Parallel.map(self.zones, { in_threads: Parallel.processor_count }) do |zone|
      zone.dns_records
    end.flatten

    records.map! do |record|
      name = record.name.chomp(record.zone_name).chomp('.')
      # Naked domain record
      name = record.zone_name if name.empty?

      record_hash = {
        domain: record.zone_name,
        zone_id: self.zone_by_name(record.zone_name).id,
        name: name,
        type: record.type,
        value: record.content,
        ttl: record.ttl,
        proxied: record.proxied,
        id: record.id,
      }
      record_hash[:priority] = record.priority if record.respond_to?(:priority)

      record_hash
    end
  end
end
