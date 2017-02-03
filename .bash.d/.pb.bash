# ~/.bash.d/.pb.bash
#########################################################################
# >>>   .pb.bash                                                       	#
#-----------------------------------------------------------------------#
# bash framework for executing PushBullet operations using https API	#
#########################################################################

# Specifically for Pushbullet API related aliases and functions

TOKEN='1234567890abcdef1234567890abcdef'
DEVICE_A_IDENT='1234567890abcdef12'

# Devices

# Get all information on devices
# Return unfiltered to stdout
pbdev() { curl -s -u ${TOKEN}: https://api.pushbullet.com/v2/devices ; }

# Get all information on devices, 
# Return filtered output based on $1 (should be valid fieldname):
pbdevx() { curl -s -u ${TOKEN}: https://api.pushbullet.com/v2/devices | grep -Po "\"$@\":.*?[^\\\\]\","; }

# Me

# Get all information on me 
# Return filtered output based on $1 (should be valid fieldname):
pbme() { curl -s -u ${TOKEN}: https://api.pushbullet.com/v2/users/me | grep -Po "\"$@\":.*?[^\\\\]\","; }

# Contacts

# Get all information on contacts
# Return unfiltered to stdout
pbcon() { curl -s -u ${TOKEN}: https://api.pushbullet.com/v2/contacts ; }

# Push Notifications

# Test (to all devices)
pbpushtest() { curl -s -u ${TOKEN}: -X POST https://api.pushbullet.com/v2/pushes --header 'Content-Type: application/json' --data-binary '{"type": "note", "title": "Note Title", "body": "Note Body"}'; }

# Broadcast note (to all devices)
pbnote() { curl -s -u ${TOKEN}: -X POST https://api.pushbullet.com/v2/pushes --header 'Content-Type: application/json' --data-binary "{\"type\": \"note\", \"title\": \"$1\", \"body\": \"$2\"}"; }

# Note to Device A
pbnotenx() { curl -s -u ${TOKEN}: -X POST https://api.pushbullet.com/v2/pushes --header 'Content-Type: application/json' --data-binary "{\"type\": \"note\", \"title\": \"$1\", \"body\": \"$2\", \"device_iden\": \"${DEVICE_A_IDENT}\"}"; }
