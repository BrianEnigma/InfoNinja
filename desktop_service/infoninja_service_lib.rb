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

require 'cgi'
require 'thread'

# Global array for all known InfoNinja service classes.  Add to this list if
# you subclass ServiceThread.
$InfoNinja_Service_List = Array.new

TEXT_BUFFER_DEBUG = false

# TextBuffer is a class that represents the text on an InfoNinja
# screen.  All threads share a common TextBuffer and can write into
# it.  The master thread then sends updates out to your InfoNinja.
# The base background color is shared among all threads with no
# conflict resultion (unlike the light blink or background alert
# blink).  This means that the last thread to write it wins.
# You're encouraged to just leave it white and use the 
# get_lcd_blink_mode() function.
class TextBuffer
    def initialize()
        @lines = Array.new
        (0..3).each { |i| @lines[i] = ""}
        @red = 255
        @green = 255
        @blue = 255
        @mutex = Mutex.new
    end
    
    def set_background_color(r, g, b)
        @mutex.synchronize {
            @red = Math.min(Math.max(r, 0), 255)
            @green = Math.min(Math.max(g, 0), 255)
            @blue = Math.min(Math.max(b, 0), 255)
        }
    end
    
    def set_line(line_number, value)
        line_number = line_number.to_i
        if line_number < 0 || line_number > 3
            print "set_line number out of range\n" if TEXT_BUFFER_DEBUG
            return
        end
        if value.length > 20
            print "long line trimmed\n" if TEXT_BUFFER_DEBUG
            value = value[0...20] 
        end
        new_value = CGI::escape(value)
        print "\n\n+----------------------+\n" if TEXT_BUFFER_DEBUG
        @mutex.synchronize {
            @lines[line_number] = new_value
            if (TEXT_BUFFER_DEBUG)
                (0..3).each { |i| 
                    temp_line = CGI::unescape(@lines[i]);
                    print("| #{temp_line}")
                    print(" " * (20 - temp_line.length))
                    print(" |\n")
                }
            end
        }
        print "+----------------------+\n" if TEXT_BUFFER_DEBUG
    end
    
    def get_line(line_number)
        result = ''
        line_number = line_number.to_i
        return '' if line_number < 0 || line_number > 3
        @mutex.synchronize {
            result = @lines[line_number]
        }
        result = "%20" if result.empty? # force-clear the line
        return result
    end
end

BASE_SERVICE_DEBUG = true

# A base class for defining the interface between a worker thread (one that
# monitors some environmental condition) and the main thread (the thread that
# sends updates to your InfoNinja).
#
# You must implement:
# - start_internal(text_buffer)
# - errored(text_buffer, exception_object)
#
class ServiceThread
    attr_reader :name
    def initialize()
        @name = "unnamed"
        @launc_time = 0
        @error_count = 0
    end
    
    # Start the service thread with the given text buffer.
    def start(text_buffer)
        print "Starting service \"#{@name}\"\n" if BASE_SERVICE_DEBUG
        @my_thread = Thread.new {
            do_abort = false
            while (!do_abort)
                @launch_time = Time.new.to_i
                begin
                    print "Starting internal \"#{name}\" thread\n" if BASE_SERVICE_DEBUG
                    start_internal(text_buffer) 
                    print "Finished internal \"#{name}\" thread\n" if BASE_SERVICE_DEBUG
                rescue => e
                    print "Thread \"#{name}\" got exception\n"
                    timestamp = Time.new.strftime("%Y-%m-%d %H:%M:%S")
                    print "#{timestamp}: Service thread \"#{@name} has died!\n"
                    print "#{e.to_s}\n"
                    print "#{e.backtrace}\n"
                    now = Time.new.to_i
                    # If it's been running for a while (5+ minutes), give it some
                    # retries.  If it's been less than that, increment the retry count
                    if now - @launch_time > 5 * 50
                        @error_count = 0
                    else
                        @error_count += 1
                    end
                    # Too many retries leads to error
                    if @error_count > 3
                        errored(text_buffer, e)
                        do_abort = true
                    end
                rescue
                    print "#{timestamp}: Service thread \"#{@name} has died!\n"
                    print "Unknown exception occurred\n"
                ensure
                    print "#{timestamp}: Service thread \"#{@name} has exited.\n"
                end
            end
        }
    end
    
    # Because several services may want to set the button LED to
    # conflicting values (e.g. one may want it off and another may
    # want it on or blinking), the main thread will query each
    # service about the desired state.  
    # If all services want it off, then it will be off.
    # If any service wants it on (but no want it blinking), then it will be on.
    # If any service wants it blinking, then it will be blinking.
    # The return value is 0, 1, or 2 -- matching the actual number
    # sent to InfoNinja (0 = off, 1 = on, 2 = blink)
    def get_button_led()
        return 0
    end
    
    # Because several services may want to set the background LCD's
    # blink mode to conflicting balues, the main thread will query each
    # service about the desired state.  See how get_button_led handles
    # this sort of conflict.
    # The return value is 0..6 -- matching the actual number send to
    # InfoNinja.
    def get_lcd_blink_mode()
        return 0
    end
end

TIME_SERVICE_DEBUG = false

class ServiceThreadTime < ServiceThread
    def initialize()
        @name = "time service"
    end
    
    def start_internal(text_buffer)
        print "Time service started\n" if TIME_SERVICE_DEBUG
        while (true)
            now = Time.new
            # Get the time and force a lowercase AM/PM
            time_string = now.strftime("%I:%M%p").downcase
            date_string = now.strftime("%m/%d")
            # Remove the leading zero.  I hate that thing.
            if time_string[0] == '0'[0]
                time_string = time_string[1..time_string.length()]
            end
            print "Time is now #{time_string} #{date_string}\n" if TIME_SERVICE_DEBUG
            text_buffer.set_line(0, "#{time_string} #{date_string}")
            print "Sleeping\n" if TIME_SERVICE_DEBUG
            sleep(10)
        end
    end

    def errored(text_buffer, exception_object)
        text_buffer.set_line(0, "time error");
    end
end


$InfoNinja_Service_List << ServiceThreadTime

