# Constants contains the needed information to
class GeoEngineer::GPS::Constants
  attr_reader :base_hash, :constants_hash

  def initialize(base_hash)
    @base_hash = base_hash

    # _defaults is copied into each environment
    @defaults_hash = HashUtils.deep_dup(@base_hash["_defaults"])

    # remove all _'s
    @constants_hash = HashUtils.remove_(@base_hash)

    # the local environment overrides the values
    @constants_hash.each_pair do |key, value|
      constants_hash[key] = value.merge(@defaults_hash)
    end

    # attach constants and environment to TTags
    @constants_hash.each_pair do |environment, vals|
      HashUtils.map_values(vals) do |a|
        a.constants = self if a.respond_to?(:constants=)
        a.environment = environment if a.respond_to?(:environment=)
        a
      end
    end
  end

  def deref
    GeoEngineer::GPS::Deref.new(nil, constants)
  end

  def each_for_environment(environment_name)
    constants_hash[environment_name.to_s]
  end

  def to_h
    HashUtils.json_dup(constants_hash)
  end

  def dereference!(reference, local_environment = nil)
    prefix, environment, name = reference.split(":")
    environment = local_environment if environment.to_s == ""

    reference = [prefix, environment, name].join(":")

    deref.dereference(reference)
  end
end