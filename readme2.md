# require

An improvised implementation of require because of the preposterous decision to not include it ComputerCraft by default. This implementation replicates the require-function usually included in Lua. Additionally it can also load APIs written for os.loadAPI() by checking the "global" environment of the API.


## Disadvantages of os.loadAPI()

- Import path must be absolute
- Variable name depends on filename
- API is loaded into global namespace
- Everything non-local is included, instead of a defined return value


## Behaviour of require

*This is just a quick overview. For more details see the [Lua Reference Manual][1] or [Programming in Lua][2] Guide

The require function takes in the module path as string, where dots represent slashes.

	local mymod = require ("path.to.mymodule")

When searching a file, the following locations are checked:

	?
	?/init
	/apis/?
	/apis/?/init
	/rom/apis/?
	/rom/apis/?/init

where ? denotes the resolved module path.

If no matching file is found, or it contains or causes errors, then require will raise an error itself, and won't try to load this same module again until restart.
Otherwise, the module will be loaded and returned, and its value gets cached in package.loaded[name] until restart.


[1]: https://www.lua.org/manual/5.3/manual.html#6.3
[2]: https://www.lua.org/pil/8.1.html