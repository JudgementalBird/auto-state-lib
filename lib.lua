---@diagnostic disable: lowercase-global

---Take the delta of `var` between calls of this function, ie the change from tick to tick in common usage.
---@param var number
---@param spot string|integer
---@return number
---@section delta
function delta(var,spot)
  	if not _AUTOSTATE_DATA then
		_AUTOSTATE_DATA = {}
		_AUTOSTATE_DATA[spot] = {oldVar = 0,deltaVar = 0}
  	elseif not _AUTOSTATE_DATA[spot] then
		_AUTOSTATE_DATA[spot] = {oldVar = 0,deltaVar = 0}
	end
	_AUTOSTATE_DATA[spot].deltaVar = var - _AUTOSTATE_DATA[spot].oldVar
	_AUTOSTATE_DATA[spot].oldVar = var
  	return _AUTOSTATE_DATA[spot].deltaVar
end
---@endsection

---Like the pulse logic block. Outputs true only on first true call, after a false call.
---@param var boolean
---@param spot string|integer
---@section pulse
function pulse(var,spot)
  if not _AUTOSTATE_DATA then
    _AUTOSTATE_DATA = {}
    _AUTOSTATE_DATA[spot] = {pulse = false,touch = false}
  elseif not _AUTOSTATE_DATA[spot] then
    _AUTOSTATE_DATA[spot] = {pulse = false,touch = false}
  end
  _AUTOSTATE_DATA[spot].pulse = var ~= _AUTOSTATE_DATA[spot].touch and var
  _AUTOSTATE_DATA[spot].touch = var
  return _AUTOSTATE_DATA[spot].pulse
end
---@endsection

---@class tunes
---@field p number
---@field i number
---@field d number

---PID
---@param setpoint number
---@param processVar number
---@param tunes tunes
---@param spot string|integer
---@param integralClamp number|nil
---@section pid
function pid(setpoint,processVar,tunes,spot,integralClamp)
    if not _AUTOSTATE_DATA then
        _AUTOSTATE_DATA = {}
        _AUTOSTATE_DATA[spot] = {error=0,integral=0,derivative=0,errorPrior=0,integralPrior=0}
    elseif not _AUTOSTATE_DATA[spot] then
        _AUTOSTATE_DATA[spot] = {error=0,integral=0,derivative=0,errorPrior=0,integralPrior=0}
    end
	 local persist = _AUTOSTATE_DATA[spot]
    persist.error = setpoint - processVar
    if integralClamp then
    	persist.integral = math.max(math.min(persist.integralPrior + persist.error,integralClamp),-integralClamp)
    else
    	persist.integral = persist.integralPrior + persist.error
    end
    persist.derivative = persist.error - persist.errorPrior
    
    persist.controlOutput = tunes.p * persist.error + tunes.i * persist.integral + tunes.d * persist.derivative
    
    persist.errorPrior = persist.error
    persist.integralPrior = persist.integral
    
    return persist.controlOutput
end
---@endsection

---PID for looping systems (in turns) (helpful for for example controlling a velocity pivot)
---@param setpoint number
---@param processVar number
---@param tunes tunes
---@param spot string|integer
---@param integralClamp number|nil
---@section loop_pid
function loop_pid(setpoint,processVar,tunes,spot,integralClamp)
    if not _AUTOSTATE_DATA then
        _AUTOSTATE_DATA = {}
        _AUTOSTATE_DATA[spot] = {error=0,integral=0,derivative=0,errorPrior=0,integralPrior=0}
    elseif not _AUTOSTATE_DATA[spot] then
        _AUTOSTATE_DATA[spot] = {error=0,integral=0,derivative=0,errorPrior=0,integralPrior=0}
    end
	 local persist = _AUTOSTATE_DATA[spot]
    persist.error = ((setpoint - processVar)%1+1.5)%1-0.5
    if integralClamp then
    	persist.integral = math.max(math.min(persist.integralPrior + persist.error,integralClamp),-integralClamp)
    else
    	persist.integral = persist.integralPrior + persist.error
    end
    persist.derivative = persist.error - persist.errorPrior
    
    persist.controlOutput = tunes.p * persist.error + tunes.i * persist.integral + tunes.d * persist.derivative
    
    persist.errorPrior = persist.error
    persist.integralPrior = persist.integral
    
    return persist.controlOutput
end
---@endsection

---Beeper! If `bool` is true then it'll return true every `ticks` ticks, eg if `ticks` is 4 then there'll be 4 false ticks between each true tick
---@param bool boolean
---@param ticks integer
---@param spot string|integer
---@section beep
function beep(bool,ticks,spot)
	if not _AUTOSTATE_DATA then
		_AUTOSTATE_DATA = {}
		_AUTOSTATE_DATA[spot] = {i=0}
	elseif not _AUTOSTATE_DATA[spot] then
		_AUTOSTATE_DATA[spot] = {i=0}
	end
	local persist = _AUTOSTATE_DATA[spot]
	if bool then
		if persist.i >= ticks then
			persist.i = 0
			return true
		else
			persist.i = persist.i + 1
			return false
		end
	else
		persist.i = 0
		return false
	end
end
---@endsection

---beeper that uses handler function instead of a bool, and because the function can be expensive, it also lets you cache the result. 
---I have to be honest I don't even remember writing this and I have no idea why you would want it.
---@param handler function
---@param cacheticks integer
---@param beepticks integer
---@param spot string|integer
---@section handler_cached_beep
function handler_cached_beep(handler,cacheticks,beepticks,spot)
	if not _AUTOSTATE_DATA then
		_AUTOSTATE_DATA = {}
		_AUTOSTATE_DATA[spot] = {i=0,c=cacheticks,r=false}
	elseif not _AUTOSTATE_DATA[spot] then
		_AUTOSTATE_DATA[spot] = {i=0,c=cacheticks,r=false}
	end
	local persist = _AUTOSTATE_DATA[spot]

	--run handler and cache the result
	if persist.c >= cacheticks then
		--if cache timer has reached supplied cacheticks value, then:
		--reset cache timer to 0, call the handler, store the result to be used for return until we run the handler again
		persist.c = 0
		persist.r = handler()
	else
		--increment cache timer
		persist.c = persist.c + 1
	end

	--beep like normal using cached value instead of calling handler function every tick
	if persist.r then
		if persist.i >= beepticks then
			persist.i = 0
			return true
		else
			persist.i = persist.i + 1
			return false
		end
	else
		persist.i = 0
		return false
	end
end
---@endsection

---Should work like the capacitor logic block. `bool` is the input, `chargeTicks` & `dischargeTicks` are charge and discharge, but in ticks, not seconds. Will output true on the `chargeTicks`'th tick.
---@param bool boolean
---@param chargeTicks integer
---@param dischargeTicks integer
---@param spot string|integer
---@section capacitor
function capacitor(bool,chargeTicks,dischargeTicks,spot)
	if not _AUTOSTATE_DATA then
		_AUTOSTATE_DATA = {}
		_AUTOSTATE_DATA[spot] = {charge=0,discharge=0}
	elseif not _AUTOSTATE_DATA[spot] then
		_AUTOSTATE_DATA[spot] = {charge=0,discharge=0}
	end
	local persist = _AUTOSTATE_DATA[spot]

	if bool then
		persist.charge = math.min(persist.charge + 1,chargeTicks)
		persist.discharge = 0
		if persist.charge == chargeTicks then
			return true 
		else
			return false
		end
	else
		persist.discharge = math.min(persist.discharge + 1,dischargeTicks)
		persist.charge = 0
		if persist.discharge == dischargeTicks then
			return false 
		else
			return true
		end
	end
end
---@endsection

---advanced delta, takes the delta of var over ticks ticks, spot is spot
---@param var number
---@param ticks integer
---@param spot string|integer
---@section advanced_delta
function advanced_delta(var,ticks,spot)
	if not _AUTOSTATE_DATA then
		_AUTOSTATE_DATA={}
		_AUTOSTATE_DATA[spot]={deltaVar=0,last={}}
		for i=1,100 do
			_AUTOSTATE_DATA[spot].last[i]=0
		end
	elseif not _AUTOSTATE_DATA[spot] then
		_AUTOSTATE_DATA[spot]={deltaVar=0,last={}}
		for i=1,100 do
			_AUTOSTATE_DATA[spot].last[i]=0
		end
	end
	local persist = _AUTOSTATE_DATA[spot]
	persist.deltaVar=(var-persist.last[ticks])/ticks
	for i=100,2,-1 do
		persist.last[i]=persist.last[i-1]
	end
	persist.last[1]=var
	return persist.deltaVar
end
---@endsection

---Variable time rolling average.
---@param input number
---@param ticks integer
---@param spot string|integer
---@section variable_rolling_average
function variable_rolling_average(input,ticks,spot)
    if not _AUTOSTATE_DATA then
        _AUTOSTATE_DATA = {}
        _AUTOSTATE_DATA[spot] = {avgTable = {},result = 0,ticks = 0,sum = 0}
    elseif not _AUTOSTATE_DATA[spot] then
        _AUTOSTATE_DATA[spot] = {avgTable = {},result = 0,ticks = 0,sum = 0}
    end
	 local persist = _AUTOSTATE_DATA[spot]
    if ticks<2 then 
        persist.ticks=2
    else
        persist.ticks=ticks
    end
    table.insert(persist.avgTable,input)
    if #persist.avgTable > persist.ticks then
        table.remove(persist.avgTable,1)
    end
    persist.sum=0
    for key,value in pairs(persist.avgTable) do
        persist.sum=persist.sum+value
    end
    persist.result=persist.sum/#persist.avgTable
    return persist.result
end
---@endsection

---@param input number
---@param ticks integer
---@param spot string|integer
---@section rolling_buffer
function rolling_buffer(input,ticks,spot)
    if not _AUTOSTATE_DATA then
        _AUTOSTATE_DATA = {}
        _AUTOSTATE_DATA[spot] = {bufferTable={},ticks = 0}
    elseif not _AUTOSTATE_DATA[spot] then
        _AUTOSTATE_DATA[spot] = {bufferTable={},ticks = 0}
    end
	 local persist = _AUTOSTATE_DATA[spot]
    -- I find it the most logical to just return the input in the eventuality that ticks <= 1
    if ticks <= 0 then
        return input
    else
        persist.ticks = ticks+1
        
        -- new info goes at the end of the table
        table.insert(persist.bufferTable,input)
    
        -- remove oldest info if there are as many or more entries than there should be in the buffer
        if #persist.bufferTable >= persist.ticks then
            table.remove(persist.bufferTable,1)
        end
    
        -- return oldest value
        return persist.bufferTable[1]
    end
end
---@endsection
