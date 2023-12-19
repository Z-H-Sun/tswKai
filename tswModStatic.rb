#!/usr/bin/env ruby
# encoding: ASCII-8Bit
# Author: Z.Sun
# Note: If the TSW executable is in an admin-privileged folder (e.g., Program Files (x86)) on an OS later than Vista, in order for this app to successfully static-patch that file, this app's startup executable must contain an UAC manifest (e.g., 'asInvoker'); otherwise, the system will create a copy of it under the 'VirtualStore' folder while keeping the original file unchanged. Therefore, please use either the 'tswKai3.exe' executable I provide or a high-version Ruby Interpreter (e.g., Ruby 2.7; as far as I know, Ruby 2.2 exe does not have a manifest)

BASE_ADDRESS_STATIC = -0xC00
SEE_MASK_NOCLOSEPROCESS = 0x40
QS_POSTMESSAGE = 8
SHELLEXECUTEINFO_STRUCT = "L2#{HANDLE_STRUCT}p4#{HANDLE_STRUCT}2p6"
SHELLEXECUTEINFO_STRUCT_LEN = 8 + POINTER_SIZE * 13
GetDesktopWindow = API.new('GetDesktopWindow', 'V', 'L', 'user32')
DestroyWindow = API.new('DestroyWindow', 'L', 'I', 'user32')
RegisterWindowMessage = API.new('RegisterWindowMessage', 'S', 'I', 'user32')
TerminateProcess = API.new('TerminateProcess', 'LI', 'I', 'kernel32')
GetModuleFileName = API.new('GetModuleFileName', 'LPI', 'I', 'kernel32')
ShellExecuteEx = API.new('ShellExecuteEx', 'P', 'I', 'shell32')

REV_VER_WATERMARK = 'rev'
MOD_ADMIN_PATCH_SIGNATURE = 'AdminStaticPatchOnly'
MOD_ADMIN_PATCH_PARENT_HWND = $*[2].to_i
MOD_ADMIN_PATCH_ONLY = ($*[1] == MOD_ADMIN_PATCH_SIGNATURE) and !IsWindow.call(MOD_ADMIN_PATCH_PARENT_HWND).zero?
MOD_TARGET_TSW_EXE = $*[0].dup
MOD_DIALOG_HEIGHT_NEW = 204
if String.instance_methods.include?(:encoding) # this is necessary for Ruby > 1.9
  MOD_TARGET_TSW_EXE.encode!('filesystem')
  APP_FNAME.encode!('filesystem')
end

module Mod
  module Static
    @CONmodStatus = Array.new(5) # in replacement of $CONmodStatus
    module_function
    def checkChkStates(staticIO)
      for i in 0...MOD_PATCH_OPTION_COUNT
        d = MOD_PATCH_BYTES_2[i]
        s = 0
        d[1].each_with_index do |l, j|
          staticIO.seek(d[2][j]+BASE_ADDRESS_STATIC)
          t = d[3+j].index(staticIO.read(l))
          s = t if j.zero? # first one
          if !t or s != t then s = 2; break end
        end
        @CONmodStatus[i] = s
        SendMessagePtr.call($hWndChkBoxes[i], BM_SETCHECK, s, 0)
      end
    end
    def patch(i, staticIO)
      s = @CONmodStatus[i]
      return if s == 2 and msgboxTxt(41, MB_ICONEXCLAMATION|MB_OKCANCEL) == IDCANCEL
      s = s.zero? ? 1 : 0 # toggle Boolean
      d = MOD_PATCH_BYTES_2[i]
      l = d[1].size
      if i == 2 and s == 1 and !$isRev # 45F merchant will be tricky; if the EXE is not pre-patched to add an extra text entry, the corresponding patches won't work
        return if msgboxTxt(43, MB_ICONEXCLAMATION|MB_OKCANCEL) == IDCANCEL
        l = d[0]; s = 2 # only patch to change the HP amount; don't try patching the dialog content
      end
      (0...l).each {|j| staticIO.seek(d[2][j]+BASE_ADDRESS_STATIC); staticIO.write(d[3+j][s.zero? ? 0 : 1])}
      staticIO.flush() # this seems necessary especially when running as admin or another user; otherwise the changed bytes won't be reflected on the hard disk even after `IO#close`
      @CONmodStatus[i] = s
      SendMessagePtr.call($hWndChkBoxes[i], BM_SETCHECK, s, 0)
      SetFocus.call($hWndChkBoxes[(i+1) % MOD_PATCH_OPTION_COUNT]) # focus next checkbox
    end
  end
end
def earlyQuit(staticIO=nil, quit=true)
  DeleteObject.call($hGUIFont2)
  staticIO.close if staticIO
  exit() if quit
end

initSettings()
msgbox = $isCHN ? :msgboxTxtW : :msgboxTxtA
shellExecuteInfo = Array.new(15)
shellExecuteInfo[0] = SHELLEXECUTEINFO_STRUCT_LEN # .cbSize
SetWindowLong.call_r($hWndDialog, GWL_HWNDOWNER, 0) # to allow showing the dialog window in the task bar
delegateAdminSubproc = false
begin
  staticIO = open(MOD_TARGET_TSW_EXE, 'r+b')
rescue Errno::EACCES
  if MOD_ADMIN_PATCH_ONLY # even with admin privilege the file can't be accessed...
    send(msgbox, 44, MB_ICONERROR)
    earlyQuit()
  end
  earlyQuit() if send(msgbox, 45, MB_ICONEXCLAMATION|MB_OKCANCEL) == IDCANCEL
  DestroyWindow.call_r($hWndDialogParent) # temporarily disable mutex; allow the admin-privileged subprocess to run

  # create a admin-privileged subprocess to complete the static patches
  shellExecuteInfo[1] = SEE_MASK_NOCLOSEPROCESS # .fMask
  shellExecuteInfo[2] = 0 # .hwnd
  shellExecuteInfo[3] = 'runas' # .lpVerb
  shellExecuteInfo[4] = APP_FNAME # .lpFile
  shellExecuteInfo[5] = " \"#{MOD_TARGET_TSW_EXE}\" #{MOD_ADMIN_PATCH_SIGNATURE} #{$hWndDialog}" # .lpParameters
  shellExecuteInfo[7] = SW_RESTORE # .nShow
  shellExecuteInfo[8] = 0 # .hInstApp
  unless $Exerb
    len = GetModuleFileName.call_r($hMod, $buf, MAX_PATH)
    RUBY_INTERPRETER_FNAME = $buf[0, len]
    shellExecuteInfo[5][0, 0] = shellExecuteInfo[4] # add script filename at the beginning of argv
    shellExecuteInfo[4] = RUBY_INTERPRETER_FNAME # must specify the executable filename
  end
  shellExecuteInfoBuf = shellExecuteInfo.pack(SHELLEXECUTEINFO_STRUCT)
  ShellExecuteEx.call_r(shellExecuteInfoBuf)
  $bufHWait[0, POINTER_SIZE] = shellExecuteInfoBuf[-POINTER_SIZE, POINTER_SIZE]
  MOD_ADMIN_PATCH_MSG = RegisterWindowMessage.call_r(MOD_ADMIN_PATCH_SIGNATURE)
  loop do
    earlyQuit() if MsgWaitForMultipleObjects.call_r(1, $bufHWait, 0, -1, QS_POSTMESSAGE).zero? # admin patch subprocess exited without sending the "success" message, then exit current process too
    while !PeekMessage.call($buf, 0, 0, 0, 1).zero?
      msg = $buf.unpack(MSG_INFO_STRUCT)
      next unless msg[0] == $hWndDialog and msg[1] == MOD_ADMIN_PATCH_MSG # admin patch subprocess sent the "success" message right before exiting
      $isCHN = !msg[2].zero? # wParam is $isCHN read from the admin patch subprocess
      delegateAdminSubproc = true
      break
    end
    break if delegateAdminSubproc
  end
  initLang()
  hPrc = $bufHWait.unpack(HANDLE_STRUCT)[0]
  TerminateProcess.call(hPrc, 0) # now that we have received the "success" message from the subprocess, we can safely kill it
  CloseHandle.call(hPrc)
  $hWndDialogParent = CreateWindowEx.call_r(0, DIALOG_CLASS_NAME, APP_MUTEX_TITLE, 0, 0, 0, 0, 0, 0, 0, 0, 0) # re-create the parent window
  SetWindowLong.call($hWndDialog, GWL_HWNDOWNER, $hWndDialogParent)
rescue
  send(msgbox, 44, MB_ICONERROR)
  earlyQuit()
end

# if `delegateAdminSubproc`, then everything patch-related has been taken care of by the admin subprocess
unless delegateAdminSubproc # or else, can manage all patch-related actions within the current process
  earlyQuit(staticIO) if Str.isCHN(staticIO).nil?
  initLang()
  earlyQuit(staticIO) if msgboxTxt(46, MB_ICONASTERISK|MB_YESNO) == IDNO
  (MOD_PATCH_OPTION_COUNT...MOD_TOTAL_OPTION_COUNT).each {|i| ShowWindow.call($hWndChkBoxes[i], SW_HIDE)} # change dialog layout because the last 3 options are not meaningful in static mode
  Mod::Static.checkChkStates(staticIO)
  Mod::MOD_PATCH_BYTES_1.each {|i| staticIO.seek(i[0]+BASE_ADDRESS_STATIC); staticIO.write(i[3])} # must-do patches
  staticIO.flush() # this seems necessary especially when running as admin or another user; otherwise the changed bytes won't be reflected on the hard disk even after `IO#close`

  GetClientRect.call_r(GetDesktopWindow.call(), $buf).zero? # center dialog on screen
  w, h = $buf[8, 8].unpack('ll')
  setTitle($hWndDialog, 31)
  SetWindowPos.call_r($hWndDialog, 0, w-MOD_DIALOG_WIDTH >> 1, h-MOD_DIALOG_HEIGHT_NEW >> 1, MOD_DIALOG_WIDTH, MOD_DIALOG_HEIGHT_NEW, 0)
  ShowWindow.call($hWndDialog, SW_SHOW)
  SetForegroundWindow.call($hWndDialog)

  while GetMessage.call($buf, 0, 0, 0) > 0 # dialog message loop
    msg = $buf.unpack(MSG_INFO_STRUCT)
    hWnd = msg[0]
    msgType = msg[1]
    wParam = msg[2]
    break if msgType == WM_KEYDOWN and (wParam == VK_ESCAPE or wParam == VK_RETURN) # if pressed ESC or RETN
    break if msgType == WM_COMMAND and wParam == IDCANCEL # if closed the dialog through [x] button or sysmenu or Alt+F4
    if (msgType == WM_LBUTTONUP or (msgType == WM_KEYUP and msg[2] == VK_SPACE)) and (i=$hWndChkBoxes.index(hWnd)) then Mod::Static.patch(i, staticIO) end
    next unless IsDialogMessage.call($hWndDialog, $buf).zero?
    TranslateMessage.call($buf)
    DispatchMessage.call($buf)
  end

  if MOD_ADMIN_PATCH_ONLY # once the patches are done, the admin-privileged subprocess should exit and hand over to the normal-level parent process; otherwise, there will be potential problems with communications across privileged and non-privileged processes
    MOD_ADMIN_PATCH_MSG = RegisterWindowMessage.call_r(MOD_ADMIN_PATCH_SIGNATURE)
    earlyQuit(staticIO, false)
    DestroyWindow.call_r($hWndDialogParent)
    PostMessage.call_r(MOD_ADMIN_PATCH_PARENT_HWND, MOD_ADMIN_PATCH_MSG, $isCHN ? 1 : 0, 0) # "success" message
    while GetMessage.call($buf, 0, 0, 0) > 0 # if quit immediatly, the "success" message will be racing with the exit of this subprocess; so let's wait for the parent process to respond first before exiting
    end
    exit
  end

  (MOD_PATCH_OPTION_COUNT...MOD_TOTAL_OPTION_COUNT).each {|i| ShowWindow.call($hWndChkBoxes[i], SW_SHOW)} # restore normal dialog layout
  ShowWindow.call($hWndDialog, SW_HIDE)
  SetWindowLong.call($hWndDialog, GWL_HWNDOWNER, $hWndDialogParent)
  SetWindowPos.call_r($hWndDialog, 0, 0, 0, MOD_DIALOG_WIDTH, MOD_DIALOG_HEIGHT, 0)
end

res = msgboxTxt(47, MB_ICONASTERISK|MB_YESNOCANCEL)
earlyQuit(staticIO) if res == IDCANCEL
staticIO.close if staticIO
if res == IDYES
  $hWnd = FindWindow.call(TSW_CLS_NAME, nil)
  if $hWnd.zero?
    shellExecuteInfo[1] = 0 # .fMask
    shellExecuteInfo[2] = 0 # .hwnd
    shellExecuteInfo[3] = 'open' # .lpVerb
    shellExecuteInfo[4] = MOD_TARGET_TSW_EXE # .lpFile
    shellExecuteInfo[5] = '' # .lpParameters
    shellExecuteInfo[7] = SW_RESTORE # .nShow
    shellExecuteInfo[8] = 0 # .hInstApp
    ShellExecuteEx.call_r(shellExecuteInfo.pack(SHELLEXECUTEINFO_STRUCT))
  else
    GetWindowThreadProcessId.call($hWnd, $bufDWORD)
    $pID = $bufDWORD.unpack('L')[0]
    $hWndTApp = GetWindowLong.call($hWnd, GWL_HWNDOWNER)
    msgboxTxt(48, MB_ICONEXCLAMATION, $pID)
  end
end
