########################################################################
# NullObject and NullObject.maybe provide the NullObject pattern
# as defined {http://devblog.avdi.org/2011/05/30/null-objects-and-falsiness/ here}
#
########################################################################
class NullObject
  def method_missing(name, *args, &block)
    nil
  end

  def self.maybe(value)
    case value
    when nil then NullObject.new
    else value
    end
  end
end
