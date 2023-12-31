#!/usr/bin/env ruby
# encoding: ASCII-8Bit
# Author: Z.Sun

ClientToScreen = API.new('ClientToScreen', 'LP', 'L', 'user32')
CreateWindowEx = API.new('CreateWindowEx', 'LSSLIIIILLLL', 'L', 'user32')
SendMessagePtr = API.new('SendMessageA', 'LLLL', 'L', 'user32')
SetCapture = API.new('SetCapture', 'L', 'L', 'user32')
ReleaseCapture = API.new('ReleaseCapture', 'V', 'L', 'user32')
LoadImage = API.new('LoadImage', 'LLIIII', 'L', 'user32')
GetDC = API.new('GetDC', 'L', 'L', 'user32')
ReleaseDC = API.new('ReleaseDC', 'LL', 'L', 'user32')
CreateFontIndirect = API.new('CreateFontIndirect', 'S', 'L','gdi32')

LR_SHARED = 0x8000
IMAGE_ICON = 1
ICON_BIG = 1
MK_LBUTTON = 1
MK_RBUTTON = 2
GWL_HWNDOWNER = -8
GWL_STYLE = -16
GWL_EXSTYLE = -20
SWP_NOSIZE = 1
SWP_NOMOVE = 2
SWP_NOZORDER = 4
SWP_FRAMECHANGED = 0x20
SWP_NOOWNERZORDER = 0x200
SWP_UPDATELONGONLY = SWP_NOSIZE | SWP_NOMOVE | SWP_NOZORDER | SWP_NOOWNERZORDER | SWP_FRAMECHANGED
WS_POPUP = 0x80000000
WS_CHILD = 0x40000000
WS_VISIBLE = 0x10000000
WS_CAPTION = 0xC00000
WS_BORDER = 0x800000
WS_SYSMENU = 0x80000
WS_SIZEBOX = 0x40000
WS_MINIMIZEBOX = 0x20000
WS_MAXIMIZEBOX = 0x10000
WS_ALLRESIZE = WS_SIZEBOX | WS_MINIMIZEBOX | WS_MAXIMIZEBOX
WS_TABSTOP = 0x10000
WS_EX_APPWINDOW = 0x40000
WS_EX_TOOLWINDOW = 0x80
WS_EX_TOPMOST = 8
WS_EX_DLGMODALFRAME = 1
SS_SUNKEN = 0x1000
SS_NOTIFY = 0x100
SS_ICON = 3
SS_RIGHT = 2
STM_SETICON = 0x170
LOGFONT_STRUCT = 'L5C8a32'
DIALOG_CLASS_NAME = '#32770'
STATIC_CLASS_NAME = 'Static'
BUTTON_CLASS_NAME = 'Button'
APP_MUTEX_TITLE = APP_NAME+'_mutex'

WINDOW_MOVE_THRESHOLD_PIXEL = 20 # only when you click and drag the mouse over this distance, the status window will then be moved (this design is to avoid misoperation)
WINDOW_SCREEN_X, WINDOW_SCREEN_Y = 20, 20 # where the status tip window show on the screen
$CONshowStatusTip = true # whether to show status tip window when TSW is not running (true: always show; false: do not show immediately you quit TSW but show upon pressing hotkey; nil: never show)
$CONaskOnTSWquit = true # if on, will ask whether to continue or not once TSW has quitted; if off, always continue

$hIco = LoadImage.call($hMod, APP_ICON_ID, IMAGE_ICON, 48, 48, LR_SHARED)
$hWndStatic1 = CreateWindowEx.call_r(WS_EX_TOOLWINDOW|WS_EX_TOPMOST|WS_EX_DLGMODALFRAME, STATIC_CLASS_NAME, nil, WS_POPUP|WS_BORDER|SS_SUNKEN|SS_NOTIFY|SS_RIGHT, WINDOW_SCREEN_X, WINDOW_SCREEN_Y, 146, 56, 0, 0, 0, 0)
$stlStatic1 = GetWindowLong.call_r($hWndStatic1, GWL_EXSTYLE) # this won't be just 0x89 set as above; additional extended styles will be auto applied, e.g. WS_EX_WINDOWEDGE and WS_EX_STATICEDGE
hWndStaticIco = CreateWindowEx.call_r(0, STATIC_CLASS_NAME, nil, WS_CHILD|WS_VISIBLE|SS_ICON, 1, 1, 48, 48, $hWndStatic1, 0, 0, 0) # a simpler method without the need of calling LoadImage is to set the title as '#1', but that cannot specify the icon size to be 48x48 (see commit `tswSL@eea9ca7`)
SendMessagePtr.call(hWndStaticIco, STM_SETICON, $hIco, 0)

unless (hWnd=FindWindow.call(DIALOG_CLASS_NAME, APP_MUTEX_TITLE)).zero? # found another instance; quit
  GetWindowThreadProcessId.call(hWnd, $bufDWORD)
  initSettings(); msgbox = $isCHN ? :msgboxTxtW : :msgboxTxtA
  send(msgbox, 29, MB_ICONERROR, $bufDWORD.unpack('L')[0])
  exit
end
$hWndDialogParent = CreateWindowEx.call_r(0, DIALOG_CLASS_NAME, APP_MUTEX_TITLE, 0, 0, 0, 0, 0, 0, 0, 0, 0) # this will be used as a 'mutex' preventing creation of multiple instances; this window has another use: see tswMod.rb

$lastMousePos = $bufDWORD * 2 # the mouse position when the msg is generated (not initialized yet; within the msg loop, will be x,y = $lastMousePos.unpack('ll'))
$movingStatic1 = false # indicate if currently using mouse to move the status window; if so, it will be [x0, y0] with respect to top left corner of the client

def Static1_3D(sunken) # when mouse/key down, sunken; up, raised
  prev_sunken = ($stlStatic1 & WS_EX_DLGMODALFRAME).zero?
  return false if sunken == prev_sunken # no need to do the following if the state doesn't change
  if sunken then $stlStatic1 &= ~ WS_EX_DLGMODALFRAME else $stlStatic1 |= WS_EX_DLGMODALFRAME end
  SetWindowLong.call_r($hWndStatic1, GWL_EXSTYLE, sunken ? ($stlStatic1 & ~ WS_EX_DLGMODALFRAME) : $stlStatic1)
  SetWindowPos.call_r($hWndStatic1, 0, 0, 0, 0, 0, SWP_UPDATELONGONLY)
  return true
end

def Static1_CheckMsg(msg)
  case msg[1]
  when WM_LBUTTONDOWN, WM_RBUTTONDOWN, WM_KEYDOWN
    if msg[1] == WM_KEYDOWN # if keystroke, must be ESC or SPACE or RETN
      Static1_3D(true) if msg[2] == VK_ESCAPE or msg[2] == VK_SPACE or msg[2] == VK_RETURN
    else
      $movingStatic1 = false
      $lastMousePos = msg[5] # msg[3], i.e. lparam, relative coordinate w.r.t. client area left top, is not accurate, can differ by 1 pixel in both x and y direction when mouse is / isn't down (why?), so I can't use this. On the contrary, msg[5], absolute coordinate, is much more reliable
      Static1_3D(true)
    end
  when WM_MOUSEMOVE
    curMousePos = msg[5]
    return if curMousePos == $lastMousePos # continue only if mouse moves to a different position
    return if msg[2] != MK_LBUTTON and msg[2] != MK_RBUTTON # continue only if dragging with mouse down
    x, y = curMousePos.unpack('l2')
    SetCapture.call($hWndStatic1) # send WM_MOUSEMOVE msg even when the mouse moves outside of the client area
    if $movingStatic1
      SetWindowPos.call_r($hWndStatic1, 0, x-$movingStatic1[0], y-$movingStatic1[1], 0, 0, SWP_NOSIZE)
    elsif (x_o, y_o = $lastMousePos.unpack('l2'); (x-x_o).abs+(y-y_o).abs > WINDOW_MOVE_THRESHOLD_PIXEL) # make sure the moving range is large enough
      Static1_3D(false)
      $movingStatic1 = [msg[3]].pack('L').unpack('s2') # lparam is the mouse position with respect to the top left corner of the client area; loword=x; hiword=y
    else return # do not assign $lastMousePos if the moving range is not large enough
    end
    $lastMousePos = curMousePos
  when WM_LBUTTONUP, WM_RBUTTONUP, WM_KEYUP
    return if msg[1] == WM_KEYUP and msg[2] != VK_ESCAPE and msg[2] != VK_SPACE and msg[2] != VK_RETURN # if keystroke, continue only with ESC or SPACE or RETN
    if $movingStatic1
      ReleaseCapture.call() # counteract `SetCapture` above
      $movingStatic1 = false
    else
      return unless Static1_3D(false) # if you press ESC or RETN, the $hWndStatic1 window will be focused, and another WM_KEYUP message will be generated, and you will get in a loop, so need to make sure WM_*DOWN has happened before WM_*UP
      case msgboxTxt(21, MB_YESNOCANCEL|MB_DEFBUTTON2|MB_ICONQUESTION, *$regKeyName.compact)
      when IDYES
        quit()
      when IDNO
        ShowWindow.call($hWndStatic1, SW_HIDE)
      end
    end
  end
end
