#!/bin/bash

# Update a nameserver entry at inwx with the current WAN IP (DynDNS)

# Copyright 2013 Christian Busch
# http://github.com/chrisb86/

# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:

# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# from which site should we get your wan ip?
IP_CHECK_SITE=http://checkip.dyndns.org

source $(dirname $0)/nsupdate.config

LOG=$0.log
IP_REGEX="\<[[:digit:]]{1,3}(\.[[:digit:]]{1,3}){3}\>"

NSLOOKUP=$(nslookup -sil $HOSTNAME - ns.inwx.de | tail -2 | head -1 | cut -d' ' -f2 | grep -Eo "$IP_REGEX")
WAN_IP=$(curl -s $IP_CHECK_SITE | grep -Eo "$IP_REGEX")

API_XML="<?xml version=\"1.0\"?>
<methodCall>
   <methodName>nameserver.updateRecord</methodName>
   <params>
      <param>
         <value>
            <struct>
               <member>
                  <name>user</name>
                  <value>
                     <string>$INWX_USER</string>
                  </value>
               </member>
               <member>
                  <name>pass</name>
                  <value>
                     <string>$INWX_PASS</string>
                  </value>
               </member>
               <member>
                  <name>id</name>
                  <value>
                     <int>$INWX_DOMAIN_ID</int>
                  </value>
               </member>
               <member>
                  <name>content</name>
                  <value>
                     <string>$WAN_IP</string>
                  </value>
               </member>
            </struct>
         </value>
      </param>
   </params>
</methodCall>"

if [ -z "$WAN_IP" ]; then
   echo "$(date) - Could not retrieve WAN IP" >> $LOG
   exit
fi

if [ -z "$NSLOOKUP" ]; then
   echo "$(date) - Could not resolve $HOSTNAME" >> $LOG
   exit
fi

if [ ! "$NSLOOKUP" == "$WAN_IP" ]; then
	curl -silent -v -XPOST -H"Content-Type: application/xml" -d "$API_XML" https://api.domrobot.com/xmlrpc/
	echo "$(date) - $HOSTNAME updated. Old IP: "$NSLOOKUP "New IP: "$WAN_IP >> $LOG
else
	echo "$(date) - No update needed for $HOSTNAME. Current IP: "$NSLOOKUP >> $LOG
fi