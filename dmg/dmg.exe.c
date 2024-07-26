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
404C5C:
  Gdi32_BitBlt:
404DCC:
  Gdi32_SelectObject:
40EC98:
  Comctl32_ImageList_DrawEx:
48C514:
  TTSW10_GAMEMAP_BITMAP_1_ADDR:
48C518:
  TTSW10_GAMEMAP_BITMAP_2_ADDR:
41A5B8:
  TCanvas_Draw:
41A950:
  TCanvas_GetHandle:
41DAD8:
  TBitmap_GetCanvas:
489C00:
  m_dmg_cri: // dword[121]
4BA1B5:
  DLL_IsInit: // byte
  db 0
4BA1B6:
  need_update: // byte
  db 3
4BA1B8:
  hMemDC:
4BA1BC:
  hMemBmp_1:
4BA1C0:
  hMemBmp_2:
4BA1C4:
  hPen_stroke:
4BA1C8:
  hPen_polyline:
4BA1CC:
  hFont_dmg:

4BA1D0:
  DLL_addr:
4BA1D4:
  DLL_cmp_addr:
4BA1D8:
  DLL_dtl_addr:
4BA1DC:
  DLL_dmp_addr:

4BA1E0:
  DLL_str:
  db 'dmg',0
  DLL_ini_str:
  db 'ini',0
  DLL_fin_str:
  db 'fin',0
  DLL_cmp_str:
  db 'cmp',0
  DLL_dtl_str:
  db 'dtl',0
  DLL_dmp_str:
  db 'dmp',0

4BA1F8:
draw_map:
  cmp byte ptr [DLL_IsInit], 0
  je TCanvas_Draw
  jmp [DLL_dmp_addr]
  nop

backup_tile_TCanvas_Draw:
  mov ebx, eax // TCanvas (dest)
  mov esi, [ebp+8] // TBitmap (src)

  xor edx, edx // now edx=0
  cmp byte ptr [DLL_IsInit], dl
  je +54 // loc_backup_tile_TCanvas_Draw_fin

  mov ecx, hMemBmp_1
  mov eax, [eax+34] // corresponding TBitmap of TBitmapCanvas (dest)
  cmp eax, [TTSW10_GAMEMAP_BITMAP_1_ADDR]
  je +0B // loc_backup_tile_TCanvas_Draw_work

  cmp eax, [TTSW10_GAMEMAP_BITMAP_2_ADDR]
  jne +3C // loc_backup_tile_TCanvas_Draw_fin
  add ecx, 4 // hMemBmp_2

  loc_backup_tile_TCanvas_Draw_work:
  push CC0020 // rop: SRCCOPY
  push edx // y1: 0
  push edx // x1: 0

  push [ecx] // HGDIOBJ h
  push [hMemDC] // HDC hdc
  call Gdi32_SelectObject

  mov eax, esi // TBitmap (src)
  call TBitmap_GetCanvas
  call TCanvas_GetHandle
  push eax // hdcSrc
  mov eax, [esi+10] // see TBitmap_GetWidth and TBitmap_GetHeight
  push [eax+18] // cy: height of TBitmap (src)
  push [eax+14] // cx: width of TBitmap (src)
  push [ebp-4] // y: top of TCanvas (dest) to draw
  push edi // x: left of TCanvas (dest) to draw
  push [hMemDC] // hdc

  call Gdi32_BitBlt
  loc_backup_tile_TCanvas_Draw_fin:
  ret

backup_tile_TCustomImageList_Draw:
  xor edx, edx // now edx=0
  cmp byte ptr [DLL_IsInit], dl
  je +41 // loc_backup_tile_TCustomImageList_Draw_fin

  mov ecx, hMemBmp_1
  mov esi, [esi+34] // corresponding TBitmap of TBitmapCanvas (dest) [its himl is already saved in eax; esi is now idle]
  cmp esi, [TTSW10_GAMEMAP_BITMAP_1_ADDR]
  je +0B // loc_backup_tile_TCustomImageList_Draw_work

  cmp esi, [TTSW10_GAMEMAP_BITMAP_2_ADDR]
  jne +29 // loc_backup_tile_TCustomImageList_Draw_fin
  add ecx, 4 // hMemBmp_2

  loc_backup_tile_TCustomImageList_Draw_work:
  push edx // fStyle: 0
  push -1 // rgbFg: CLR_NONE
  push edx // rgbBk: 0
  push edx // dy: 0 (full size)
  push edx // dx: 0 (full size)
  push [ebp+C] // y (from argv)
  push edi // x (from argv)
  push [hMemDC] // hdc
  push [ebp+8] // i (from argv)
  push eax // himl (from argv (processed in earlier codes in TCustomImageList_Draw))

  push [ecx] // HGDIOBJ h
  push [hMemDC] // HDC hdc
  call Gdi32_SelectObject

  call Comctl32_ImageList_DrawEx
  loc_backup_tile_TCustomImageList_Draw_fin:
  jmp Comctl32_ImageList_DrawEx

47D2D8:
TTSW10_Help2Click: // F1
  cmp byte ptr [DLL_IsInit], 0
  jne +33 // ret
  push DLL_str
  call Kernel32_LoadLibraryA
  mov [DLL_addr], eax
  push DLL_ini_str
  push eax
  push DLL_dmp_str
  push eax
  call Kernel32_GetProcAddress
  mov [DLL_dmp_addr], eax
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
  nop

41A5C6: // part of TCanvas_Draw
  call backup_tile_TCanvas_Draw
417EA7: // part of TCustomImageList_Draw
  call backup_tile_TCustomImageList_Draw
*/
    {0x4BA1B5, 267, "\0\3\0" "\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0"
        "dmg\0" "ini\0" "fin\0" "cmp\0" "ctl\0" "dmp\0"
        "\x80\x3D\xB5\xA1\x4B\x00\x00\x0F\x84\xB3\x03\xF6\xFF\xFF\x25\xDC\xA1\x4B\x00\x90\x8B\xD8\x8B\x75\x08\x31\xD2\x38\x15\xB5\xA1\x4B\x00\x74\x54\xB9\xBC\xA1\x4B\x00\x8B\x40\x34\x3B\x05\x14\xC5\x48\x00\x74\x0B\x3B\x05\x18\xC5\x48\x00\x75\x3C\x83\xC1\x04\x68\x20\x00\xCC\x00\x52\x52\xFF\x31\xFF\x35\xB8\xA1\x4B\x00\xE8\x82\xAB\xF4\xFF\x8B\xC6\xE8\x87\x38\xF6\xFF\xE8\xFA\x06\xF6\xFF\x50\x8B\x46\x10\xFF\x70\x18\xFF\x70\x14\xFF\x75\xFC\x57\xFF\x35\xB8\xA1\x4B\x00\xE8\xED\xA9\xF4\xFF\xC3\x31\xD2\x38\x15\xB5\xA1\x4B\x00\x74\x41\xB9\xBC\xA1\x4B\x00\x8B\x76\x34\x3B\x35\x14\xC5\x48\x00\x74\x0B\x3B\x35\x18\xC5\x48\x00\x75\x29\x83\xC1\x04\x52\x6A\xFF\x52\x52\x52\xFF\x75\x0C\x57\xFF\x35\xB8\xA1\x4B\x00\xFF\x75\x08\x50\xFF\x31\xFF\x35\xB8\xA1\x4B\x00\xE8\x16\xAB\xF4\xFF\xE8\xDD\x49\xF5\xFF\xE9\xD8\x49\xF5\xFF"},
    {0x47D2D8, 61, "\x80\x3D\xB5\xA1\x4B\x00\x00\x75\x33\x68\xE0\xA1\x4B\x00\xE8\x11\x79\xF8\xFF\xA3\xD0\xA1\x4B\x00\x68\xE4\xA1\x4B\x00\x50\x68\xF4\xA1\x4B\x00\x50\xE8\x83\x78\xF8\xFF\xA3\xDC\xA1\x4B\x00\xE8\x79\x78\xF8\xFF\xFF\xD0\xC6\x05\xB5\xA1\x4B\x00\x01\xC3"},
    {0x463874, 41, "\x80\x3D\xB5\xA1\x4B\x00\x00\x74\x1F\xA1\xD0\xA1\x4B\x00\x50\x68\xE8\xA1\x4B\x00\x50\xE8\xF6\x12\xFA\xFF\xFF\xD0\xE8\x8F\x12\xFA\xFF\xC6\x05\xB5\xA1\x4B\x00\x00\xC3"},
    {0x484B14, 50, "\xE8\x5B\xED\xFD\xFF\xBB\x14\xC5\x48\x00\x8B\x03\xE8\x0F\xE1\xF7\xFF\x8B\x43\x04\xE8\x07\xE1\xF7\xFF\x8B\x43\x08\xE8\xFF\xE0\xF7\xFF\x8B\x43\x0C\xE8\xF7\xE0\xF7\xFF\x8B\x43\x10\xE8\xEF\xE0\xF7\xFF\x90"},
    {0x44314E, 4, "\xA6\x70\x07\x00"},
    {0x443276, 4, "\x7E\x6F\x07\x00"},
    {0x417EA8, 4, "\xC4\x23\x0A\x00"},
    {0x41A5C6, 5, "\xE8\x41\xFC\x09\x00"},
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
