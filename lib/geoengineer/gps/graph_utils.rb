# GraphUtils contains a suite of utilities to parse and process the graph spit out by
# `GeoEngineer::GPS::expanded_hash`.
class GeoEngineer::GPS::GraphUtils
  # Return the new values between old and new where old and new differ.
  # Specifically this returns:
  #   - Action of - with the old value for any key only present in old.
  #   - Action of + with the new value for any key only present in new.
  #   - Action of ~ with the new value for any key present in both but with different values.
  def self.difference(old, new)
    old_keys = old.keys
    new_keys = new.keys

    removed = old_keys - new_keys
    added = new_keys - old_keys

    to_return = []

    potential_modified_keys = old_keys - removed
    potential_modified_keys.each do |key|
      to_return += [{ action: '~', key: key, value: new[key] }] unless new[key] == old[key]
    end

    to_return += removed.map { |key| { action: '-', key: key, value: old[key] } }
    to_return += added.map { |key| { action: '+', key: key, value: new[key] } }
  end

  # This flattens the environment into a hash where keys are dot delimited keys up to the
  # first level of attributes of a GPS node. It doesn't flatten out sub levels of an attribute.
  # For example, a service would have a key of:
  # - "org/project.account.configuration.service.service_name.policies"
  # And this key would point to a list of hashes
  def self.flatten(tree, level = 6, base = "")
    if level.positive? && (tree.is_a?(Hash) || tree.is_a?(Array))
      tree.map do |key, value|
        new_base = [base, key].join(".")
        flatten(value, level - 1, new_base)
      end.reduce({}, :merge)
    else
      # Strip leading .
      base[0] = ''
      { base => tree }
    end
  end
end
