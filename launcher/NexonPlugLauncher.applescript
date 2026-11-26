-- Starts Nexon Plug inside the CrossOver bottle with software rendering,
-- which avoids the black window that GPU rendering gives under Wine.
-- make-launcher-app.sh fills in bottleName with your bottle name.
property bottleName : "__BOTTLE__"
property wineBin : "/Applications/CrossOver.app/Contents/SharedSupport/CrossOver/bin/wine"
property plugExe : "C:\\Nexon\\NexonPlug\\NexonPlug.exe"
property plugFlags : "--use-gl=swiftshader --use-angle=swiftshader --in-process-gpu"

property svcKey : "HKLM\\System\\CurrentControlSet\\Services\\Nexon Launcher"

on run
	set w to quoted form of wineBin & " --bottle " & quoted form of bottleName
	-- Wine에서 켜지지 않는 Nexon Launcher 서비스를 꺼 둬요. 그래야 "게임 실행에 실패했습니다" 없이 게임이 바로 켜져요.
	do shell script w & " reg query " & quoted form of svcKey & " >/dev/null 2>&1 && " & w & " reg add " & quoted form of svcKey & " /v Start /t REG_DWORD /d 4 /f >/dev/null 2>&1; true"
	do shell script w & " --no-wait " & quoted form of plugExe & " " & plugFlags & " > /dev/null 2>&1 &"
end run
