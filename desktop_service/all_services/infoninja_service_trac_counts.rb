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

$LOAD_PATH << File.expand_path("../")
require "./infoninja_service_lib"
require "net/http"
require "uri"
require "cgi"

TRAC_COUNT_SERVICE_DEBUG = true

TRAC_COUNT_URL = "http://hood/sockeye/query?"
TRAC_COUNT_PROJECT = "2.2"
TRAC_COUNT_LABEL = "2.2"
#TRAC_COUNT_PROJECT = "Kokanee 1.5"
#TRAC_COUNT_LABEL = "v1.5"

class ServiceThreadTracCounts < ServiceThread
    def initialize()
        @name = "trac count service"
        @open_statuses = ['accepted', 'assigned', 'new', 'reopened']
        @fnv_statuses = ['fixed_not_verified']
        @closed_statuses = ['closed']
        @http_username = nil
        @http_password = nil
    end

    def load_username_password
        if File.exists?(File.expand_path("~/.tracid"))
            f = File.new(File.expand_path("~/.tracid"), "r")
            @http_username = f.readline().strip()
            @http_password = f.readline().strip()
            f.close()
        end
    end
    private :load_username_password
    
    def start_internal(text_buffer)
        print "Trac Count service started\n" if TRAC_COUNT_SERVICE_DEBUG
        load_username_password()
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
                    this_count = fetch_count(label)
                    if -1 != this_count && -1 != counts[i]
                        counts[i] += this_count
                    else
                        counts[i] = -1
                    end
                }
                sleep(5)
            }
            (0...3).each { |i|
                counts[i] = 'ERR' if counts[i] == -1
            }
            line = "#{TRAC_COUNT_LABEL}: #{counts[0]}o #{counts[1]}fnv #{counts[2]}c"
            text_buffer.set_line(1, line)
            print "Sleeping\n" if TRAC_COUNT_SERVICE_DEBUG
            sleep(5 * 60)
        end
    end

    def fetch_count(label)
        response_string = ''
        count = 0
        url = URI("#{TRAC_COUNT_URL}status=#{label}&max=1000&group=status&milestone=#{CGI::escape(TRAC_COUNT_PROJECT)}")
        req = Net::HTTP::Get.new(url.request_uri)
        print "#{url}\n" if TRAC_COUNT_SERVICE_DEBUG
        if (nil != @http_username && nil != @http_password)
          req.basic_auth(@http_username, @http_password)
        end
        begin
            response = Net::HTTP.start(url.host, url.port) { |http|
                #http.get(url.request_uri)
                http.request(req)
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
        if nil == matches || matches.length != 2
            length = 0
            length = matches.length if nil != matches
            print "Trac Count regexp unexpectedly matched #{length} item(s)\n"
            count = 0
        elsif nil == matches[1]
            print "Trac Count matched nil on \"#{response_string}\n"
            p matches
            count = -1
        else
            count = matches[1].to_i
        end
        print "#{count}\n" if TRAC_COUNT_SERVICE_DEBUG
        return count
    end

    def errored(text_buffer, exception_object)
        text_buffer.set_line(1, "trac fetch error");
    end
end

$InfoNinja_Service_List << ServiceThreadTracCounts

