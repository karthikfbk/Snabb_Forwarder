-- This is a simple forwarding snabbswitch app --

HOW TO RUN:
-- Copy the folder 'forwarder' containing files 'forwarder.lua' and 'simpleforwarder.lua' to "base_directory_of_snabbswitch/src/program/"

-- Go to base directory of snabbswitch and run 'make -j'

-- To run the forwarder app from base directory of snabbswitch,
	./src/snabb forwarder <PCI Input> <PCI Output> <No Of Forwarding apps>

Example 1: 
./src/snabb forwarder 0000:02:00.0 0000:02:00.1 0

The structure of APP network for the above example would be

0000:02:00.0-->Intel82599--> forwarder-->Intel82599-->0000:02:00.1


Example 2: 
./src/snabb forwarder 0000:02:00.0 0000:02:00.1 2

The structure of APP network for the above example would be

0000:02:00.0-->Intel82599--> forwarder-->forwarder1--> forwarder2-->Intel82599-->0000:02:00.1

