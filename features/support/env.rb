require 'bundler'
Bundler.setup

require 'cucumber'
require 'cucumber/formatter/unicode' # Remove this line if you don't want Cucumber Unicode support

require 'sniff'
Sniff.init File.join(File.dirname(__FILE__), '..', '..'), :earth => [:air, :locality, :fuel], :cucumber => true, :logger => 'log/test_log.txt'


# Set up fuzzy matching between Aircraft and FlightSegment for testing
# Also, derive characteristics of Aircraft from flight_segments
require 'loose_tight_dictionary'
require 'earth/air/flight_segment/data_miner'
require 'earth/air/aircraft/data_miner'
FlightSegment.data_miner_config.steps.clear
Aircraft.update_averages!

# Derive characteristics of AircraftClass from aircraft
require 'earth/air/aircraft_class/data_miner'
AircraftClass.data_miner_config.steps.detect { |s| s.class == DataMiner::Process and s.description =~ /Derive aircraft classes/i }.run
AircraftClass.data_miner_config.steps.detect { |s| s.class == DataMiner::Process and s.description =~ /Derive some average/i }.run
