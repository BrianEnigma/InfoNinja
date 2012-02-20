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

require "net/http"
require "uri"
require "infoninja_service_lib"
# Include any other libs derived from ServiceThread here...
require "infoninja_service_trimet"
# End includes

print "InfoNinja Service v1.0\n"

#Get IP address
if ARGV.length < 1
    print "Error: supply IP address of your InfoNinja on the command line\n"
    exit(1)
end

def do_request(url_string)
    response_string = ''
    begin
        url = URI(url_string)
        response = Net::HTTP.start(url.host, url.port) do |http|
            http.get(url.request_uri)
        end
        response_string = response.body
    rescue => e
        print("#{e.to_s}\n")
        print("#{e.backtrace}\n")
        return false
    end
    return false if response_string.empty?
    return false if response_string.index("ERROR") != nil
    return true if response_string.index("GOOD") != nil
    return true if response_string.index("InfoNinja is alive") != nil # hello command's response
    return false # unexpected value returned
end

# Verify that the thing is out there
infoninja_ip = ARGV[0]
hello_url = "http://#{infoninja_ip}/index.html"
if !do_request(hello_url)
    print "Your InfoNinja did not respond to the 'Hello' command\n"
    exit(2)
end

# Set up LCD text buffer
text_buffer = TextBuffer.new

# Set up service threads
threads = Array.new
time_service = ServiceThreadTime.new
print "Starting time thread\n"
time_service.start(text_buffer)
threads << time_service
# Add any additional threads & services here
trimet_service = ServiceThreadTrimet.new
trimet_service.start(text_buffer)
threads << trimet_service
# ------------------------------------------

# Give the threads a sec to stabalize
sleep(1)

# Infinite program loop
print "Staring update thread\n"
while (true)
    # Print the four lines
    (0..3).each { |i|
        line = text_buffer.get_line(i)
        url = "http://#{infoninja_ip}/print?#{i}-#{line}"
        if !do_request(url)
            print("Error sending request #{url}\n")
        end
    }
    # TODO: update backlight
    # TODO: resolve button LED conflict
    # TODO: resolve backlight blink conflict
    # Wait for the next cycle
    sleep(20)
end
