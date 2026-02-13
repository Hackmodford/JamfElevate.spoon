# JamfElevate Spoon

A Hammerspoon Spoon that automatically prompts users to request admin privileges via Jamf Connect during business hours.

## Features

- ✅ Automatic checks during business hours (weekdays 7am-5pm by default)
- ✅ Verifies if user already has admin privileges before prompting
- ✅ User-friendly confirmation dialog
- ✅ Configurable check interval
- ✅ Manual elevation check via hotkey
- ✅ Comprehensive logging
- ✅ Easy to customize

## Installation

### Manual Installation

1. Copy the `JamfElevate.spoon` directory to `~/.hammerspoon/Spoons/`
   ```bash
   cp -r JamfElevate.spoon ~/.hammerspoon/Spoons/
   ```

2. Add to your `~/.hammerspoon/init.lua`:
   ```lua
   hs.loadSpoon("JamfElevate")
   spoon.JamfElevate:start()
   ```

3. Reload Hammerspoon configuration

### Using SpoonInstall (Alternative)

Add to your `~/.hammerspoon/init.lua`:
```lua
hs.loadSpoon("SpoonInstall")
spoon.SpoonInstall:andUse("JamfElevate", {
    start = true
})
```

## Configuration

You can customize the behavior in your `init.lua`:

```lua
hs.loadSpoon("JamfElevate")

-- Configure business hours (24-hour format)
spoon.JamfElevate.businessHoursStart = 8   -- 8 AM
spoon.JamfElevate.businessHoursEnd = 18    -- 6 PM

-- Configure check interval (in seconds)
spoon.JamfElevate.checkInterval = 7200     -- Check every 2 hours

-- Configure logging
spoon.JamfElevate.enableLogging = true
spoon.JamfElevate.logPath = "/tmp/jamf-elevate.log"

-- Bind a hotkey for manual checks
spoon.JamfElevate:bindHotkeys({
    manualCheck = {{"cmd", "alt", "ctrl"}, "E"}
})

-- Start the spoon
spoon.JamfElevate:start()
```

## Usage

### Automatic Mode
Once started, the Spoon will:
1. Check every hour (or your configured interval) if it's business hours
2. If it's business hours and you don't have admin privileges, show a prompt
3. If you click "Elevate Me", it will click the Jamf Connect menu item

### Manual Mode
Press your configured hotkey (default: Cmd+Alt+Ctrl+E) to manually trigger an elevation check, bypassing business hours.

## Methods

- `JamfElevate:start()` - Start automatic checking
- `JamfElevate:stop()` - Stop automatic checking
- `JamfElevate:manualCheck()` - Manually trigger an elevation check
- `JamfElevate:checkAdminStatus()` - Check if user has admin privileges
- `JamfElevate:isBusinessHours()` - Check if current time is within business hours

## Requirements

- macOS
- [Hammerspoon](https://www.hammerspoon.org/) 0.9.93 or later
- Jamf Connect installed and configured

## Troubleshooting

### Logs
Check the log file at `/tmp/jamf-elevate.log` for detailed information about each check.

### Permissions
Hammerspoon needs Accessibility permissions to interact with the Jamf Connect menu bar. Go to:
System Settings > Privacy & Security > Accessibility > Enable Hammerspoon

### Menu Item Not Found
If the Spoon can't find the "Request Admin Privileges" menu item, ensure:
1. Jamf Connect is running
2. The menu item name is exactly "Request Admin Privileges"
3. Hammerspoon has Accessibility permissions

## License

MIT License - See LICENSE file for details

## Original Scripts

This Spoon is based on the original bash/AppleScript implementation found in this directory:
- `jamf-elevate-wrapper.sh` - Original wrapper script
- `jamf-elevate.scpt` - Original AppleScript
- `jamf-elevate.txt` - Original AppleScript source
