#IfWinActive ahk_exe TslGame.exe ; If active window is PUBG
LShift::                          ; When Space is pressed
   send, +c               ; Send Spacebar and Crouch (c key)
return
