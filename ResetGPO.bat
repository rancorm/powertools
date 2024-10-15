:: Remove Group Policy files for Computer and Users
RD /S /Q "%WinDir%\System32\GroupPolicyUsers"
RD /S /Q "%WinDir%\System32\GroupPolicy"

:: Force Group Policy Update to retrieve policies from the domain
GPUPDATE /FORCE
