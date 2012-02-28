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

FORTUNE = "/usr/bin/fortune"
FORTUNE_COMMAND = "#{FORTUNE} -n20 -s"

class ServiceThreadFortune < ServiceThread
    def initialize()
        @available = File.exists?(FORTUNE)
    end
    
    def start_internal(text_buffer)
        if @available == false
            text_buffer.set_line(2, "fortune cmd unavailable")
            return
        end
        while (true)
            fortune = `#{FORTUNE_COMMAND}`
            fortune.strip!
            text_buffer.set_line(2, fortune)
            sleep(5 * 60)
        end
    end

    def errored(text_buffer, exception_object)
        text_buffer.set_line(2, "fortune error");
    end
end

$InfoNinja_Service_List << ServiceThreadFortune

