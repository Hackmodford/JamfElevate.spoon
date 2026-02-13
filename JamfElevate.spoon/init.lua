--- === JamfElevate ===
---
--- Automatically prompts to request admin privileges via Jamf Connect during business hours
---
--- Download: [https://github.com/hackmodford/JamfElevate.spoon](https://github.com/hackmodford/JamfElevate.spoon)

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "JamfElevate"
obj.version = "1.0.0"
obj.author = "Brandon Butler"
obj.homepage = "https://github.com/hackmodford/JamfElevate.spoon"
obj.license = "MIT"

-- Configuration
obj.businessHoursStart = 7  -- 7 AM
obj.businessHoursEnd = 17   -- 5 PM
obj.checkInterval = 3600    -- Check every hour (in seconds)
obj.logPath = "/tmp/jamf-elevate.log"
obj.enableLogging = true
obj.timer = nil

--- JamfElevate:log(message)
--- Method
--- Logs a message to the log file and Hammerspoon console
---
--- Parameters:
---  * message - String to log
function obj:log(message)
    if self.enableLogging then
        local timestamp = os.date("%Y-%m-%d %H:%M:%S")
        local logMessage = string.format("[%s] %s", timestamp, message)
        
        -- Log to Hammerspoon console
        print(logMessage)
        
        -- Log to file
        local file = io.open(self.logPath, "a")
        if file then
            file:write(logMessage .. "\n")
            file:close()
        end
    end
end

--- JamfElevate:checkAdminStatus()
--- Method
--- Checks if the current user has admin privileges
---
--- Returns:
---  * true if user is admin, false otherwise
function obj:checkAdminStatus()
    local output, status = hs.execute("groups | grep -q admin && echo 'true' || echo 'false'")
    return output and output:match("true") ~= nil
end

--- JamfElevate:isBusinessHours()
--- Method
--- Checks if current time is within business hours (weekday 7am-5pm)
---
--- Returns:
---  * true if within business hours, false otherwise
function obj:isBusinessHours()
    local now = os.date("*t")
    local hour = now.hour
    local dayOfWeek = now.wday  -- 1=Sunday, 2=Monday, ..., 7=Saturday
    
    -- Convert to 1=Monday, 7=Sunday
    local weekday = (dayOfWeek + 5) % 7 + 1
    
    -- Check if it's a weekday (1-5) and within business hours
    local isWeekday = weekday >= 1 and weekday <= 5
    local isDuringHours = hour >= self.businessHoursStart and hour <= self.businessHoursEnd
    
    self:log(string.format("Time check - Hour: %d, Weekday: %d, IsWeekday: %s, IsDuringHours: %s",
        hour, weekday, tostring(isWeekday), tostring(isDuringHours)))
    
    return isWeekday and isDuringHours
end

--- JamfElevate:showConfirmationDialog()
--- Method
--- Shows a confirmation dialog asking user to elevate privileges
---
--- Returns:
---  * true if user confirmed, false if cancelled
function obj:showConfirmationDialog()
    local button, _ = hs.dialog.blockAlert(
        "Jamf Connect - Admin Request",
        "It's time to request admin privileges",
        "Elevate Me",
        "Cancel"
    )
    
    return button == "Elevate Me"
end

--- JamfElevate:clickMenubarItem()
--- Method
--- Clicks the "Request Admin Privileges" menu item in Jamf Connect
---
--- Returns:
---  * true if successful, false otherwise
function obj:clickMenubarItem()
    -- Use AppleScript to interact with the menu bar extra
    local script = [[
        tell application "System Events"
            try
                -- Get the Jamf Connect menubar item
                set menubarItem to menu bar item 1 of menu bar 1 of application process "Jamf Connect"
                
                -- Click to open the menu
                click menubarItem
                
                delay 0.3
                
                -- Try to click by position first (position 10 from original script)
                try
                    click menu item 10 of menu 1 of menubarItem
                    return "success-position"
                on error
                    -- Fallback: search by name
                    set menuItems to every menu item of menu 1 of menubarItem
                    repeat with currentItem in menuItems
                        try
                            if name of currentItem is "Request Admin Privileges" then
                                click currentItem
                                return "success-name"
                            end if
                        end try
                    end repeat
                    return "not-found"
                end try
            on error errMsg
                return "error: " & errMsg
            end try
        end tell
    ]]
    
    local ok, result, rawTable = hs.osascript.applescript(script)
    
    if ok then
        if result:match("success") then
            self:log("Successfully clicked 'Request Admin Privileges' (" .. result .. ")")
            return true
        elseif result == "not-found" then
            self:log("ERROR: Could not find 'Request Admin Privileges' menu item")
            return false
        else
            self:log("ERROR: " .. result)
            return false
        end
    else
        self:log("ERROR: AppleScript execution failed - " .. tostring(result))
        return false
    end
end

--- JamfElevate:checkAndElevate()
--- Method
--- Main function that checks admin status and prompts for elevation if needed
function obj:checkAndElevate()
    self:log("Running elevation check...")
    
    -- Check if we're in business hours
    if not self:isBusinessHours() then
        self:log("Outside business hours, skipping check")
        return
    end
    
    self:log("Within business hours, checking admin status")
    
    -- Check if user already has admin privileges
    if self:checkAdminStatus() then
        self:log("User already has admin privileges")
        return
    end
    
    self:log("User does not have admin privileges - showing elevation dialog")
    
    -- Show confirmation dialog
    if self:showConfirmationDialog() then
        self:log("User confirmed elevation request")
        self:clickMenubarItem()
    else
        self:log("User cancelled elevation request")
    end
end

--- JamfElevate:start()
--- Method
--- Starts the periodic check timer
---
--- Returns:
---  * The JamfElevate object
function obj:start()
    self:log("Starting JamfElevate with check interval of " .. self.checkInterval .. " seconds")
    
    -- Run initial check
    self:checkAndElevate()
    
    -- Set up periodic timer
    if self.timer then
        self.timer:stop()
    end
    
    self.timer = hs.timer.doEvery(self.checkInterval, function()
        self:checkAndElevate()
    end)
    
    return self
end

--- JamfElevate:stop()
--- Method
--- Stops the periodic check timer
---
--- Returns:
---  * The JamfElevate object
function obj:stop()
    self:log("Stopping JamfElevate")
    
    if self.timer then
        self.timer:stop()
        self.timer = nil
    end
    
    return self
end

--- JamfElevate:manualCheck()
--- Method
--- Manually trigger an elevation check (bypasses business hours check)
function obj:manualCheck()
    self:log("Manual elevation check triggered")
    
    -- Check admin status
    if self:checkAdminStatus() then
        hs.alert.show("You already have admin privileges")
        return
    end
    
    -- Show confirmation dialog
    if self:showConfirmationDialog() then
        self:clickMenubarItem()
    end
end

--- JamfElevate:bindHotkeys(mapping)
--- Method
--- Binds hotkeys for the Spoon
---
--- Parameters:
---  * mapping - A table containing hotkey modifier/key details for the following items:
---   * manualCheck - Manually trigger an elevation check
---
--- Example:
--- ```
--- spoon.JamfElevate:bindHotkeys({
---   manualCheck = {{"cmd", "alt", "ctrl"}, "E"}
--- })
--- ```
function obj:bindHotkeys(mapping)
    local def = {
        manualCheck = hs.fnutils.partial(self.manualCheck, self)
    }
    hs.spoons.bindHotkeysToSpec(def, mapping)
end

return obj
