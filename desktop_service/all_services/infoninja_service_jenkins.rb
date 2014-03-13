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

JENKINS_SERVICE_DEBUG = true

class ServiceThreadJenkins < ServiceThread
    def initialize()
        @name = "jenkins service"
        # Set these to the URL(s) your Jenkins server(s)
        @url_list = [
            "http://jenkins-eme:8080/cc.xml",
            "http://jenkins-eme-win:8080/cc.xml",
        ]
        # List of projects we care about mapped to pass/fail/building characters
        @project_list = {
            "SockeyeTrunkQuick"             => ['q',  'Q',    '_'],
            "SockeyeTrunkMedium"            => ['m',  'M',    '_'],
            "Sockeye2_4Medium"              => ['24', '!24!', '_'],
            "Windows_Debug_x64_CPU"         => ['w',  'W',    '_'],
            "Windows_Debug_Live_x64_CPU"    => ['wl', 'WL',   '_'],
        }
        # Last known project statuses
        @project_status = Hash.new
        @currently_failing = false
    end
    
    def start_internal(text_buffer)
        print "Jenkins service started\n" if JENKINS_SERVICE_DEBUG
        while (true)
            error_string = ''
            print "Fetching Jenkins status\n" if JENKINS_SERVICE_DEBUG
            @project_status = Hash.new
            # Collect results
            @url_list.each { |url|
                document = nil
                response = Net::HTTP.get(URI(url))
                if !response.empty?
                  begin
                    document = REXML::Document.new(response)
                  rescue
                    print "Error parsing XML\n" if JENKINS_SERVICE_DEBUG
                  end
                end
                if nil != document
                    f = File.new("/tmp/cc.xml", "w")
                    document.write(f)
                    f.close()
                    document.each_element('/Projects/Project') { |project|
                        name = project.attributes['name']
                        next if nil == name || name.empty?
                        activity = project.attributes['activity']
                        status = project.attributes['lastBuildStatus']
                        # Record the status
                        if nil != status && !status.empty?
                            @project_status[name] = status
                        end
                        # Overwrite it with 'Building' if we're building
                        if nil != activity && !activity.empty? && 'Building' == activity
                            @project_status[name] = activity
                        end
                        #print "#{name} => #{@project_status[name]}\n" if JENKINS_SERVICE_DEBUG
                    }
                end
            }
            # Turn results into command
            entry = ''
            @currently_failing = false
            @project_list.each { |name, value|
                case @project_status[name]
                when 'Building'
                    entry << value[2]
                when 'Success'
                    entry << value[0]
                when 'Failure', 'Exception'
                    entry << value[1]
                    @currently_failing = true
                when 'Unknown'
                    entry << '?'
                    @currently_failing = true
                else
                    entry << '?'
                    @currently_failing = true
                end
                entry << ' '
            }
            entry.strip!
            text_buffer.set_line(1, entry)
            print "Sleeping\n" if JENKINS_SERVICE_DEBUG
            sleep(10 * 60)
        end
    end

    def get_lcd_blink_mode()
        return 5 if true == @currently_failing
        return 0
    end
    
    def errored(text_buffer, exception_object)
        text_buffer.set_line(3, "#{exception_object.to_s}");
    end
end


$InfoNinja_Service_List << ServiceThreadJenkins

