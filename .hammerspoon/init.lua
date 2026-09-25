local previousApp = nil

hs.hotkey.bind({ "cmd" }, "escape", function()
	local ghostty = hs.application.find("com.mitchellh.ghostty")
	local front = hs.application.frontmostApplication()

	if ghostty and front:bundleID() == "com.mitchellh.ghostty" then
		-- Ghostty is focused -> go back to previous app
		if previousApp then
			previousApp:activate()
		end
	else
		-- Remember where we were, then bring Ghostty forward
		previousApp = front
		if ghostty then
			ghostty:activate()
		else
			hs.application.launchOrFocus("Ghostty")
		end
	end
end)

-- macOS caches screen:frame() and forgets the Dock after displays change,
-- so measure the Dock ourselves and subtract it from the full frame.
local function dockFrame()
	local autohide = hs.execute("defaults read com.apple.dock autohide 2>/dev/null")
	if autohide:match("1") then return nil end
	local dock = hs.application.find("com.apple.dock")
	if not dock then return nil end
	local ax = hs.axuielement.applicationElement(dock)
	for _, child in ipairs(ax and ax:attributeValue("AXChildren") or {}) do
		if child:attributeValue("AXRole") == "AXList" then
			return child:attributeValue("AXFrame")
		end
	end
	return nil
end

local function usableFrame(screen)
	local ok, result = pcall(function()
		local full = screen:fullFrame()
		local visible = screen:frame()
		-- keep the menu bar offset reported by macOS
		local f = { x = full.x, y = visible.y, w = full.w, h = full.h - (visible.y - full.y) }
		local d = dockFrame()
		if not d then return hs.geometry.rect(f) end
		local tol = 2
		local fits = d.x >= full.x - tol and d.x + d.w <= full.x + full.w + tol
			and d.y >= full.y - tol and d.y + d.h <= full.y + full.h + tol
		if not fits then return hs.geometry.rect(f) end
		if d.w >= d.h then -- bottom
			f.h = d.y - f.y
		elseif d.x <= full.x + tol then -- left
			f.x = d.x + d.w
			f.w = full.x + full.w - f.x
		else -- right
			f.w = d.x - f.x
		end
		return hs.geometry.rect(f)
	end)
	if ok and result then return result end
	return screen:frame()
end

-- Window management: move/resize focused window
local function moveWindow(fn)
	local win = hs.window.focusedWindow()
	if not win then return end
	fn(usableFrame(win:screen()), win)
end

local hyper = { "ctrl", "alt", "cmd" }

-- Left half
hs.hotkey.bind(hyper, "left", function()
	moveWindow(function(f, win)
		win:setFrame({ x = f.x, y = f.y, w = f.w / 2, h = f.h })
	end)
end)

-- Right half
hs.hotkey.bind(hyper, "right", function()
	moveWindow(function(f, win)
		win:setFrame({ x = f.x + f.w / 2, y = f.y, w = f.w / 2, h = f.h })
	end)
end)

-- Fullscreen (fill screen)
hs.hotkey.bind(hyper, "up", function()
	moveWindow(function(f, win)
		win:setFrame(f)
	end)
end)

-- Move window to next display and maximize it there
hs.hotkey.bind(hyper, "down", function()
	local win = hs.window.focusedWindow()
	if not win then return end

	local nextScreen = win:screen():next()
	win:moveToScreen(nextScreen)
	win:setFrame(usableFrame(nextScreen))
end)

-- When displays are added/removed, re-fit windows that fill their screen
local refitTimer = nil
screenWatcher = hs.screen.watcher.new(function()
	if refitTimer then refitTimer:stop() end
	refitTimer = hs.timer.doAfter(1.5, function()
		for _, win in ipairs(hs.window.visibleWindows()) do
			local screen = win:screen()
			if win:isStandard() and screen then
				local wf, full = win:frame(), screen:fullFrame()
				if wf.w >= full.w * 0.95 and wf.h >= full.h * 0.85 then
					win:setFrame(usableFrame(screen))
				end
			end
		end
	end)
end)
screenWatcher:start()