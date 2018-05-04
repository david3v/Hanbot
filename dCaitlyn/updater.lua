--[[

	DEBUG VERSION

--]]



--Credits : Avada

local json = module.load("dCaitlyn", "json")

local updater = {}

updater.update = false
updater.error = function(str)
	console.set_color(004)
	print("[DD Update ERROR] " .. tostring(str))
	console.set_color(015)
end

updater.print = function(str)
	print("[DD Update] " .. tostring(str))
end

updater.davidev_update = function(script_name, local_version, cpath_x)
	updater.print("Init")
	
	if(not script_name)then
		updater.error("Script name missing")
		return
	end
	
	if(not local_version)then
		updater.error("local_version name missing")
		return
	end
	
	if(not cpath_x)then
		updater.error("cpath_x name missing")
		return
	end
	
	local base_folder = cpath_x .. '/'..script_name..'/'
	
	local local_files = updater.scandir(base_folder)
	--https://raw.githubusercontent.com/david3v/Hanbot/master/dCaitlyn/main.lua
	local remote_data_r , rm_err, rm_msg = network.send('https://raw.githubusercontent.com/david3v/Hanbot/master/' .. script_name .. '/update.json',{
		method = 'GET'
	})
	
	if(type(remote_data_r) ~= 'table')then
		updater.error("Unexpected error")
		updater.error(rm_err)
		updater.error(rm_msg)
		return
	end
	
	if(remote_data_r.code ~= "200")then
		updater.error("Failed for " .. script_name)
		return
	end
	
	local remote_data = json.parse(remote_data_r.body)
	local remote_files = remote_data["files"]
	local remote_version = remote_data["version"]
		
	
	if(not remote_version or (not type(remote_version) == 'string' and not type(remote_version) == 'number'))then
		updater.error("Couldn't find remote version")
		return
	end
	
	if(not type(local_version) == 'number' and not type(local_version) == 'string')then
		updater.error("Couldn't find local version")
		return
	end
	
	if(tonumber(local_version) >= tonumber(remote_version))then
		updater.print("You already have the latest version [" .. local_version .. "] @ " .. script_name)
		return
	end
	updater.update = true
	updater.print("Downloading update [" .. local_version .. " => " .. remote_version .. "]")
	
	
	--
	local remote_only = {}
	local local_only = {}
	local unchanged = {}
	local diff = {}
	
	remote_only = remote_files
	for k,v in pairs(local_files)do
		local s_name = v:gsub(base_folder,'')
		if(remote_files[s_name])then
			local l_md5sum = md5.file(v)
			local remote_md5sum = remote_files[s_name]
			
			if(l_md5sum == remote_md5sum)then
				unchanged[s_name] = md5.file(v)			
			else
				diff[s_name] = md5.file(v) .. " <> " .. remote_md5sum		
			end
			
			remote_only[s_name] = nil
		else
			local_only[s_name] = md5.file(v)
		end
	end
	
	
	print("")
	print("========================")
	print("||== DD Update log == ||")
	print("|| " .. script_name .. " ||")
	print("========================")
	
	
	print("")
	print("=== Remote only ===")
	for k,v in pairs(remote_only)do
		print("\t" .. k .. " : " .. v)
	end
	
	
	print("")
	print("=== Local only ===")
	for k,v in pairs(local_only)do
		print("\t" .. k .. " : " .. v)
	end
	
	print("")
	print("=== Unchanged ===")
	for k,v in pairs(unchanged)do
		print("\t" .. k .. " : " .. v)
	end
	
	print("")
	print("=== Diff ===")
	for k,v in pairs(diff)do
		print("\t" .. k .. " : " .. v)
	end
	
	--Delete local only files
	print("")
	print("Deleting: ")
	for k,v in pairs(local_only)do
		print("\t" .. k)
		updater.delete_file(base_folder, k)
	end
	--https://raw.githubusercontent.com/david3v/Hanbot/master/dCaitlyn/main.lua
	local base_url = "https://raw.githubusercontent.com/david3v/Hanbot/master/" .. script_name .. "/"
	--local base_url = "https://git.soontm.net/avada/" .. script_name .. "/raw/branch/master/"
	
	print("")
	print("Downloading: ")
	for k,v in pairs(diff)do
		print("\t" .. k)
		network.download_file(base_url .. k, base_folder .. k)
	end
	
	--Download remote only	
	for k,v in pairs(remote_only)do
		print("\t" .. k)
		updater.make_sure_path_exists(base_folder,k)
		network.download_file(base_url .. k, base_folder .. k)
	end
	
	
end

--Vulnerable to command injection :kappa:
function updater.delete_file(base_folder, filename)
	local lpath = base_folder .. filename
	lpath = lpath:gsub("/","\\")
	io.popen('del /Q /F "' .. lpath .. '"')
end

--Vulnerable to command injection :kappa:
function updater.make_sure_path_exists(base_folder,path)
	local xpath = string.match(path, "(.-)([^\\/]-%.?([^%.\\/]*))$")
	local file = assert(io.popen('MD "' .. base_folder ..xpath .. '"'))
	local output = file:read('*all')
	file:close()
end

--Vulnerable to command injection :kappa:
function updater.scandir(directory)
	local i, files, popen = 0, {}, io.popen
    local pfile = popen('dir /B /a-d "'..directory..'"')
    for filename in pfile:lines() do
        i = i + 1
        files[i] = directory .. filename
    end
    pfile:close()
    local i, directories, popen = 0, {}, io.popen
    local pfile = popen('dir /B /ad "'..directory..'"')
    for filename in pfile:lines() do
        i = i + 1
		if(filename ~= ".git")then
			local x = updater.scandir(directory..filename .."/")
			for k,v in pairs(x) do
				files[#files+1] = v
			end
		end
    end
    pfile:close()
	return files
end

return updater