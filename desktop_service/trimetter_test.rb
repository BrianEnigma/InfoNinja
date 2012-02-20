#!/usr/bin/ruby
# Trimetter : a simple Ruby library for interfacing with Trimet data
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

require "trimetter"

trimetter = TrimetterArrivalQuery.new()
trimetter.debug = true
trimetter.stop_list = [11925, 1793]
trimetter.route_list = [14, 9]
results = Array.new()
error_string = ''
if !trimetter.fetch_update(results, error_string)
    print "Error fetching Trimet data\n"
    print "#{error_string}\n"
else
    print "\n\n"
    print "Received #{results.length} result#{results.length == 1 ? '' : 's'}\n"
    results.each { |result| print "#{result.to_s}\n" }
end
