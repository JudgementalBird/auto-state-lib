### What is this?
This collection of functions provides a reliable way to very easily use functionality that requires persistent information, ***without setup***. The only price you pay in convenience, is needing to provide a unique identifier where you use these functions.

Example: Your self landing rocket needs to know its closing velocity with the ground. You can simply call the delta() function with no setup:
```lua
-- assuming delta function included outside onTick
function onTick()
	closing_velocity = delta(input.getNumber(1),"cv") -- "cv" is the unique identifier I gave here
end
```
Normally, if you want to take the delta of a value from tick to tick, you might do something like this instead:
```lua
old_distance=0
closing_velocity=0
function onTick()
  distance = input.getNumber(whatever)
  closing_velocity = distance - old_distance
  old_distance = distance
  -- and there you have closing_velocity
end
```
### Why this?
Why not just write that code yourself instead of throwing fat functions into your scripts? Just convenience. Writing it yourself will likely reduce your character count unless you make many calls. (ie if you have 20 of the pids from this lib running)
The example I showed was simple, but for more complicated (and changing) things (like developing something with 5, no wait, 6 PIDs, wait, actually just 4) it quickly gets clunky and annoying to manage + keep track of.
Another thing to mention, there have been class/object-based approaches in which you instantiate an object outside onTick() and then use it in onTick. They are nice because you don't provide an identifier (except the variable name) each time you use it, but it is too much friction and needless object orientation for my preference. That's why I made these functions.

### How does it work?
All persistent data is stored in one global table; `_AUTOSTATE_DATA`. Each time you use a function, you provide a unique identifier (spot) which is used to refer to a new sub-table inside that table. The sub-table holds all persistent data related to that function call, so for example, a call to `delta()` with a unique identifier will create this sub-table exactly: `{oldVar = 0,deltaVar = 0}`

This means you do need to provide a unique identifier across different self 
```lua
-- assuming delta function included outside onTick
function onTick()
	something = delta(input.getNumber(1),"a") --shorthands are fine
	somethingelse = delta(input.getNumber(2),"bingus") -- whole words are fine
	anotherthing = delta(input.getNumber(3),50) -- so are numbers, but it is easier to understand when you're using shorthands
	
	-- the IMPORTANT part is that you give a unique identifier each place.
	thisthing = delta(input.getNumber(4),"awd")
	thatthing = delta(input.getNumber(5),"awd") -- this will mess with both `thisthing` and `thatthing`, don't do this !
end
```

I can't think of a reason in the world why you would intentionally use a boolean, a function, a table, or a float, as unique identifiers for these functions, so I restricted the 'spot' or 'unique identifier' to string|integer to let Lua LLS catch more bugs. The code is only tested for those two, but it *should* work for the rest, so you *can* ignore the warnings if you want.

### Contributing
`spot` should always be the last input variable, unless there are optional parameters. They should be listed after `spot`.
Template with explanation: (when I write 'unique function call' I mean a function call with a unique identifier)
Remember, we have minifiers!
```lua
---@section function_name
function function_name(input1,input2,spot,optional1,optional2) --as many required parameters as we want, then spot, then as many optional parameters as we want.
	if not _AUTOSTATE_DATA then --if the table that holds the tables for each unique function call's persistent values doesn't exist:  (confused? see https://www.lua.org/pil/2.2.html)
		_AUTOSTATE_DATA = {}
		_AUTOSTATE_DATA[spot] = {variable1=whatever,variable2=whatever} --creates the sub-table that holds this unique function call's persistent values. This is where you initialize persistent values.
	elseif not _AUTOSTATE_DATA[spot] then --if an autostate function has been called, but not with this unique identifier:
		_AUTOSTATE_DATA[spot] = {variable1=whatever,variable2=whatever} --just the second initialization step from above
	end
	--in place of this comment goes whatever code should run each time
	--function parameters can be accessed directly by the names we gave them earlier (ie `input1`, `input2`, `optional1`, `optional2`, etc)
	--persistent values are located in `_AUTOSTATE_DATA[spot]`. Ie `_AUTOSTATE_DATA[spot].variable1`

	return --put return values in place of this comment
end
---@endsection
```
Concise template:
```lua
---@section function_name
function function_name(input1,input2,spot)
	if not _AUTOSTATE_DATA then
		_AUTOSTATE_DATA = {}
		_AUTOSTATE_DATA[spot] = {variable1=stuff, variable2=stuff}
	elseif not _AUTOSTATE_DATA[spot] then
		_AUTOSTATE_DATA[spot] = {variable1=stuff, variable2=stuff}
	end
	--in place of this comment goes whatever code should run each time
	return --stuff
end
---@endsection
```