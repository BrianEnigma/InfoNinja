#!/usr/bin/ruby
# InfoNinja Service : a desktop service to push data to the InfoNinja
# Copyright (C) 2012, Brian Enigma <http://netninja.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

$LOAD_PATH << File.expand_path("../")
require "./infoninja_service_lib"
require "rexml/document"
require "net/http"
require "uri"

WEATHER_SERVICE_DEBUG = true

class ServiceThreadWeather < ServiceThread
    def initialize()
        @name = "weather service"
        # Set these to your own stations and lines
        @lat = 45.59578
        @long = -122.60917
        @url = "http://forecast.weather.gov/MapClick.php?lat=#{@lat}&lon=#{@long}&unit=0&lg=english&FcstType=dwml"
        # Example: http://forecast.weather.gov/MapClick.php?lat=45.52050&lon=-122.70734900000002&unit=0&lg=english&FcstType=dwml
    end
    
    def start_internal(text_buffer)
        print "Weather service started\n" if WEATHER_SERVICE_DEBUG
        while (true)
            entry = ''
            error_string = ''
            document = nil
            print "Fetching Weather update\n" if WEATHER_SERVICE_DEBUG
            response = Net::HTTP.get(URI(@url))
            if response.empty?
              entry = "Weather error"
            else
              begin
                document = REXML::Document.new(response)
              rescue
                entry = "Error parsing XML"
              end
            end
            if nil != document
              f = File.new("/tmp/weather.xml", "w")
              document.write(f)
              f.close()
              document.each_element('//dwml/data[@type="current observations"]/parameters/temperature[@type="apparent"]/value') { |temp_element|
                entry << temp_element.text
              }
              temp_min = ''
              temp_max = ''
              document.each_element('//dwml/data[@type="forecast"]/parameters/temperature') { |temp_element|
                if temp_element.attributes['type'] == 'maximum'
                  temp_element.each_element("value") { |v|
                    temp_max = v.text if temp_max.empty?
                  }
                end
                if temp_element.attributes['type'] == 'minimum'
                  temp_element.each_element("value") { |v|
                    temp_min = v.text if temp_min.empty?
                  }
                end
              }
              conditions = ''
              document.each_element('//dwml/data[@type="forecast"]/parameters/weather/weather-conditions') { |cond_element|
                conditions = cond_element.attributes['weather-summary'] if conditions.empty?
              }
              entry << " #{temp_min}-#{temp_max}" if !temp_min.empty? && !temp_max.empty?
              entry << " #{conditions}" if !conditions.empty?
              entry = entry[0, 20] if entry.length > 20
            end
            text_buffer.set_line(2, entry)
            print "Sleeping\n" if WEATHER_SERVICE_DEBUG
            sleep(10 * 60)
        end
    end
    
    def errored(text_buffer, exception_object)
        text_buffer.set_line(3, "#{exception_object.to_s}");
    end
end


$InfoNinja_Service_List << ServiceThreadWeather

