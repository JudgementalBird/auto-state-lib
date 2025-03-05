require("lib")
print("-- TESTING 'lib.lua' --")

do
	local results = {}
	for i = 1,3 do
		results[i] = delta(i*2,"a")
	end
	results[4] = delta(10,"a")
	assert(results[1]==2)
	assert(results[2]==2)
	assert(results[3]==2)
	assert(results[4]==4)
end
print("Passed delta test")

do
	assert(pulse(false,"b")==false)
	assert(pulse(true,"b")==true)
	assert(pulse(true,"b")==false)
	assert(pulse(false,"b")==false)
	assert(pulse(true,"b")==true)
end
print("Passed pulse test")

do--doesn't test i or i-clamp
	local dist_no_d = 100
	for i = 1,20 do
		dist_no_d = dist_no_d + pid(0,dist_no_d,{p=0.1,i=0,d=0},"c")
	end
	assert(dist_no_d < 15)
	assert(dist_no_d > 10)
	local dist_with_d = 100
	for i = 1,20 do
		dist_with_d = dist_with_d + pid(0,dist_with_d,{p=0.1,i=0,d=0.5},"d")
	end
	assert(dist_with_d < 18)
	assert(dist_with_d > 14)

	assert(dist_no_d < dist_with_d)
end
print("Passed pid test")

do--doesn't test i, d, or iclamp
	--shortest angle is up past 1 (0) and then to 0.2. traditional pid will choose the longer route
	local ang = 0.9
	for i = 1,10 do
		ang = (ang + loopPid(0.2,ang,{p=0.15,i=0,d=0},"e"))%1
	end
	assert(ang > 0.1)
	assert(ang < 0.3)
end
print("Passed loopPid test")

do
	local beeps = 0
	for i = 1, 10 do
		if beep(true,4,"f") then
			beeps = beeps + 1
		end
	end
	assert(beeps==2)
	for i = 1, 50 do
		if beep(false,4,"f") then
			beeps = beeps + 1
		end
	end
	assert(beeps==2)
end
print("Passed beep test")

do
	-- might write this test if I find out the purpose of this function
end
--print("Passed handlercachedbeep test")
print("Skipping test of handlercachedbeep")

do
	assert(capacitor(true,3,3,"g") == false)
	assert(capacitor(true,3,3,"g") == false)
	assert(capacitor(true,3,3,"g") == true)

	assert(capacitor(false,3,3,"g") == true)
	assert(capacitor(false,3,3,"g") == true)
	assert(capacitor(false,3,3,"g") == false)

	assert(capacitor(true,3,3,"g") == false)
	assert(capacitor(true,3,3,"g") == false)
	assert(capacitor(true,3,3,"g") == true)

	--discharge of 0 ticks
	assert(capacitor(true,3,0,"h") == false)
	assert(capacitor(true,3,0,"h") == false)
	assert(capacitor(true,3,0,"h") == true)
	assert(capacitor(false,3,0,"h") == false)
end
print("Passed capacitor test")

do
	assert(advanced_delta(2,1,"i") == 2)
	assert(advanced_delta(6,1,"i") == 4)

	assert(advanced_delta(1,2,"j") == 0.5)
	assert(advanced_delta(2,2,"j") == 1)
	assert(advanced_delta(3,2,"j") == 1)
end
print("Passed advanced_delta test")

do
	assert(vRollAvg(1,3,"k") == 1)
	assert(vRollAvg(2,3,"k") == 1.5)
	assert(vRollAvg(3,3,"k") == 2)
end
print("Passed vRollAvg test")

do
	assert(rollingBuffer(1,2,"l") == 1)
	assert(rollingBuffer(2,2,"l") == 1)
	assert(rollingBuffer(3,2,"l") == 2)
	assert(rollingBuffer(4,2,"l") == 3)
end
print("Passed rollingBuffer test")
