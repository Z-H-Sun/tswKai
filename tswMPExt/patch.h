#include <windows.h>
typedef struct {
    SIZE_T addr;
    SIZE_T len;
    const char* bytes;
} PATCH;

#define check(ret) if(!ret) {msg = msg_f; goto end;}
static inline void patch(const PATCH *p_start, const PATCH *p_end) {
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
    for(const PATCH *p = p_start; p < p_end; ++p)
        check(WriteProcessMemory(hPrc, (LPVOID)p->addr, p->bytes, p->len, NULL));
    CloseHandle(hPrc);
end:
    MessageBoxA(hWnd, msg, "TSW dmg extension", MB_ICONEXCLAMATION | MB_TOPMOST | MB_SETFOREGROUND);
}
