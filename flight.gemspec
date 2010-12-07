# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{flight}
  s.version = "0.1.8"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Andy Rossmeissl", "Seamus Abshere", "Ian Hough", "Matt Kling", "Derek Kastner"]
  s.date = %q{2010-12-07}
  s.description = %q{A software model in Ruby for the greenhouse gas emissions of a flight}
  s.email = %q{andy@rossmeissl.net}
  s.extra_rdoc_files = [
    "LICENSE",
     "README.markdown",
     "README.rdoc"
  ]
  s.files = [
    "LICENSE",
     "README.rdoc",
     "lib/flight.rb",
     "lib/flight/carbon_model.rb",
     "lib/flight/carbon_model/fuel_use_equation.rb",
     "lib/flight/characterization.rb",
     "lib/flight/data.rb",
     "lib/flight/fallback.rb",
     "lib/flight/relationships.rb",
     "lib/flight/summarization.rb",
     "lib/test_support/flight_record.rb"
  ]
  s.homepage = %q{http://github.com/brighterplanet/flight}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{A carbon model}
  s.test_files = [
    "features/support/env.rb",
     "features/flight_committees.feature",
     "features/flight_emissions.feature",
     "lib/test_support/flight_record.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<activerecord>, ["~> 3"])
      s.add_development_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_development_dependency(%q<cucumber>, [">= 0"])
      s.add_development_dependency(%q<jeweler>, ["~> 1.4.0"])
      s.add_development_dependency(%q<rake>, [">= 0"])
      s.add_development_dependency(%q<rdoc>, [">= 0"])
      s.add_development_dependency(%q<rspec>, ["= 2.0.1"])
      s.add_development_dependency(%q<sniff>, ["~> 0.3"])
      s.add_runtime_dependency(%q<emitter>, ["~> 0.3"])
      s.add_runtime_dependency(%q<earth>, ["~> 0.3"])
      s.add_runtime_dependency(%q<builder>, [">= 0"])
    else
      s.add_dependency(%q<activerecord>, ["~> 3"])
      s.add_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_dependency(%q<cucumber>, [">= 0"])
      s.add_dependency(%q<jeweler>, ["~> 1.4.0"])
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<rdoc>, [">= 0"])
      s.add_dependency(%q<rspec>, ["= 2.0.1"])
      s.add_dependency(%q<sniff>, ["~> 0.3"])
      s.add_dependency(%q<emitter>, ["~> 0.3"])
      s.add_dependency(%q<earth>, ["~> 0.3"])
      s.add_dependency(%q<builder>, [">= 0"])
    end
  else
    s.add_dependency(%q<activerecord>, ["~> 3"])
    s.add_dependency(%q<bundler>, ["~> 1.0.0"])
    s.add_dependency(%q<cucumber>, [">= 0"])
    s.add_dependency(%q<jeweler>, ["~> 1.4.0"])
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<rdoc>, [">= 0"])
    s.add_dependency(%q<rspec>, ["= 2.0.1"])
    s.add_dependency(%q<sniff>, ["~> 0.3"])
    s.add_dependency(%q<emitter>, ["~> 0.3"])
    s.add_dependency(%q<earth>, ["~> 0.3"])
    s.add_dependency(%q<builder>, [">= 0"])
  end
end

