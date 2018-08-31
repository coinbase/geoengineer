require 'thread'

########################################################################
# CloudflareClient exposes a set of API calls to fetch data from
# Cloudflare.
# The primary reason for centralizing them here is testing and stubbing,
# and to synchronize access to global configuration settings so that
# we don't encounter race conditions when using multiple providers.
########################################################################
class CloudflareClient
  def self.mutex
    @mutex ||= Monitor.new # Monitor is reentrant, whereas Mutex is not
  end

  def self.connection(provider = nil)
    @connections ||= {}
    key = "cloudflare_client_#{provider&.terraform_id || GeoEngineer::Resource::DEFAULT_PROVIDER}"
    @connections[key] ||= new(provider)
  end

  def initialize(provider)
    @provider = provider
    @cloudflare = Cloudflare.connect(key: @provider.token, email: @provider.email)
  end

  def zones
    @zones ||= synchronize do
      Cloudflair.zones
    end
  end

  def zone_by_name(zone_name)
    zones_by_name[zone_name]
  end

  def dns_records
    @dns_records ||= begin
      records =
        synchronize do
          Parallel.map(zones, { in_threads: Parallel.processor_count }) do |zone|
            zone.dns_records
          end.flatten
        end

      records.map! do |record|
        name = record.name.chomp(record.zone_name).chomp('.')

        record_hash = {
          domain: record.zone_name,
          zone_id: zones_by_name[record.zone_name].id,
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

  private

  # Due to an implementation choice in the Cloudflair gem, we are forced to use
  # global configuration options any time we want to make a query. This isn't
  # thread-safe and we have to manage it explicitly if we want to support
  # multiple providers.
  def synchronize(&block)
    self.class.mutex.synchronize do
      Cloudflair.configure do |config|
        config.cloudflare.auth.key = @provider.token
        config.cloudflare.auth.email = @provider.email
      end
      yield(self)
    end
  end

  def zones_by_name
    @zones_by_name ||= zones.each_with_object({}) { |zone, hash| hash[zone.name] = zone }
  end
end
