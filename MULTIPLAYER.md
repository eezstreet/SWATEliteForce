# HOW TO PLAY IN MULTIPLAYER #

## Using GameRanger (preferred) ##
BOTH PLAYERS will need to do the following:
Download and install GameRanger. It can be found at http://gameranger.com
Next, GameRanger will automatically detect SWAT 4 and SWAT 4: The Stetchkov Syndicate, if all is OK.
You may need to manually detect these, if GameRanger doesn't do it for you.
You will need to rename the LaunchSEF.exe in SEF/Extras to SWAT4X.exe so Gameranger will recognize it. (It's named LaunchSEF.exe so that it isn't automatically detected!)
Then, you will need to modify the Stetchkov Syndicate game in Gameranger so it points to the Swat4X.exe file in SEF/Extras/Swat4X.exe.

THE HOST will need to do the following:
Create a game room, as a SWAT 4: The Stetchkov Syndicate game. (TIP: if this is going to be a publicly joinable game, be sure to mention it's using the SEF mod and specify the version!)
When enough players have joined, press the Start Game button. This will launch the game. From here, go to the Host Game menu and start up a server.
Important Note: Do not launch as a dedicated server while using GameRanger.
The other players will automatically connect to your game while you are loading the map.

THE CLIENT will need to do the following:
Join a public game, or your friend's game. That's all you really need to do.

### TROUBLESHOOTING ###
**NOTE: If you have the mod installed incorrectly, LaunchSEF.exe won't work!**

Make sure you have the Microsoft Visual Studio 2017 Redistributable. It is required to run LaunchSEF.exe and other applications. Download it here:

* **64-bit Windows:** https://go.microsoft.com/fwlink/?LinkId=746572
* **32-bit Windows:** https://go.microsoft.com/fwlink/?LinkId=746571

If GameRanger "aborts" when it launches, you may have some application (antivirus?) interfering with LaunchSEF.exe. If this happens, copy all .exe and .dll files from `ContentExpansion/System` into `SEF/System` and point GameRanger to the Swat4X.exe that is in `SEF/System`. This is kind of an ultra last resort option however!

## Traditional Method (TCP/IP) ##
SWAT: Elite Force v4 was the first version of this mod to allow for multiplayer play. v5 introduced Campaign CO-OP and allowed for publishing of games to Swat4Stats without a CD-key (removing DRM that GOG didn't).

### If you want to join a game: ###

If the game you want is not hosted via LAN, then you will need the SWAT4Stats server browser plugin. It's available at http://swat4stats.com - make sure you get the TSS version.

After it is installed, your server list will show all of the servers, including the ones that are on different mods. Just join the one you want. There are a number of 24/7 SEF servers out there.

If the game you want is hosted via LAN, or you cannot find the server in the list, you will need the host's external IP address (have the host look this up on http://myexternalip.com). You can then join the game from the Join Game menu using the IP address.

### If you want to host a game ###

First, you will need to open some ports on your router: 10480 - 10483, TCP/UDP. If you aren't sure how to do this, the following article explains it well: https://www.howtogeek.com/66214/how-to-forward-ports-on-your-router/

**OPTIONAL:** If you want your game to be publicly visible on the master server list (on swat4stats), you will need to install the Swat4Stats server browser plugin, available at http://swat4stats.com - You'll also want to set your game to be "Internet" and not "LAN" for this to work.

If you aren't playing an Internet/Swat4Stats enabled game, you will need your external IP address for other players to connect. You can look this up on http://myexternalip.com
Lastly, you need to determine what type of game you want to play. Regular CO-OP is handled through the Host Game menu ingame, but Campaign CO-OP is done through the Career menu - select a campaign and hit Career CO-OP. The "Equipment" panel will change to a "Settings" panel where you can configure a password, etc just like in Host Game.

Once you have selected your map settings and have started the server at least once, you can quickly launch a server (without going ingame) by using the Dedicated Server.bat file. You can then join the server from the Join Server menu.

## Admin System ##
Server hosts should NOT use MarkMod, SES Mod, Gez Mod, or Snitch for admin features. Those mods can introduce glitches, bugs, or crashes or break some of the features of SWAT: Elite Force. Instead, SEF includes its own admin mod which aims to combine a lot of the best features of those mods. If you are pining for a particular feature of one of those, let me know and I will work on adding it!

Administrator permissions are doled out through the use of "roles." Everyone by default is assigned to the Guest role; it is not recommended that you give the Guest role very many powers, if any at all. A player can only have one role at a time. Each role should have a unique password associated with it. To log in to a role, click on the "Admin Login" button and enter the password associated with the desired role.

Admin Roles should be assigned through the Host Game menu, when setting up the server settings.

Additionally, SEF also has an MOTD system. The only way (currently) to configure this is through the use of editing INI files. Open SEF/System/Swat4XDedicatedServer.ini. In the section titled `[SwatGame.SwatAdmin]` (at the bottom), add your MOTD lines by the following:

```ini
AutoActions=(Delay=NumSeconds,ExecuteText="Command")
```

Replace `NumSeconds` with the number of seconds (decimal number) before the command will be executed, and `"Command"` with the command text. The command text can be "print " followed by a message to print a string to chat, or "ac " followed by an admin command to execute that command.

As a trivial example, this will print three lines of text every 10 minutes:

```ini
AutoActions=(Delay=600.0,ExecuteText="[c=FFFFFF]Welcome to my server![\\c]")
AutoActions=(Delay=0.5,ExecuteText="[c=FFFFFF]I hope you have fun![\\c]]")
AutoActions=(Delay=0.5,ExecuteText="[c=FFFFFF]Please be nice to others![\\c]")
```

WebAdmin defaults to port 6000. You can access it in a web browser by going to: http://<external ip>:6000/
On the host machine, this can be reached from http://127.0.0.1:6000/

For some tools, you might want to get JSON metadata off of the server. There are two specialized addresses to pull data from. You can see an example of how the data is formatted by going to the listed addresses in your browser.
Note that all enumerations start from zero. They are updated as of v7.

 * Player data can be pulled from `<webadmin address>/json/players`. The Status field can be one of the following from this enumeration:

```cpp
enum COOPStatus
{
    STATUS_NotReady,
    STATUS_Ready,
    STATUS_Healthy,
    STATUS_Injured,
    STATUS_Incapacitated,
};
```

 * A full readout of the server's webadmin logs can be pulled from `<webadmin address>/json/log`. The Message Type field can be one of the following from this enumeration:

```cpp
enum WebAdminMessageType
{
	MessageType_Chat,
	MessageType_PlayerJoin,
	MessageType_AdminJoin,
	MessageType_AdminLeave,
	MessageType_Penalty,
	MessageType_SwitchTeams,
	MessageType_NameChange,
	MessageType_Voting,
	MessageType_Kill,
	MessageType_TeamKill,
	MessageType_Arrest,
	MessageType_Round,
	MessageType_WebAdminError,
};
```

Note that `MessageType_SwitchTeams` is also used for administrator actions, and messages sent by AutoActions are *not* included as part of these logs.
As a security precaution, note that *anyone* can access these URLs and get a message log. So you should probably not be discussing sensitive information on the server.