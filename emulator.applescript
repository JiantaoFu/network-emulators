#!/usr/bin/osascript 

# helper function for command parameters
on stringSplit(str, delimiters)
	# save delimiters to restore old settings
	set oldDelimiters to AppleScript's text item delimiters
	# set delimiters to delimiter to be used
	set AppleScript's text item delimiters to delimiters
	# create the array
	set splitedArray to every text item of str
	# restore the old setting
	set AppleScript's text item delimiters to oldDelimiters
	# return the result
	return splitedArray
end stringSplit


# Open Network Link Conditioner
on openNetworkEmulator()
	tell application "System Preferences"
		activate
		set the current pane to pane id "com.apple.Network-Link-Conditioner"
		delay 1
		
		tell window "Network Link Conditioner"
		end tell
	end tell
end openNetworkEmulator

on minimizeNetworkEmulator()
	tell application "System Events"
		tell process "System Preferences"		
#			set miniaturized of window "Network Link Conditioner" to true
			set visible to false
		end tell
	end tell 
end minimizeNetworkEmulator

# Close Network Link Conditioner
on closeNetworkEmulator()
	tell application "System Preferences" to quit
	delay 1
end closeNetworkEmulator


# Clear Network emulation
on clearNetworkEmulator()
	# use system events to control UI operation
	tell application "System Events"
		tell process "System Preferences"
			
			# Turn off switch
			# set enableSwitch to checkbox 2 of window "Network Link Conditioner"
			# tell enableSwitch
			# 	if its value is equal to 1 then click enableSwitch
			# 	delay 1
			# 	set value of enableSwitch to 0
			# 	delay 1
			# end tell
                        click button "OFF" of window "Network Link Conditioner"
			
			click button "Manage Profiles..." of window "Network Link Conditioner"
			
			tell window "Network Link Conditioner"
				
				# find QoSTest profile and delete it if any
				
				# UI elements of outline 1 of scroll area 1 of sheet 1		
				set outlineElems to outline 1 of scroll area 1 of sheet 1
				repeat with anElement in rows of outlineElems
					UI elements of anElement
					if (value of static text of anElement as text) is equal to "QoSTest" then
						#UI elements of anElement
						set selected of anElement to true
						# button 1 remove
						click button 1 of sheet 1
						exit repeat
					end if
				end repeat

				click button "OK" of sheet 1
			end tell # window
			
		end tell #process
	end tell # application
	
end clearNetworkEmulator


# Set Network emulation
on setNetworkEmulator(settings)
	# default values
	set {upDrops, upDelay, upBandwidth} to {"0", "0", "0"}
	set {downDrops, downDelay, downBandwidth} to {"0", "0", "0"}
	
	# get from settings if any
	try
		set upDrops to settings's uplinkDrops
	end try
	
	try
		set upDelay to settings's uplinkDelay
	end try
	
	try
		set upBandwidth to settings's uplinkBandwidth
	end try
	
	try
		set downDrops to settings's downlinkDrops
	end try
	
	try
		set downDelay to settings's downlinkDelay
	end try
	
	try
		set downBandwidth to settings's downlinkBandwidth
	end try
	
	# use system events to control UI operation
	tell application "System Events"
		tell process "System Preferences"
			
			click button "Manage Profiles..." of window "Network Link Conditioner"
			
			tell window "Network Link Conditioner"

                                set profileExist to false
				set outlineElems to outline 1 of scroll area 1 of sheet 1
				repeat with anElement in rows of outlineElems
					UI elements of anElement
					if (value of static text of anElement as text) is equal to "QoSTest" then
						#UI elements of anElement
						set selected of anElement to true
                                                set profileExist to true 
					end if
				end repeat
				
                                if not profileExist
                                        # button 2 add
				        click button 2 of sheet 1
				        delay 1
				        
				        # create QoSTest profile and set emulation settings
				        set value of text field 1 of sheet 1 of sheet 1 to "QoSTest"
				        click button "create" of sheet 1 of sheet 1
				        delay 1
                                end if
				
				# uplink drops
				set value of text field 1 of group 1 of sheet 1 to upDrops
				set focused of text field 1 of group 1 of sheet 1 to true
				
				# uplink delay
				set value of text field 2 of group 1 of sheet 1 to upDelay
				set focused of text field 2 of group 1 of sheet 1 to true
				
				# uplink bandwidth
				set value of text field 3 of group 1 of sheet 1 to upBandwidth
				set focused of text field 3 of group 1 of sheet 1 to true
				
				# downlink bandwidth
				set value of text field 4 of group 1 of sheet 1 to downBandwidth
				set focused of text field 4 of group 1 of sheet 1 to true
				
				# downlink delay
				set value of text field 5 of group 1 of sheet 1 to downDelay
				set focused of text field 5 of group 1 of sheet 1 to true
				
				# downlink drops
				set value of text field 6 of group 1 of sheet 1 to downDrops
				set focused of text field 6 of group 1 of sheet 1 to true
				
				click button "OK" of sheet 1
				
				# Turn on switch
				delay 1
				# set enableSwitch to checkbox 2
				# tell enableSwitch
				# 	if its value is equal to 0 then click enableSwitch
				# 	delay 1
				# 	set value of enableSwitch to 1
				# 	delay 1
				# end tell
                                click button "ON"
				
			end tell # window
			
		end tell # process
	end tell # application
	
end setNetworkEmulator


on parseSettings(settings)
	set downBandwidth to "0"
	set downDelay to "0"
	set downDrops to "0"
	set upBandwidth to "0"
	set upDelay to "0"
	set upDrops to "0"
	repeat with s in settings
		set params to stringSplit(s, "=")
		if length of params is equal to 2 then
			set k to item 1 of params
			set v to item 2 of params
			
			if k is equal to "downlinkDrops" then
				set downDrops to v
			else if k is equal to "downlinkBandwidth" then
				set downBandwidth to v
			else if k is equal to "downlinkDelay" then
				set downDelay to v
			else if k is equal to "uplinkDrops" then
				set upDrops to v
			else if k is equal to "uplinkBandwidth" then
				set upBandwidth to v
			else if k is equal to "uplinkDelay" then
				set upDelay to v
			end if
		end if
	end repeat
	return {downlinkDrops:downDrops,Â
	        downlinkBandwidth:downBandwidth,Â
	        downlinkDelay:downDelay,Â
                uplinkDrops:upDrops,Â
                uplinkBandwidth:upBandwidth,Â
                uplinkDelay:upDelay}

end parseSettings


on run argv
	set helpStr to "Usage: emulator.applescript[(start|change) params | stop]

params like:

	downlinkDrops=1        - set downlink packet drops to 1%

	downlinkBandwidth=1000 - set downlink bandwidth to 1000 kbps

	downlinkDelay=100      - set downlink delay to 100 ms

	uplinkDrops=1          - set uplink packet drops to 1%

	uplinkBandwidth=1000   - set uplink bandwidth to 1000 kbps

	uplinkDelay=100        - set uplink delay to 100 ms

"
	
	set action to "none"
	
	if length of argv is equal to 1 then
		if item 1 of argv is equal to "stop" then
			set action to "stop"
		end if
	else if length of argv is greater than 1 then
		if item 1 of argv is in {"start", "change"} then
                        set params to parseSettings(argv)
			set action to item 1 of argv
		end if
	end if
	
	if action is equal to "stop" then
		openNetworkEmulator()
	        clearNetworkEmulator()
		closeNetworkEmulator()
	else if action is equal to "start" then
		openNetworkEmulator()
	        clearNetworkEmulator()
                log params
                setNetworkEmulator(params)
		minimizeNetworkEmulator()
	else if action is equal to "change" then
		openNetworkEmulator()
                log params
                setNetworkEmulator(params)
		minimizeNetworkEmulator()
	else
		return helpStr
	end if 
end run
