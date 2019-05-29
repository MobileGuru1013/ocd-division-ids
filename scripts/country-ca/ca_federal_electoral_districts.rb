#!/usr/bin/env ruby
# coding: utf-8

require File.expand_path(File.join("..", "utils.rb"), __FILE__)

# Scrapes federal electoral district codes and names from elections.ca

class CA < Runner
  def initialize(*args)
    super

    add_command({
      :name        => "names-fr",
      :description => "Prints a CSV of identifiers and French names",
      :output_path => "identifiers/country-ca/ca_federal_electoral_districts-name_fr.csv",
    })
    add_command({
      :name        => "names-2013",
      :description => "Prints a CSV of identifiers, English names, and French names",
      :output_path => "identifiers/country-ca/ca_federal_electoral_districts-2013.csv",
    })
  end

  def names
    rows("name", "e")
  end

  def names_fr
    rows("name_fr", "F")
  end

  def names_2013
    puts CSV.generate_line(["id", "name", "name_fr", "validFrom"])
    # @see http://open.canada.ca/data/en/dataset/5f1c2e06-405a-4357-9566-872e69ee2ade
    ShapefileParser.new(
      "http://www12.statcan.gc.ca/census-recensement/2011/geo/bound-limit/files-fichiers/2016/lfed000a16a_e.zip",
      "ed:", {
        :id => lambda{|record| "#{record.attributes["FEDUID"]}-2013"},
        :name => lambda{|record| record.attributes["FEDENAME"].gsub("’", "'")},
        :name_fr => lambda{|record| record.attributes["FEDFNAME"].gsub("’", "'")},
        :sort_as => "FEDUID",
        :validFrom => lambda{|record| "2015-10-19"},
      }
    ).run(:write_headers => false)
  end

private

  def rows(column_name, language)
    puts CSV.generate_line(["id", column_name])
    # The most authoritative data is only available as HTML.
    Nokogiri::HTML(open("http://elections.ca/content.aspx?section=res&dir=cir/list&document=index&lang=#{language}")).css("tr").each do |tr|
      tds = tr.css("td")
      next if tds.empty? # if th tags

      identifier = tds[0].text.gsub(/\D/, "")
      next unless identifier[/\A\d{5}\z/] # name changes and totals

      name = tds[1].children[0].text.normalize_space.gsub("–", "—") # n-dash, m-dash
      if name == "Western Arctic"
        name = language == "e" ? "Northwest Territories" : "Territoires du Nord-Ouest"
      end

      # "Saint Boniface" is inconsistent with other district names in Manitoba,
      # "Charleswood–St. James–Assiniboia" and "Kildonan–St. Paul".
      output("ed:", identifier, name)
    end
  end
end

CA.new("ca_federal_electoral_districts.csv").run(ARGV)
