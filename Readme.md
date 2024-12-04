# `xpc_set_event_stream_handler`

Built for use by `launchd` plists using the `LaunchEvents` key.

Agents that use `LaunchEvents` must use `xpc_set_event_stream_handler(3)` to consume the events
the agent subscribes to. If the events are not consumed, `launchd` will think that the agent has
faild and will restart it. And restart it. Again. Every 10 seconds (by default: see `ThrottleInterval`).

There is no native way to call `xpc_set_event_stream_handler(3)` from a shell script, which makes these
agents more difficult to write.

`xpc_set_event_stream_handler` provides a way. Each time it is spawned, it will consume one event
from the given event stream then runs the command you specify. See Arguments below.

Note that `xpc_set_event_stream_handler` does not register a subscription for any events. `launchd`
takes care of that. `xpc_set_event_stream_handler` only consumes the events.

Note also that `xpc_set_event_stream_handler` consumes the event but does not inspect it. If you
need to read the event details and act on them, `xpc_set_event_stream_handler` won't help.

See:
* `man 8 launchd`
* `man 5 launchd.plist`
* `man 3 xpc_set_event_stream_handler`
* See https://github.com/snosrap/xpc_set_event_stream_handler (was designed to handle IOKit events
  and is the inspiration for this repo)

Caution: I have no working knowledge of Swift, Objective-C, or MacOS development in general :)
I "wrote" this with help from AI to scratch an itch.

To compile:
```
swiftc main.swift -o xpc_set_event_stream_handler
```

### Arguments
```
xpc_set_event_stream_handler \
	EVENT_STREAM_NAME \
	[COMMAND] \
	[...COMMAND_ARGS]
```

`EVENT_STREAM_NAME` must be one of:
* `com.apple.notifyd.matching` (works at least in Sequoia 15.1.1)
* `com.apple.iokit.matching` (untested)

`COMMAND` is the absolute path to the binary you want to run.

`COMMAND_ARGS` are arguments to pass to `COMMAND`.

### Example

The following plist defines a `launchd` agent that listens to the
`com.apple.system.config.network_change` event and refreshes a (hypothetical)
[SwiftBar](https://github.com/swiftbar/SwiftBar) menu item.

~/Library/LaunchAgents/local.ProxySwiftBar.plist
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<!--
Refreshes a (hypothetical) Proxy SwiftBar menu item when the network changes.
See:
* https://github.com/swiftbar/SwiftBar
-->
<dict>
    <key>Label</key>
    <string>local.ProxySwiftBar.plist</string>
    <key>ProgramArguments</key>
    <array>
	    <string>/absolute/path/to/compiled/binary/xpc_set_event_stream_handler/xpc_set_event_stream_handler</string>
	    <string>com.apple.notifyd.matching</string>
	    <string>/usr/bin/open</string>
	    <string>-g</string>
	    <string>swiftbar://refreshplugin?name=Proxy.1h.sh</string>
    </array>
    <key>LaunchEvents</key>
    <dict>
        <key>com.apple.notifyd.matching</key>
        <dict>
            <key>com.apple.system.config.network_change</key>
            <dict>
                <key>Notification</key>
                <string>com.apple.system.config.network_change</string>
            </dict>
        </dict>
    </dict>
</dict>
</plist>
```

### Other Notes

There is no documentation providing a complete list of MacOS's native `notifyd`/DistributedNotificationCenter events.
I strongly suspect that they change from MacOS version to MacOS version. Non-Apple developers have compiled some
ad-hoc lists here and there, but finding information about a useful-to-you event is still pretty difficult.

You can watch all `notifyd` events by doing:
1. Disable SIP on your machine. THIS IS NOT A GOOD IDEA :) Be sure to reenable SIP when you are done.
2. `sudo launchctl debug system/com.apple.notifyd -- /usr/sbin/notifyd -d`
   That command will tell `launchd` to use `/usr/sbin/notifyd -d` instead of `/usr/sbin/notifyd` the next time
   it launches the `notifyd` daemon. The `-d` puts `notifyd` in debug mode.
3. `tail -F /var/log/notifyd.log`
4. `ps ax | grep notifyd`
5. `sudo kill NOTIFYD_PID_FROM_STEP_4`
6. Watch the log as you do whatever action you're looking to associate an event with.
   You may or may not find something useful.
7. `ps ax | grep notifyd`
8. `sudo kill NOTIFYD_PID_FROM_STEP_7` (to put `notifyd` back in normal mode).
9. REENABLE SIP ON YOUR MACHINE.

See:
* `man 8 notifyd`
* `man 3 notify`
* [DistributedNotificationCenter](https://developer.apple.com/documentation/foundation/distributednotificationcenter)
