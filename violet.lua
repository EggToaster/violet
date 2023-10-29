local args={...}
local version = 1.01
fs.makeDir("/violet/")
fs.makeDir("/bin/")
fs.makeDir("/lib/")
fs.makeDir("/pkgdata/")
print("Violet package manager")
print("Version "..version)
local wget = function(url,dir)
	local wao = http.get(url).readAll()
	local file = fs.open(dir,"w")
	file.write(wao)
	file.close()
end
local tablecontains = function(tbl,v)
	for i = 1,#tbl do
		if tbl[i]==v then
			return(true)
		end
	end
	return(false)
end
local install = function(pkname,repo)
	local repocache = "/violet/repo/cache/"..repo.."/"
	local repofile = fs.open("/violet/repo/"..repo..".vrepo","r")
	local repourl = repofile.readAll()
	repofile.close()
	local temp = "/violet/temp/"
	fs.makeDir(temp)
	print("Installing "..pkname)
	wget(repourl.."packages/"..pkname.."/install.lua",temp.."install.lua")
	local pkinfo = require(repocache..pkname.."/".."info")
	if #pkinfo.file.bin ~= 0 then
		for i = 1,#pkinfo.file.bin do
			local fl = pkinfo.file.bin[i]
			wget(repourl.."packages/"..pkname.."/bin/"..fl,"/bin/"..fl)
		end
	end
	if #pkinfo.file.lib ~= 0 then
		for i = 1,#pkinfo.file.lib do
			local fl = pkinfo.file.lib[i]
			wget(repourl.."packages/"..pkname.."/lib/"..fl,"/lib/"..fl)
		end
	end
	if #pkinfo.file.pkgdata ~= 0 then
		for i = 1,#pkinfo.file.pkgdata do
			local fl = pkinfo.file.pkgdata[i]
			wget(repourl.."packages/"..pkname.."/pkgdata/"..fl,"/pkgdata/"..fl)
		end
	end
	require(temp.."install")
	fs.delete(temp)
	wget(repourl.."packages/"..pkname.."/uninstall.lua","/violet/uninstall/"..pkname..".lua")
	print("Installed")
	local pkginlist = fs.open("/violet/pkglist.violet","a")
	pkginlist.writeLine(pkname)
	wget(repourl.."packages/"..pkname.."/info.lua","/violet/info/"..pkname..".lua")
	if fs.exists("/violet/runafterinstall.lua") then
		require("/violet/runafterinstall")
	end
end
if args[1]=="update" then
	local ipkg = fs.open("/violet/pkglist.violet","a")
	ipkg.close()
	if fs.exists("/violet/repo/") then
		local repofiles = fs.find("/violet/repo/*.vrepo")
		if #repofiles == 0 then
			print("Repo files are gone,add with 'violet repo add <name> <url>'")
		else
			print("Fetching info...")
			for i = 1,#repofiles do
				local repofilename = fs.getName(repofiles[i])
				repofilename = string.gsub(repofilename,".vrepo","")
				local repocachedir = "/violet/repo/cache/"..repofilename.."/"
				local repofile = fs.open(repofiles[i],"r")
				local repourl = repofile.readAll()
				repofile.close()
				print(repofilename.." "..repourl)
				fs.makeDir(repocachedir)
				wget(repourl.."info.lua",repocachedir.."info.lua")
				local repoinfo = require(repocachedir.."info")
				print("Repo name is "..repoinfo.name.." version "..tostring(repoinfo.ver))
				if tonumber(repoinfo.ver)>version then
					print("Repo version "..repoinfo.ver.." is newer than current violet version "..version..", ignoring")
				else
					print("Fetching Package List")
					local repopkgdata = {}
					wget(repourl.."packages/list.lua",repocachedir.."list.lua")
					local repopkglist = require(repocachedir.."list")
					for ii = 1,#repopkglist do
						local pkgname = repopkglist[ii]
						fs.makeDir(repocachedir..pkgname)
						wget(repourl.."packages/"..pkgname.."/info.lua",repocachedir..pkgname.."/info.lua")
						local pkgdetail = require(repocachedir..pkgname.."/info")
						repopkgdata[pkgname] = pkgdetail 
					end
					
				end
			end
		end
	else
		print("Repo folder doesnt exist, add repo with 'violet repo add <name> <url>'")
	end
end

if args[1]=="install" then
	local pkl = fs.open("/violet/pkglist.violet","r")
	local pklis = {}
	local wao = true
	while wao do
		local tmp = pkl.readLine()
		if tmp ~= nil then
			table.insert(pklis,tmp)
		else
			wao = false
		end
	end
	pkl.close()
	if tablecontains(pklis,args[2]) then
		print("Already installed")
	else
	local avplace = fs.find("/violet/repo/cache/*/"..args[2])
	local installed = false
	if #avplace ~= 0 then for i = 1,1 do
		local nowp = avplace[i]
		local reponame = string.gsub(string.gsub(nowp,"/"..args[2],""),"violet/repo/cache/","")
		local repofile = fs.open("/violet/repo/"..reponame..".vrepo","r")
		local repocache = "/violet/repo/cache/"..reponame.."/"
		local repourl = repofile.read()
		repofile.close()
		print("Found")
		local pkgdetail = require(repocache..args[2].."/info")
		local dependlist = {}
		local founddepend = true
		if #pkgdetail.depends ~= 0 then
			print("Searching for depends")
			for ii = 1,#pkgdetail.depends do
				local founddp = false
				local thisdepend = pkgdetail.depends[1].id
				local thisdpv = pkgdetail.depends[1].ver
				local avaplace = fs.find("/violet/repo/cache/*/"..thisdepend)
				for iii = 1,#avaplace do
					local nowdp = avaplace[iii]
					local dpreponame = string.gsub(string.gsub(nowp,"/"..thisdepend,""),"violet/repo/cache/","")
					local dprepocache = "/violet/repo/cache/"..dpreponame.."/"
					local dprepofile = fs.open("/violet/repo/"..dpreponame..".vrepo","r")
					local dprepourl = dprepofile.read()
					dprepofile.close()
					local dppkg = require(dprepocache..thisdepend.."/info")
					if not (tonumber(dppkg.ver) < tonumber(thisdpv)) then
						if not tablecontains(pklis,thisdepend) then
						table.insert(dependlist,{id=thisdepend,repo=dpreponame})
						end
						founddp = true
						break
					end
				end
				if not founddp then
					founddepend = false
					print("Dependends not found.")
					print("Try 'violet update' first")
					break
				end
			end
		end
		if founddepend then
			print("Preparing...")
			local installing = {}
			table.insert(installing,args[2])
			for i = 1,#dependlist do
				table.instert(installing,dependlist[i].id)
			end
			print("Following PKG will install")
			local insttext = ""
			for i = 1,#installing do
				insttext = insttext.." "..installing[i]
			end
			print(insttext)
			print("Continue? [y/any other key]")
			local enterpressed = false
			local y = true
			local somethingentered = false
			while not enterpressed do
				local event, key = os.pullEvent("key")
				if key == keys.enter then
					enterpressed=true
				else
					somethingentered = true
					if key ~= keys.y then
						y = false
					end
				end
			end
			if y and somethingentered then
				print("Installing")
				for i = 1,#dependlist do
					install(dependlist[i].id,dependlist[i].repo)
				end
				install(args[2],reponame)
			else
				print("Aborted")
			end
			installed=true
		else
			installed=true
			print("Installation aborted")
		end
	end end
	if not installed then
		print("Package not found.")
	end
	end
end

if args[1]=="remove" then
	local pkl = fs.open("/violet/pkglist.violet","r")
	local pklis = {}
	local wao = true
	while wao do
		local tmp = pkl.readLine()
		if tmp ~= nil then
			table.insert(pklis,tmp)
		else
			wao = false
		end
	end
	pkl.close()
	local install = false
	if tablecontains(pklis,args[2]) then
		print("Preparing...")
		print("Following PKG will DELETE")
		print(args[2])
		print("Continue? [y/any other key]")
		local enterpressed = false
		local y = true
		local somethingentered = false
		while not enterpressed do
			local event, key = os.pullEvent("key")
			if key == keys.enter then
				enterpressed=true
			else
				somethingentered = true
				if key ~= keys.y then
					y = false
				end
			end
		end
		if y and somethingentered then
			print("Removing")
			require("/violet/uninstall/"..args[2])
			fs.delete("/violet/uninstall/"..args[2]..".lua")
			local pkinfo = require("/violet/info/"..args[2])
			if #pkinfo.file.bin ~= 0 then
				for i = 1,#pkinfo.file.bin do
					local fl = pkinfo.file.bin[i]
					fs.delete("/bin/"..fl)
				end
			end
			if #pkinfo.file.lib ~= 0 then
				for i = 1,#pkinfo.file.lib do
					local fl = pkinfo.file.lib[i]
					fs.delete("/lib/"..fl)
				end
			end
			if #pkinfo.file.pkgdata ~= 0 then
				for i = 1,#pkinfo.file.pkgdata do
					local fl = pkinfo.file.pkgdata[i]
					fs.delete("/pkgdata/"..fl)
				end
			end
			fs.delete("/violet/info/"..args[2]..".lua")
			local pkgfl = fs.open("/violet/pkglist.violet","w")
			for i = 1,#pklis do
				if pklis[i] == args[2] then
					table.remove(pklis,i)
					break
				end
			end
			for i = 1,#pklis do
				pkgfl.writeLine(pklis[i])
			end
			pkgfl.close()
			print("Uninstalled")
		else
			print("Aborted")
		end
		installed=true
	end
	if not installed then
		print("Package not found.")
	end
end

if args[1]=="repo" then
	if args[2]=="add" then
		fs.makeDir("/violet/repo/")
		fs.makeDir("/violet/repo/cache")
		local repofile = fs.open("/violet/repo/"..args[3]..".vrepo","w")
		repofile.write(args[4])
		repofile.close()
		print("repo added")
	end
	if args[2]=="remove" then
		fs.delete("/violet/repo/"..args[3]..".vrepo")
		print("repo removed")
	end
end

if args[1] == "list" then
	local pkl = fs.open("/violet/pkglist.violet","r")
	local pklis = {}
	local wao = true
	while wao do
		local tmp = pkl.readLine()
		if tmp ~= nil then
			table.insert(pklis,tmp)
		else
			wao = false
		end
	end
	pkl.close()
	print("installed packages:")
	local pktxt = ""
	for i = 1,#pklis do
		if not (i==1) then
			pktxt = pktxt .. " "
		end
		pktxt = pktxt .. pklis[i]
	end
	print(pktxt)
end
