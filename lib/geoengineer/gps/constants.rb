# Constants contains the needed information to
class GeoEngineer::GPS::Constants
  attr_reader :base_hash, :constants_hash

  def initialize(base_hash)
    @base_hash = base_hash

    # _defaults is copied into each environment
    @defaults_hash = @base_hash["_defaults"]

    # remove all _'s
    @constants_hash = HashUtils.remove_(@base_hash)

    # the local environment overrides the values
    @constants_hash.each_pair do |environment, vals|
      @constants_hash[environment] = @defaults_hash.merge(vals)
    end

    # Force different Tag objects
    @constants_hash = HashUtils.deep_dup(@constants_hash)

    # attach constants and environment to TTags
    @constants_hash.each_pair do |environment, vals|
      GeoEngineer::GPS::YamlTag.add_tag_values(vals, { constants: self, environment: environment })
    end
  end

  def constants_json
    @constants_json ||= HashUtils.json_dup(constants_hash)
  end

  def for_environment(environment_name)
    constants_json[environment_name.to_s]
  end

  def dereference(environment, attribute)
    @constants_hash.dig(environment, attribute)
  end

  def to_h
    HashUtils.json_dup(constants_hash)
  end
end
