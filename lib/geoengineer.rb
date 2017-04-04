########################################################################
# GeoEngineer main Module
########################################################################
module GeoEngineer
end

########################################################################
# GeoEngineer::Resources Collection of Resources
########################################################################
module GeoEngineer::Resources
end

########################################################################
# GeoEngineer::Templates Collection of Templates
########################################################################
module GeoEngineer::Templates
end

require 'aws-sdk'
require 'json'
require 'ostruct'
require 'uri'
require 'securerandom'

Dir["#{File.dirname(__FILE__)}/geoengineer/utils/**/*.rb"].each { |f| require f }

Dir["#{File.dirname(__FILE__)}/geoengineer/*.rb"].each { |f| require f }

Dir["#{File.dirname(__FILE__)}/geoengineer/resources/**/*.rb"].each { |f| require f }

Dir["#{File.dirname(__FILE__)}/geoengineer/templates/**/*.rb"].each { |f| require f }
