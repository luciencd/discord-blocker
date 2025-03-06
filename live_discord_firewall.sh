#!/bin/bash
echo $PATH
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

#gather all ipv4 addresses connected to discord
lsof -i4 -n -P | grep Discord | awk '{print $9}' | awk -F '->' '{print $2}' | awk -F ':' '{print $1}' | sort -u | sudo tee /etc/pf.discord.new.table > /dev/null
#pipe them to a holding file /etc/pf.discord.new.table 

#figure out how to do this for ipv6 as well, (not 100% certain it's necessary)



# Get the current minute and hour
minute=$(date +%M)
hour=$(date +%H) 


#append that holding file to the existing list of banned ips (the blacklist file)
cat /etc/pf.discord.new.table >> /etc/pf.discord.table

#sort the file containing all banned ips and make them unique (to conserve space)
sort -u /etc/pf.discord.table -o /etc/pf.discord.table



if [ "$hour" -ge 18 ] && [ "$hour" -lt 6 ]; then # don't bother making this into an arg... will make this project take 10x longer.
	#daytime ban - change to nighttime ban.

	# replace contents of the firewall blacklist with existing blacklist file
	pfctl -t discord_servers -T replace -f /etc/pf.discord.table >> /dev/null
	echo "Discord firewall rules updated at $(date)"
	echo "Banning ips: "
	cat /etc/pf.discord.table
else
    echo "Allow Discord to operate"
    # replace contents of the firewall blacklist with empty file
    pfctl -t discord_servers -T replace -f /dev/null >> /dev/null
fi

#update firewall rules
#sudo pfctl -f /etc/pf.conf
