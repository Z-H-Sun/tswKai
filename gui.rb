CreateWindowEx = API.new('CreateWindowEx', 'LSSLIIIILLLL', 'L', 'user32')
SendMessagePtr = API.new('SendMessageA', 'LLLL', 'L', 'user32')
SetCapture = API.new('SetCapture', 'L', 'L', 'user32')
ReleaseCapture = API.new('ReleaseCapture', 'V', 'L', 'user32')
LoadImage = API.new('LoadImage', 'LLIIII', 'L', 'user32')

LR_SHARED = 0x8000
DEFAULT_GUI_FONT = 17
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
BS_NOTIFY = 0x4000
BS_MULTILINE = 0x2000
BS_TOP = 0x400
BS_AUTOCHECKBOX = 3
BS_TSWCON = WS_CHILD | WS_VISIBLE | WS_TABSTOP | BS_NOTIFY | BS_MULTILINE | BS_TOP | BS_AUTOCHECKBOX
BM_GETCHECK = 0xf0

WINDOW_MOVE_THRESHOLD_PIXEL = 20 # only when you click and drag the mouse over this distance, the status window will then be moved (this design is to avoid misoperation)

$hIco = LoadImage.call($hMod, APP_ICON_ID, IMAGE_ICON, 48, 48, LR_SHARED)
$hWndStatic1 = CreateWindowEx.call_r(WS_EX_TOOLWINDOW|WS_EX_TOPMOST|WS_EX_DLGMODALFRAME, 'STATIC', nil, WS_POPUP|WS_BORDER|SS_SUNKEN|SS_NOTIFY|SS_RIGHT, 20, 20, 146, 56, 0, 0, 0, 0)
$stlStatic1 = GetWindowLong.call_r($hWndStatic1, GWL_EXSTYLE) # this won't be just 0x89 set as above; additional extended styles will be auto applied, e.g. WS_EX_WINDOWEDGE and WS_EX_STATICEDGE
hWndStaticIco = CreateWindowEx.call_r(0, 'STATIC', nil, WS_CHILD|WS_VISIBLE|SS_ICON, 1, 1, 48, 48, $hWndStatic1, 0, 0, 0) # a simpler method without the need of calling LoadImage is to set the title as '#1', but that cannot specify the icon size to be 48x48 (see commit `tswSL@eea9ca7`)
SendMessagePtr.call(hWndStaticIco, STM_SETICON, $hIco, 0)

def Static1_CheckMsg(msg)
  case msg[1]
  when WM_LBUTTONDOWN..WM_RBUTTONUP
    case msgboxTxt(21, MB_YESNOCANCEL|MB_DEFBUTTON2|MB_ICONQUESTION)
    when IDYES
      quit()
    when IDNO
      ShowWindow.call($hWndStatic1, SW_HIDE)
    end
  end
end
