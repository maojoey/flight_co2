module BrighterPlanet
  module Flight
    module ImpactModel
      class FlightSegmentCohort
        class << self
          def from_characteristics(characteristics)
            flight_segment_cohort = new characteristics
            if flight_segment_cohort.valid?
              flight_segment_cohort
            else
              nil
            end
          end
        end

        BTS_COHORT_PRIORITIES = [:origin_airport_iata_code, :destination_airport_iata_code, :aircraft_description, :airline_name]
        BTS_SOURCE_CODE = 'BTS T100'
        ICAO_COHORT_PRIORITIES = [:origin_airport_city, :destination_airport_city, :aircraft_description, :airline_name]
        ICAO_SOURCE_CODE = 'ICAO TFS'
        COLUMNS = {
          aircraft_description: 'CHARACTER VARYING(255)',
          seats_per_flight: 'FLOAT',
          distance: 'FLOAT',
          load_factor: 'FLOAT',
          freight_share: 'FLOAT',
          passengers: 'INTEGER',
        }
        
        attr_reader :characteristics
        attr_reader :table_name
        attr_reader :origin_airport
        attr_reader :destination_airport
        
        # We pull values out of charisma curations here
        # TODO: don't make up for charisma's probs
        def initialize(characteristics)
          @select_manager_mutex = Mutex.new
          @cohort_mutex = Mutex.new
          @count_mutex = Mutex.new
          @table_name = "flight_segment_cohort_#{Kernel.rand(1e11)}"
          @characteristics = characteristics.inject({}) do |memo, (k, v)|
            if (vv = v.respond_to?(:value) ? v.value : v) and not vv.nil?
              memo[k] = vv
            end
            memo
          end
          @origin_airport = characteristics[:origin_airport]
          @destination_airport = characteristics[:destination_airport]
          @covered_by_bts_query = (origin_airport.try(:country_iso_3166_code) == 'US' or destination_airport.try(:country_iso_3166_code) == 'US')
        end
        
        def valid?
          characteristics[:segments_per_trip] == 1 and
          characteristics[:date].present? and
          provided.any? and
          possible?
        end
        
        def weighted_average(*args)
          select_manager.weighted_average(*args)
        end
        
        def cohort_sql
          @cohort_sql ||= case cohort
          when Array
            union = cohort.inject { |memo, v| memo.union(:all, v) }
            "SELECT * FROM #{union.to_sql} AS t1"
          else
            cohort.to_sql
          end
        end

        alias :to_sql :cohort_sql

        def count
          @count || @count_mutex.synchronize do
            @count ||= begin
              counter = select_manager.clone
              counter.projections = [Arel.sql('COUNT(*)')]
              FlightSegment.connection.select_value counter.to_sql
            end
          end
        end
        
        def as_json(*)
          { :members => count, :sql => to_sql }
        end

        def cleanup
          execute %{ DROP TABLE IF EXISTS #{table_name} }
        end

        def resolve_cohort!
          cohort_sql
          true
        end

        def generate_tmp_table!
          select_manager
          true
        end
        
        private

        def connection
          FlightSegment.connection
        end

        def execute(sql)
          connection.execute sql
        end

        def sqlite?
          connection.adapter_name =~ /sqlite/i
        end

        def mysql?
          connection.adapter_name =~ /mysql/i
        end

        def provided
          @provided ||= {
            :aircraft_description => characteristics[:aircraft].try(:flight_segments_foreign_keys),
            :airline_name => characteristics[:airline].try(:name),
            :origin_airport_iata_code => origin_airport.try(:iata_code),
            :origin_airport_city => origin_airport.try(:city),
            :destination_airport_iata_code => destination_airport.try(:iata_code),
            :destination_airport_city => destination_airport.try(:city),
          }.select do |k, v|
            v.present?
          end
        end

        def relevant_years
          date = characteristics[:date].is_a?(Date) ? characteristics[:date] : Date.parse(characteristics[:date].to_s)
          if covered_by_bts?
            # Restrict the cohort to flight segments that occurred the same year as the flight or the previous year.
            # (We need to include the previous year because BTS flight segment data lags by 6 months.)
            [date.year - 1, date.year]
          else
            # Restrict the cohort to flight segments that occurred the same year as the flight or the previous three years.
            # (We need to include the previous three years because 2009 is the most recent year for which we have complete ICAO data.)
            [date.year - 3, date.year - 2, date.year - 1, date.year]
          end
        end

        def covered_by_bts?
          @covered_by_bts_query
        end
        
        def cohort_from_source(source, priority)
          fs = FlightSegment.arel_table
          other_conditions = fs[:source].eq(source).and(fs[:year].in(relevant_years).and(fs[:passengers].gt(0)))
          FlightSegment.where(other_conditions).cohort(provided.slice(*priority), :strategy => :strict, :priority => priority).project(COLUMNS.keys.join(','))
        end

        # Assemble a cohort by starting with all flight segments in the relevant years. Select only the
        # segments that match the characteristics we've decided to use. If no segments match all the
        # characteristics, drop the last characteristic (initially `airline`) and try again. Continue until
        # we have some segments or we've dropped all the characteristics.
        def bts_cohort
          cohort_from_source BTS_SOURCE_CODE, BTS_COHORT_PRIORITIES
        end

        # FIXME TODO deal with cities in multiple countries that share a name
        # Tried pushing country, which works on a flight from Mexico City to Barcelona, Spain because it does
        # not include flights to Barcelona, Venezuela BUT it doesn't work if we're trying to go from Montreal
        # end up with flights to London, United Kingdom. Also pushing country breaks addition of cohorts - all 'AND'
        # statements get changed to 'OR' so you end up with all flights to that country
        # e.g. WHERE origin_airport_iata_code = 'JFK' OR origin_country_iso_3166_code = 'US'
        def icao_cohort
          cohort_from_source ICAO_SOURCE_CODE, ICAO_COHORT_PRIORITIES
        end

        def cohort
          @cohort || @cohort_mutex.synchronize do
            @cohort ||= if origin_airport.present? and destination_airport.present?
              if covered_by_bts?
                # NOTE: It's possible that the origin/destination pair won't appear in our database and we'll end up using a
                # cohort based just on origin. If that happens, even if the origin is not in the US we still don't want to use
                # origin airport city, because we know the flight was going to the US and ICAO segments never touch the US.
                # For example if there are direct flights from Rivendell to DC or London, but you enter a flight from Timbuktu to NYC.
                bts_cohort
              else
                icao_cohort
              end
            else
              [bts_cohort, icao_cohort]
            end
          end
        end

        def possible?
          resolve_cohort!
          Array.wrap(cohort).any? do |cohort|
            cohort.cohort_possible?
          end
        end

        def select_manager
          @select_manager || @select_manager_mutex.synchronize do
            @select_manager ||= begin
              populated = false
              structure = "CREATE TEMPORARY TABLE #{table_name} (#{COLUMNS.map { |k, v| "#{k} #{v}" }.join(',')})"

              if sqlite?
                populated = true
                execute %{ #{structure} AS #{cohort_sql} }
              elsif mysql?
                execute %{ #{structure} ENGINE=MEMORY }
              else
                execute structure
              end

              unless populated
                execute %{ INSERT INTO #{table_name} #{cohort_sql} }
              end

              select_manager = Arel::SelectManager.new FlightSegment, Arel::Table.new(table_name)
              
              # eagerly perform a count
              counter = select_manager.clone
              counter.projections = [Arel.sql('COUNT(*)')]
              @count = FlightSegment.connection.select_value counter.to_sql

              select_manager
            end
          end
        end
      end
    end
  end
end
