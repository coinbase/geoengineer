# HashUtils class for helper methods
class HashUtils
  def self.remove_(hash)
    hash = hash.dup
    hash.each_pair do |key, value|
      hash.delete(key) && next if key.to_s.start_with?("_")
      hash[key] = remove_(value) if value.is_a?(Hash)
    end
    hash
  end

  def self.json_dup(object)
    JSON.parse(object.to_json)
  end

  def self.deep_dup(object)
    case object
    when Hash
      object.each_with_object({}) do |(key, value), hash|
        hash[deep_dup(key)] = deep_dup(value)
      end
    when Array
      object.map { |it| deep_dup(it) }
    when Symbol
      object.to_s
    else
      object.dup
    end
  end

  # This merges a set of deeply nested hashes
  def self.deep_merge(a = {}, b = {})
    a.merge(b) do |key, value_a, value_b|
      if value_a.is_a?(Hash) || value_b.is_a?(Hash)
        deep_merge(value_a, value_b)
      else
        value_b
      end
    end
  end
end
