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

-- Window management: move/resize focused window
local function moveWindow(fn)
	local win = hs.window.focusedWindow()
	if not win then return end
	local f = win:screen():frame() -- usable frame (excludes menu bar / Dock)
	fn(f, win)
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