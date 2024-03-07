// gcc -mwindows -std=gnu99 -Os -s -DNDEBUG -mpush-args -mno-accumulate-outgoing-args -mno-stack-arg-probe -mpreferred-stack-boundary=2 -fomit-frame-pointer dmg.exe.c -o dmg.exe

#include <windows.h>
typedef struct {
    SIZE_T addr;
    SIZE_T len;
    const char* bytes;
} PATCH;
const PATCH patches[] = { /*
404B24:
  Kernel32_FreeLibrary:
404BFC:
  Kernel32_LoadLibraryA:
404B84:
  Kernel32_GetProcAddress:
4BA1B5:
  DLL_IsInit: // byte
4BA1B8:
  DLL_str:
  db 'dmg',0
  DLL_ini_str:
  db 'ini',0
  DLL_fin_str:
  db 'fin',0
  DLL_inj_str:
  db 'inj',0
4BA1C8:
  DLL_addr:
4BA1CC:
  DLL_inj_addr:
4BA1D0:
  show_dmg:
  cmp byte ptr [4BA1B5], 0
  je +6
  call [DLL_inj_addr]
  ret

47D2D8:
  TTSW10_Help2Click: // F1
  cmp byte ptr [DLL_IsInit], 0
  jne +33 // ret
  push DLL_str
  call Kernel32_LoadLibraryA
  mov [DLL_addr], eax
  push DLL_ini_str
  push eax
  push DLL_inj_str
  push eax
  call Kernel32_GetProcAddress
  mov [DLL_inj_addr], eax
  call Kernel32_GetProcAddress
  call eax
  mov byte ptr [DLL_IsInit], 1
  ret

463874:
  TTSW10_GameQuit1Click: // F9
  cmp byte ptr [DLL_IsInit], 0
  je +1F // ret
  mov eax, [DLL_addr]
  push eax
  push DLL_fin_str
  push eax
  call Kernel32_GetProcAddress
  call eax
  call Kernel32_FreeLibrary
  mov byte ptr [DLL_IsInit], 0
  ret

443385: // right before epilog of TTSW10.Timer1Timer
  call show_dmg
  mov eax, ebx
  mov ebx, 48C5C4 // whether to redraw keys
  cmp word ptr [ebx], 0
  jne 44339F
  call 44BED8 // TTSW10.keydisp
  inc word ptr [ebx]

484B14:
  TTSW10_TSW10close:
  call TTSW10_GameQuit1Click // free dmg drawing-related GDI obj
  mov ebx, 48C514 // TSW game map bitmap 1
  mov eax, [ebx]
  call 402C34 // TObject.Free
  mov eax, [ebx+04]
  call 402C34
  mov eax, [ebx+08]
  call 402C34
  mov eax, [ebx+0C]
  call 402C34
  mov eax, [ebx+10]
  call 402C34
  nop  */
    {0x4BA1B5, 43, "\0\0\0" "dmg\0" "ini\0" "fin\0" "inj\0" "\0\0\0\0\0\0\0\0"
        "\x80\x3D\xB5\xA1\x4B\x00\x00\x74\x06\xFF\x15\xCC\xA1\x4B\x00\xC3"},
    {0x47D2D8, 61, "\x80\x3D\xB5\xA1\x4B\x00\x00\x75\x33\x68\xB8\xA1\x4B\x00\xE8\x11\x79\xF8\xFF\xA3\xC8\xA1\x4B\x00\x68\xBC\xA1\x4B\x00\x50\x68\xC4\xA1\x4B\x00\x50\xE8\x83\x78\xF8\xFF\xA3\xCC\xA1\x4B\x00\xE8\x79\x78\xF8\xFF\xFF\xD0\xC6\x05\xB5\xA1\x4B\x00\x01\xC3"},
    {0x463874, 41, "\x80\x3D\xB5\xA1\x4B\x00\x00\x74\x1F\xA1\xC8\xA1\x4B\x00\x50\x68\xC0\xA1\x4B\x00\x50\xE8\xF6\x12\xFA\xFF\xFF\xD0\xE8\x8F\x12\xFA\xFF\xC6\x05\xB5\xA1\x4B\x00\x00\xC3"},
    {0x484B14, 50, "\xE8\x5B\xED\xFD\xFF\xBB\x14\xC5\x48\x00\x8B\x03\xE8\x0F\xE1\xF7\xFF\x8B\x43\x04\xE8\x07\xE1\xF7\xFF\x8B\x43\x08\xE8\xFF\xE0\xF7\xFF\x8B\x43\x0C\xE8\xF7\xE0\xF7\xFF\x8B\x43\x10\xE8\xEF\xE0\xF7\xFF\x90"},
    {0x443385, 26, "\xE8\x46\x6E\x07\x00\x8B\xC3\xBB\xC4\xC5\x48\x00\x66\x83\x3B\x00\x75\x08\xE8\x3C\x8B\x00\x00\x66\xFF\x03"}};

#define check(ret) if(!ret) {msg = msg_f; goto end;}
int main() {
    const char* msg = "TSW injection OK. F1/F9 = Show/Hide on-map damage.";
    const char* msg_f = "TSW injection failed, possibly because TSW is not running or you don't have proper permissions.";
    HWND hWnd = FindWindow("TTSW10", NULL);
    check(hWnd);
    DWORD pID;
    HANDLE hPrc;
    GetWindowThreadProcessId(hWnd, &pID);
    check(pID);
    hPrc = OpenProcess(PROCESS_VM_WRITE | PROCESS_VM_OPERATION, 0, pID);
    check(hPrc);
    for(const PATCH *p = patches; p < (&patches)[1]; ++p)
        check(WriteProcessMemory(hPrc, (LPVOID)p->addr, p->bytes, p->len, NULL));
    CloseHandle(hPrc);
end:
    MessageBoxA(hWnd, msg, "TSW dmg extension", MB_ICONEXCLAMATION | MB_TOPMOST | MB_SETFOREGROUND);
    return 0;
}
