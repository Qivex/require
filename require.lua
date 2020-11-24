--[[
Inspired by:
https://www.lua.org/pil/8.1.html
https://www.lua.org/manual/5.3/manual.html#6.3
https://bitbucket.org/openshell/cc-require/src/default/assets/computercraft/lua/rom/autorun/require.lua
]]


-- CONSTANTS
local MODULE_SEPERATOR_PATTERN = "%."
local PATH_SEPERATOR_PATTERN = "/"
local PATH_PLACEHOLDER_PATTERN = "#"
local CURRENTDIR_PLACEHOLDER_PATTERN = "?"

local ALLOWED_PATHS = {
	-- Local Files
	"?#",
	"?#/init",
	-- Global APIs
	"/apis/#",
	"/apis/#/init",
	-- OS APIs
	"/rom/apis/#",
	"/rom/apis/#/init"
}


-- IMPLEMENTATION
local getCurrentPath = function()
	-- Absolute path to program
	local program_path = PATH_SEPERATOR_PATTERN .. shell.getRunningProgram()
	-- Parent dir
	local parent_dir = program_path:match(PATH_SEPERATOR_PATTERN .. ".*" .. PATH_SEPERATOR_PATTERN) or PATH_SEPERATOR_PATTERN
	return parent_dir
end

local createPathLoader = function(module_name, file)
	local path_loader = function(module_name)
		-- Setup environment
		local env = {}
		setmetatable(env, {__index = _G})	-- required to still reach global functions like "pairs"
		-- Get a compiled chunk from file content
		local chunk, compile_error = loadfile(file)
		if not chunk then
			error("File '"..file.."' is not valid.\n\nDetails:\n" .. compile_error, 3)
		else
			setfenv(chunk, env)
		end
		-- Call the chunk to execute its content
		local ok, content = pcall(chunk)
		if not ok then
			error("Required file '" .. file .. "' could not be executed.\n\nCaused by:\n" .. content, 3)
		else
			local api = {}
			if content then
				-- Add content from "return" statement (default style)
				api = content
			else
				-- Add content from environment (old API style)
				for key, value in pairs(env) do
					api[key] = value
				end
			end
			return api
		end
	end
	return path_loader
end

local preload_searcher = function(module_name)
	if package.preload[module_name] then
		return package.preload[module_name]
	end
	return "- Loading using Preload failed: No field '" .. module_name .. "' in package.preload"
end

local path_searcher = function(module_name)
	local missing_files = {}
	local relative_path = module_name:gsub(MODULE_SEPERATOR_PATTERN, PATH_SEPERATOR_PATTERN)
	-- Check all allowed paths (and replace placeholder with current dir)
	for path in package.path:gsub(CURRENTDIR_PLACEHOLDER_PATTERN, getCurrentPath()):gmatch("[^;]+") do
		-- Build path
		local check_path = path:gsub(PATH_PLACEHOLDER_PATTERN, relative_path)
		if (fs.exists(check_path) == true) and (fs.isDir(check_path) == false) then
			return createPathLoader(module_name, check_path)
		else
			table.insert(missing_files, check_path)
		end
	
	end
	return "- Loading from Path failed. Missing files:\n\t" .. table.concat(missing_files, "\n\t")
end

local package = {
	loaded = {},
	preload = {},
	path = table.concat(ALLOWED_PATHS, ";"),
	searchers = {
		preload_searcher,
		path_searcher
		-- OPTIONAL dir_searcher: loads entire dir assuming default inits
		-- OPTIONAL github_searcher: download missing files from github
	}
}

local require = function(module_name, force_refresh)
	local errors = {}
	-- Check if previously loaded
	if package.loaded[module_name] and not force_refresh then
		return package.loaded[module_name]
	end
	-- Execute available searchers
	for _, searcher in pairs(package.searchers) do
		local loader = searcher(module_name)
		-- Check if searcher actually found a loader
		if (type(loader) == "function") then
			-- Load the module using the loader
			local loader_output = loader(module_name)
			-- Check if module loaded correctly
			if (loader_output ~= nil) then
				package.loaded[module_name] = loader_output
			elseif (package.loaded[module_name] == nil) then
				-- If loading failed prevent future loads of same module
				package.loaded[module_name] = true
			end
			return package.loaded[module_name]
		elseif (type(loader) == "string") then
			-- Searcher returned an error
			local searcher_errormessage = loader
			table.insert(errors, searcher_errormessage)
			
		end
	end
	-- Display errors from all searchers
	error("Module '" .. module_name .. "' was not loaded correctly.\n\nDetails:\n" .. table.concat(errors, "\n"), 2)
end


-- EXPORT
if not _G.package then
	_G.package = package
end
if not _G.require then
	_G.require = require
end
