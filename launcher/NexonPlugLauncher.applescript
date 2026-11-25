-- Starts Nexon Plug inside the CrossOver bottle with software rendering,
-- which avoids the black window that GPU rendering gives under Wine.
-- make-launcher-app.sh fills in bottleName with your bottle name.
property bottleName : "__BOTTLE__"
property wineBin : "/Applications/CrossOver.app/Contents/SharedSupport/CrossOver/bin/wine"
property plugExe : "C:\\Nexon\\NexonPlug\\NexonPlug.exe"
property plugFlags : "--use-gl=swiftshader --use-angle=swiftshader --in-process-gpu"

on run
	do shell script quoted form of wineBin & " --bottle " & quoted form of bottleName & " --no-wait " & quoted form of plugExe & " " & plugFlags & " > /dev/null 2>&1 &"
end run
