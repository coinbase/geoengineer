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

    HashUtils.map_values(@constants_hash) do |a|
      a.constants = self if a.respond_to?(:constants=)
      a
    end
  end

  def each_for_environment(environment_name)
    constants_hash[environment_name.to_s]
  end

  def to_h
    HashUtils.json_dup(constants_hash)
  end
end