
# Discord Blocker

Have you ever looked at the time and noticed it was 3 am and you're still in voice chat with the boys? Wish you could put a stop to that but also don't trust 3rd party apps with lots of permissions?

To solve this, I created a lightweight customizable shell script as a tiny project. You can read all the code yourself in 2 minutes.


### How it works
This shell script is a cron job that blocks discord on my computer by maintaining a blacklist of IPs from the discord process and adding them to the pfctl mac firewall command line interface.


### Questions you might ask

Why not just shut down the process: I use both the app and the web client, and they use similar ip addresses. Instead of shutting down the process and trying to close certain tabs I figured go simpler to the shared root of access (the tcp and udp files that are the channel to discord servers). I was also trying to learn how the mac firewall works.

Why not make a firewall by url: To maintain a list of all urls that an app uses is time consuming and could change over time. It might lead to gaps as well. If i generate the list of IPs from the process name, then the work is done for me.



## What I learned: 

Better understanding of TCP and UDP protocols.

lsof, which lists all open files (including tcp and udp connections), and those are greppable by 
`lsof -i -p | grep discord`

pfctl, the mac firewall program, which is backed by a pf.config file that runs on a high-level config language.



## Notes:


So Discord connections to the outside world can be listed via 
`lsof -i -p | grep discord`

They are TCP and UDP connections that are opened by the discord process

If you create a firewall in `/etc/pf.conf` blocking those connectiions, you can disable discord.


If then you create a Shell script to enable or disable that set of rules, at specific times, you can control the access of said process.


The following lines will block the listed IPs from making a connection to the applications on my computer
```
block drop out quick on en0 proto {tcp udp} to 162.159.136.234
block drop out quick on en0 proto {tcp udp} to 162.159.128.232
block drop out quick on en0 proto {tcp udp} to 162.159.138.232
block drop out quick on en0 proto {tcp udp} to 162.159.134.233
block drop out quick on en0 proto {tcp udp} to 162.159.137.232
block drop out quick on en0 proto {tcp udp} to 162.159.128.233
block drop out quick on en0 proto {tcp udp} to 162.159.133.234
```



However, it would be messy to maintain a dynamic list like that in my main config file.


So I created another file that has the custom rules so I dont break some default rule in the main config /etc/pf.config

`table <discord_servers> persist file "/etc/pf.discord.table"`


Then we can reference a new file pf.discord.table in pf.discord.config, and as the former file changes, the latter file will adjust and ban ips as they come in with this line:

This line references the table we created in the line above.

`block drop out quick on en0 proto {tcp udp} to <discord_servers>`

(add `pf.conf` to `/etc/pf.conf`)


We can call it pf.discord.table:
```
162.159.136.234
162.159.128.232
162.159.138.232
162.159.134.233
162.159.137.232
162.159.128.233
162.159.133.234
```
To generate the IPs above, run the command below



`sudo lsof -i -n -P | grep Discord | awk '{print $9}' | awk -F '->' '{print $2}' | awk -F ':' '{print $1}' | sort -u`

^ this will get the unique list of ips that are connected to the discord process

Then pipe it to the pf.discord.table file

`| sudo tee /etc/pf.discord.table > /dev/null`


At this point, I thought I had solved the problem, but then I realized discord dynamically generates new IP addresses if the client doesnt immediately connect to the default ones. So you can't just refresh the IP list every minute, the old IPs will come back through as they leave the lsof output.


So I have to maintain a blacklist of IPs and not get rid of any that dissappear and make sure the list doesnt get too big and out of hand. The perfect solution is to just maintain a secondary ip list, and append to it ips from lsof, and then make it a unique set of rows.

The command for that is: `sort -u /etc/pf.discord.table -o /etc/pf.discord.table`


Finally, we have to run this every minute and decide when it should be shut off:


### Cron job

cron jobs are per user (cron tab), and cron jobs that need root permissions have to be run as root, so to do that `sudo crontab -e` to edit the root's cron jobs.

add 
`$ * * * * * ~/repo_dir/live_discord_firewall.sh >> ~/repo_dir/blocker.log 2>&1`

Then 
`crontab -l` (lists all cron jobs)


### Running manually:
`./live_discord_firewall.sh`


