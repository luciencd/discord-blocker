import time
import os

# Define the Discord domains to block
DISCORD_DOMAINS = [
    "discord.com",
    "cdn.discordapp.com",
    "media.discordapp.net",
    "discordapp.com"
]
HOSTS_FILE = "/etc/hosts"
REDIRECT_IP = "127.0.0.1"

# Define time range (e.g., block from 10 PM to 7 AM)
BLOCK_HOURS = (19, 7)  # 10 PM to 7 AM

def is_block_time():
    """Check if the current time falls within blocking hours."""
    current_hour = time.localtime().tm_hour
    start, end = BLOCK_HOURS
    if start < end:
        return start <= current_hour < end
    return current_hour >= start or current_hour < end  # Handles cases like 10PM - 7AM

def modify_hosts(block=True):
    """Modify the /etc/hosts file to block or unblock Discord."""
    with open(HOSTS_FILE, "r+") as file:
        lines = file.readlines()
        file.seek(0)
        for line in lines:
            if not any(domain in line for domain in DISCORD_DOMAINS):
                file.write(line)
        file.truncate()

        if block:
            for domain in DISCORD_DOMAINS:
                file.write(f"{REDIRECT_IP} {domain}\n")

def main():
    if is_block_time():
        modify_hosts(block=True)
        print("Discord is now blocked.")
    else:
        modify_hosts(block=False)
        print("Discord is unblocked.")

if __name__ == "__main__":
    if os.geteuid() != 0:
        print("Please run this script as root (sudo).")
    else:
        main()
