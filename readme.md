# require

An improvised re-implementation of require - because of the **preposterous** decision to not include it in ComputerCraft by default.
Executing this program will give you a global `require` function, replicating the default Lua behaviour.
Additionally, it can also load APIs written for os.loadAPI() by checking the "global" environment of the API.


## Disadvantages of os.loadAPI()

- Import path must be absolute
- Variable name depends on filename
- API is loaded into global namespace
- Everything non-local is included, instead of a defined return value


## Behaviour of require

*This is just a quick overview. For more details see the [Lua Reference Manual][1] or [Programming in Lua][2] Guide*

The `require` function takes in the module path as string (where dots represent slashes), and returns the loaded module:

	local mymod = require("path.to.mymodule")

If no matching file is found, or it contains/causes errors, then `require` will raise an error itself and won't try to load this same module again.
Otherwise, the module will be loaded and returned, and its value gets cached in `package.loaded[name]` until restart.

When searching a file, the following locations are checked (`?` denotes the resolved module path):

	?
	?/init
	/apis/?
	/apis/?/init
	/rom/apis/?
	/rom/apis/?/init

An `init` file can be used to load multiple modules at once:

	-- In file "myapi/init":
	return {
		submodule = require "myapi.submodule",
		somefile = require "myapi.somefile"
	}


[1]: https://www.lua.org/manual/5.3/manual.html#6.3
[2]: https://www.lua.org/pil/8.1.html