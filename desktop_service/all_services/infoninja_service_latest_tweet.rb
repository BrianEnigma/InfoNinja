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
require "infoninja_service_lib"

TWITTER_USERNAME = 'elementaltech'
TWITTER_URL = "http://api.twitter.com/1/statuses/user_timeline.rss?screen_name=#{TWITTER_USERNAME}"
DISPLAY_LINE = 2

class ServiceThreadLatestTweet < ServiceThread
    def initialize()
        @name = "latest tweet service"
    end
    
    def start_internal(text_buffer)
        while (true)
            tweet = ''

            # Get RSS document
            response = Net::HTTP.get(URI(TWITTER_URL))
            
            # Parse resulting XML
            document = REXML::Document.new(response)

            document.each_element("//item[1]/description") { |el|
                tweet = el.text
                tweet.gsub!(/^[^:]+:/, "")
                tweet.strip!
            }
            if tweet.empty?
                tweet = 'No tweet data'
            end
            text_buffer.set_line(DISPLAY_LINE, tweet)
            sleep(5 * 60)
        end
    end
    
    def errored(text_buffer, exception_object)
        text_buffer.set_line(DISPLAY_LINE, "#{exception_object.to_s}");
    end
end


$InfoNinja_Service_List << ServiceThreadLatestTweet

