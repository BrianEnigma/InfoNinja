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
require "trimetter"

TRIMET_SERVICE_DEBUG = true

class ServiceThreadTrimet < ServiceThread
    def initialize()
        @name = "trimet service"
        # Set these to your own stations and lines
        @stop_list = [7636, 13169]
        @route_list = [14, 9]
        @trimetter = TrimetterArrivalQuery.new
        # Set up your Developer ID here if you don't have it in a dotfile in your home folder
        #@trimetter.devloper_id = 'xyz'
        @trimetter.stop_list = @stop_list
        @trimetter.route_list = @route_list
    end
    
    def start_internal(text_buffer)
        print "Trimet service started\n" if TRIMET_SERVICE_DEBUG
        while (true)
            arrivals = Array.new
            error_string = ''
            print "Fetching Trimet update\n" if TRIMET_SERVICE_DEBUG
            if (@trimetter.fetch_update(arrivals, error_string))
                line_14 = '#14:'
                line_9 = '#9: '
                arrivals.each { |arrival|
                    entry = ''
                    if :error == arrival.status
                        entry << "[err]"
                    elsif :canceled == arrival.status
                        entry << "[cancel]"
                    elsif :invalid == arrival.status
                        entry << "[inv]"
                    elsif :estimated == arrival.status
                        if 0 == arrival.arriving_in_minutes
                            entry << "now"
                        else
                            entry << "#{arrival.arriving_in_minutes}min"
                        end
                    elsif :scheduled == arrival.status
                        if 0 == arrival.arriving_in_minutes
                            entry << "now?"
                        else
                            entry << "#{arrival.arriving_in_minutes}min?"
                        end
                    elsif :delayed == arrival.status
                        entry << "@#{arrival.arrival_time.strftime('%I:%M')}"
                    else
                        entry << "[???]"
                    end
                    entry << " "
                    if 9 == arrival.route.to_i
                        line_9 << entry
                    elsif 14 == arrival.route.to_i
                        line_14 << entry
                    end
                }
                if (arrivals.length > 0)
                    text_buffer.set_line(2, line_14)
                    text_buffer.set_line(3, line_9)
                else
                    text_buffer.set_line(3, "No Trimet Data")
                end
            else
                text_buffer.set_line(2, "Trimet Fetch Error")
                text_buffer.set_line(3, error_string)
            end
            print "Sleeping\n" if TRIMET_SERVICE_DEBUG
            sleep(60)
        end
    end
    
    def errored(text_buffer, exception_object)
        text_buffer.set_line(2, "trimet data error");
        text_buffer.set_line(3, "#{exception_object.to_s}");
    end
end
