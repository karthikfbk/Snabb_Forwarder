module(..., package.seeall)
local Simpleforwarder = require("program.forwarder.simpleforwarder")

local engine    = require("core.app")
local config    = require("core.config")
local timer     = require("core.timer")
local pci       = require("lib.hardware.pci")

local Intel82599 = require("apps.intel.intel_app").Intel82599
local main      = require("core.main")
local lib = require("core.lib")


function run (parameters)
   if not (#parameters == 4) then
      print("Usage: forwarder <input PCI Bus:Device.function> <output PCI Bus:Device.function> <No Of Forwarding apps> <Direction 'B' or 'S'")
      main.exit(1)
   end
   local inputportpattern = parameters[1]
   local outputportpattern = parameters[2]
   local NoOfHops = tonumber(parameters[3])
   local direction = parameters[4]

   if inputportpattern == outputportpattern and direction == 'B' then
	print("Bidirectional forwarding is not possible with same input and output port")
	return
   end
	
   local defaultforwarderfwdstart = "Frwd_fHead"
   local defaultforwarderbkwdstart = "Frwd_bHead"

   local c = config.new()
   print("Scanning PCI devices ...")
   pci.scan_devices()

   if inputportpattern == outputportpattern then

	--If inputport and output port are same, then it should be single direction forwarder
	print("Configuring app network ...")

	config.app(c, defaultforwarderfwdstart, Simpleforwarder.Simpleforwarder)

   	local Interfaceapp = "ioIntel82599"
   	local assigned = 0
   	for _,device in ipairs(pci.devices) do
   	   if is_device_suitable(device, inputportpattern) then
   	      config.app(c, Interfaceapp, Intel82599, { pciaddr=device.pciaddress})
	      print("Linking app "..Interfaceapp.." and "..defaultforwarderfwdstart)
   	      config.link(c,Interfaceapp..".tx -> "..defaultforwarderfwdstart..".input")
	      assigned = 1
   	   end
   	end
   	assert(assigned >0," PCI Device does not match any suitable device")

	BuildandLinkInterface(c,defaultforwarderfwdstart,Interfaceapp,NoOfHops,'Frwd_To')		
		
   else
	--If inputport and output port are not same, it can be either single direction or bi-directional forwarder

	 print("Configuring app network ...")
	 config.app(c, defaultforwarderfwdstart, Simpleforwarder.Simpleforwarder)

	 local iInterfaceapp = "iIntel82599"
	 local assigned = 0
	 for _,device in ipairs(pci.devices) do
	    if is_device_suitable(device, inputportpattern) then
	       config.app(c, iInterfaceapp, Intel82599, { pciaddr=device.pciaddress})	       
	       assigned = 1
	    end
	  end	
	assert(assigned >0," PCI Device does not match any suitable device")
	
	 local oInterfaceapp = "oIntel82599"
	 local assigned = 0
	 for _,device in ipairs(pci.devices) do
	    if is_device_suitable(device, outputportpattern) then
	       config.app(c, oInterfaceapp, Intel82599, { pciaddr=device.pciaddress})	     
	       assigned = 1
	    end
	  end	
	assert(assigned >0," PCI Device does not match any suitable device")

	print("Linking app "..iInterfaceapp.." and "..defaultforwarderfwdstart)
	config.link(c,iInterfaceapp..".tx -> "..defaultforwarderfwdstart..".input")

	BuildandLinkInterface(c,defaultforwarderfwdstart,oInterfaceapp,NoOfHops,'Frwd_To')	
	
	if direction == 'B' then
		config.app(c, defaultforwarderbkwdstart, Simpleforwarder.Simpleforwarder)
		print("Linking app "..oInterfaceapp.." and "..defaultforwarderbkwdstart)
		config.link(c,oInterfaceapp..".tx -> "..defaultforwarderbkwdstart..".input")

		BuildandLinkInterface(c,defaultforwarderbkwdstart,iInterfaceapp,NoOfHops,'Frwd_Fro')
	end
		
   end

   
   engine.configure(c)
   local dir

   if direction == 'S' then
	dir = 'Single'
   else
	dir = 'Bi'
   end
   print("Forwarder is running with input interface "..inputportpattern.." output interface "..outputportpattern.. " and "..NoOfHops.." forwarding chain apps in "..dir.." Direction")
   engine.main()
end

function BuildandLinkInterface(c,forwarder, Interface, NoOfHops,appname)

	if NoOfHops > 0 then
			local lastforwarder = BuildForwarderSingleDirection(c,forwarder, NoOfHops,appname)
			print("Linking app "..lastforwarder.. " and "..Interface)
			config.link(c, lastforwarder..".output ->"..Interface..".rx")
		else 
			print("Linking app "..forwarder.. " and "..Interface)
			config.link(c, forwarder..".output ->"..Interface..".rx")
	end

end

function BuildForwarderSingleDirection(c,defaultforwarderfwd, NoOfHops,appname)
	if NoOfHops > 0 then
		local lastapp = defaultforwarderfwd
		
		for i=1,NoOfHops do
			local applink = appname..i
			config.app(c,applink, Simpleforwarder.Simpleforwarder)
			print("Linking app "..lastapp.." and "..applink)
			config.link(c,lastapp..".output ->"..applink..".input")			
			lastapp = applink			
   		end
		
		return lastapp
	end
end

function is_device_suitable (pcidev, patterns)
   if not pcidev.usable or pcidev.driver ~= 'apps.intel.intel_app' then
      return false
   end 
   
   if pci.qualified(pcidev.pciaddress):gmatch(patterns)() then
         return true
   else
		--print("PCI "..pcidev.pciaddress.." does not match any suitable device")
		return false
   end
   
end
