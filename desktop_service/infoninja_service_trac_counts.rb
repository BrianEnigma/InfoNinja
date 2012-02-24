#!/usr/bin/ruby
# InfoNinja Service : a desktop service to push data to the InfoNinja
# Copyright (C) 2012, Brian Enigma <http://netninja.com>
#
# For more information about this library see: (TBD)
# For more information about the Trimet API see: <http://developer.trimet.org/>
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

require "infoninja_service_lib"
require "net/http"
require "uri"
require "cgi"

TRAC_COUNT_SERVICE_DEBUG = false

TRAC_COUNT_URL = "http://hood/sockeye/query?"
TRAC_COUNT_PROJECT = "Sockeye 1.8"
TRAC_COUNT_LABEL = "v1.8"

class ServiceThreadTracCounts < ServiceThread
    def initialize()
        @name = "trac count service"
        @open_statuses = ['accepted', 'assigned', 'new', 'reopened']
        @fnv_statuses = ['fixed_not_verified']
        @closed_statuses = ['closed']
    end
    
    def start_internal(text_buffer)
        print "Trac Count service started\n" if TRAC_COUNT_SERVICE_DEBUG
        while (true)
            arrivals = Array.new
            error_string = ''
            print "Fetching Trac Count update\n" if TRAC_COUNT_SERVICE_DEBUG
            counts = [0, 0, 0]
            (0...3).each { |i|
                labels = @open_statuses if 0 == i
                labels = @fnv_statuses if 1 == i
                labels = @closed_statuses if 2 == i
                labels.each { |label|
                    counts[i] += fetch_count(label)
                }
            }
            line = "#{TRAC_COUNT_LABEL}: #{counts[0]}o #{counts[1]}fnv #{counts[2]}c"
            text_buffer.set_line(1, line)
            print "Sleeping\n" if TRAC_COUNT_SERVICE_DEBUG
            sleep(60)
        end
    end

    def fetch_count(label)
        response_string = ''
        count = 0
        url = URI("#{TRAC_COUNT_URL}status=#{label}&max=1000&group=status&milestone=#{CGI::escape(TRAC_COUNT_PROJECT)}")
        print "#{url}\n" if TRAC_COUNT_SERVICE_DEBUG
        begin
            response = Net::HTTP.start(url.host, url.port) { |http|
                http.get(url.request_uri)
            }
            response_string = response.body
        rescue => e
            print("#{e.to_s}\n")
            print("#{e.backtrace}\n")
            count = 0
        end
        #print "#{response_string}\n" if TRAC_COUNT_SERVICE_DEBUG

        if response_string.index("No tickets found") != nil
            print "0\n" if TRAC_COUNT_SERVICE_DEBUG
            return 0
        end
        matches = response_string.match(/\(([0-9]+) matche?s?\)/)
        if nil != matches && matches.length != 2
            print "Trac Count regexp unexpectedly matched #{matches.length} item(s)\n"
            count = 0
        else
            count = matches[1].to_i
        end
        print "#{count}\n" if TRAC_COUNT_SERVICE_DEBUG
        return count
    end
end
