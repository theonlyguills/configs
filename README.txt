
Execute the following in a NON admin power shell :

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression

scoop bucket add nerd-fonts
scoop install firacode

THEN

save bootstrap.ps1 in user profile folder (C:\Users\fill_in_your_profile)

Execute the following in a ADMIN power shell while in your user profile folder:
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

bootstrap.ps1

