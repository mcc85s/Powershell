#IfWinActive ahk_exe TslGame.exe ; If active window is PUBG
Space::                          ; When Space is pressed
   send, Space & c               ; Send Spacebar and Crouch (c key)
return