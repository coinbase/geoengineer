# Constants contains a hash that can store sharable values
class GeoEngineer::GPS::Constants
  attr_reader :constants

  def initialize(constants)
    @constants = constants

    # the local environment overrides the default values
    constants.each_pair do |environment, vals|
      # "name" is always the full name of the environment
      constants[environment]["name"] = environment.to_s
    end

    # attach constants and environment to YamlTags
    constants.each_pair do |environment, vals|
      GeoEngineer::GPS::YamlTag.add_tag_context(vals, { constants: self, context: { environment: environment } })
    end

    @constants = HashUtils.json_dup(@constants)
  end

  def for_environment(environment_name)
    (constants["_global"] || {}).merge(constants[environment_name.to_s])
  end

  # look up in environment then look in the _global
  def dereference(environment, attribute)
    from_current_env = constants.dig(environment, attribute)
    return from_current_env unless from_current_env.nil?

    from_global_env = constants.dig("_global", attribute)
    return from_global_env unless from_global_env.nil?

    nil
  end

  def to_h
    HashUtils.json_dup(constants)
  end
end
