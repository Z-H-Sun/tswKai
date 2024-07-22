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
41A5B8:
  TCanvas_Draw:
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
  db 'dmg',0
4BA1C8:
  DLL_addr:
4BA1CC:
  DLL_inj_addr:
4BA1D0:
  draw_map:
  cmp byte ptr [DLL_IsInit], 0
  je TCanvas_Draw
  jmp [DLL_inj_addr]

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
4638A8: // this is within TTSW10_GameQuit1Click (won't be executed anymore, but patch it anyway)
  pop ebx
  jmp TTSW10_TSW10close

463933: // part of TTSW10_Exit1Click
  jmp TTSW10_TSW10close

44314D:
  call draw_map
443275:
  call draw_map

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
    {0x4BA1B5, 46, "\0\0\0" "dmg\0" "ini\0" "fin\0" "dmg\0" "\0\0\0\0\0\0\0\0"
        "\x80\x3D\xB5\xA1\x4B\x00\x00\x0F\x84\xDB\x03\xF6\xFF\xFF\x25\xCC\xA1\x4B\x00"},
    {0x47D2D8, 61, "\x80\x3D\xB5\xA1\x4B\x00\x00\x75\x33\x68\xB8\xA1\x4B\x00\xE8\x11\x79\xF8\xFF\xA3\xC8\xA1\x4B\x00\x68\xBC\xA1\x4B\x00\x50\x68\xC4\xA1\x4B\x00\x50\xE8\x83\x78\xF8\xFF\xA3\xCC\xA1\x4B\x00\xE8\x79\x78\xF8\xFF\xFF\xD0\xC6\x05\xB5\xA1\x4B\x00\x01\xC3"},
    {0x463874, 41, "\x80\x3D\xB5\xA1\x4B\x00\x00\x74\x1F\xA1\xC8\xA1\x4B\x00\x50\x68\xC0\xA1\x4B\x00\x50\xE8\xF6\x12\xFA\xFF\xFF\xD0\xE8\x8F\x12\xFA\xFF\xC6\x05\xB5\xA1\x4B\x00\x00\xC3"},
    {0x484B14, 50, "\xE8\x5B\xED\xFD\xFF\xBB\x14\xC5\x48\x00\x8B\x03\xE8\x0F\xE1\xF7\xFF\x8B\x43\x04\xE8\x07\xE1\xF7\xFF\x8B\x43\x08\xE8\xFF\xE0\xF7\xFF\x8B\x43\x0C\xE8\xF7\xE0\xF7\xFF\x8B\x43\x10\xE8\xEF\xE0\xF7\xFF\x90"},
    {0x44314E, 4, "\x7E\x70\x07\x00"},
    {0x443276, 4, "\x56\x6F\x07\x00"},
    {0x463933, 5, "\xE9\xDC\x11\x02\x00"},
    {0x4638A8, 6, "\x5B\xE9\x66\x12\x02\x00"}};

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
