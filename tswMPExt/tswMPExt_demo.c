// gcc -mwindows -std=gnu99 -Os -s -DNDEBUG tswMPExt_demo.c -o tswMPExt_demo.exe

#include <windows.h>
typedef struct {
    SIZE_T addr;
    SIZE_T len;
    const char* bytes;
} PATCH;
const PATCH patches[] = {
    {0x489DF0, 16, "SetDCBrushColor"},
    {0x4BA1B5, 3079, "\0\3\0" "\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0"
        "BeginPath\0\0\0" "EndPath\0" "StrokePath\0\0"
        "\x10\0\0\0" "\6\0\0\0" "\0\0\0\0" "\0\0\0\0" "\xBC\2\0\0" "\0\0\0\0\0\0\3\0" "Tahoma\0\0"
        "\x22\xAA\x22\0" "\xC0\xA0\x60\0" "\xFF\x22\x22\0" "\x40\x7F\xC0\0" "\x88\x99\x88\0" "\x66\x66\x66\0" "\xFF\xFF\xFF\0"
        "\x8B\xD8\x8B\x75\x08\x31\xD2\x38\x15\xB5\xA1\x4B\x00\x74\x54\xB9\xBC\xA1\x4B\x00\x8B\x40\x34\x3B\x05\x14\xC5\x48\x00\x74\x0B\x3B\x05\x18\xC5\x48\x00\x75\x3C\x83\xC1\x04\x68\x20\x00\xCC\x00\x52\x52\xFF\x31\xFF\x35\xB8\xA1\x4B\x00\xE8\x52\xAB\xF4\xFF\x8B\xC6\xE8\x57\x38\xF6\xFF\xE8\xCA\x06\xF6\xFF\x50\x8B\x46\x10\xFF\x70\x18\xFF\x70\x14\xFF\x75\xFC\x57\xFF\x35\xB8\xA1\x4B\x00\xE8\xBD\xA9\xF4\xFF\xC3\x31\xD2\x38\x15\xB5\xA1\x4B\x00\x74\x41\xB9\xBC\xA1\x4B\x00\x8B\x76\x34\x3B\x35\x14\xC5\x48\x00\x74\x0B\x3B\x35\x18\xC5\x48\x00\x75\x29\x83\xC1\x04\x52\x6A\xFF\x52\x52\x52\xFF\x75\x0C\x57\xFF\x35\xB8\xA1\x4B\x00\xFF\x75\x08\x50\xFF\x31\xFF\x35\xB8\xA1\x4B\x00\xE8\xE6\xAA\xF4\xFF\xE8\xAD\x49\xF5\xFF\xE9\xA8\x49\xF5\xFF\x80\x3D\xB5\xA1\x4B\x00\x00\x75\x07\xE9\xBA\x02\xF6\xFF\x66\x90\x55\x57\x56\x53\x50\x8B\x83\x54\x02\x00\x00\xFF\x70\x2C\x80\x3D\xE4\x9D\x48\x00\x00\x74\x0E\x8B\x44\x24\x1C\xE8\xB4\x08\x00\x00\xE9\x03\x02\x00\x00\x8B\x44\x24\x1C\xE8\xAA\x37\xF6\xFF\xE8\x1D\x06\xF6\xFF\x8B\xF8\xBE\xB6\xA1\x4B\x00\x80\x7E\x01\x01\x74\x1F\x83\x3D\xCC\x86\x4B\x00\x01\x74\x16\xF6\x06\x10\x0F\x85\xD6\x01\x00\x00\xE8\x1D\x03\x00\x00\x80\x0E\x13\xE9\xC9\x01\x00\x00\xF6\x06\x08\x74\x0C\x83\x3D\xAC\xC5\x48\x00\x00\x7F\xDC\x80\x26\xF3\xF6\x06\x04\x74\x10\x83\x3D\xAC\xC5\x48\x00\x00\x0F\x8F\xA6\x01\x00\x00\x80\x26\xFB\xE8\x7A\x06\x00\x00\x0F\xB6\x0D\xD2\xC5\x48\x00\x8D\x41\x01\x84\x06\x0F\x84\x8F\x00\x00\x00\xB0\x02\x29\xC8\x20\x06\xA1\xB8\xA1\x4B\x00\x31\xDB\x6B\x14\x24\x0B\x68\x20\x00\xCC\x00\x53\x53\x50\x52\x52\x53\x53\x57\xFF\x34\x8D\xBC\xA1\x4B\x00\x50\xE8\x05\xAA\xF4\xFF\xE8\x90\xA8\xF4\xFF\xFF\x35\xCC\xA1\x4B\x00\x57\xFF\x35\xC4\xA1\x4B\x00\x57\x6A\x01\x57\xE8\x02\xAA\xF4\xFF\xE8\xE5\xA9\xF4\xFF\x8B\xF0\xE8\xDE\xA9\xF4\xFF\x8B\xE8\xB1\x0B\x8B\xC3\xF6\xF1\x40\x88\xE1\xF6\x24\x24\xC1\xE0\x10\x88\xC8\xF6\x24\x24\x8B\xC8\x8B\xD3\x80\xCA\x80\x8B\xC7\xE8\x7A\x04\x00\x00\x43\x83\xFB\x79\x75\xD8\x55\x57\x56\x57\xE8\xAB\xA9\xF4\xFF\xE8\xA6\xA9\xF4\xFF\xE9\xFD\x00\x00\x00\x83\x3D\xAC\xC5\x48\x00\x00\x0F\x8F\xF0\x00\x00\x00\x8B\x0D\xA0\x86\x4B\x00\xA1\xA4\x86\x4B\x00\x6B\xD8\x0B\x01\xCB\x40\xF6\x24\x24\xC1\xE0\x10\x88\xC8\xF6\x24\x24\x8B\xC8\x8B\xD3\x8B\xC7\xE8\x2D\x04\x00\x00\xA1\x14\xC5\x48\x00\x8B\x15\x18\xC5\x48\x00\x3B\x44\x24\x1C\x0F\x44\xC2\xE8\x62\x36\xF6\xFF\xE8\xD5\x04\xF6\xFF\x8B\xE8\xBA\x80\xC5\x48\x00\x8B\x02\x89\x1A\x3C\x79\x73\x32\x39\xD8\x74\x2E\x88\xC7\xB1\x0B\xF6\xF1\x40\x88\xE1\xF6\x24\x24\xC1\xE0\x10\x88\xC8\xF6\x24\x24\x8B\xF0\x8B\xC8\x88\xFA\x8B\xC7\xE8\xDD\x03\x00\x00\x8B\xCE\x88\xFA\xB7\x00\x8B\xC5\xE8\xD0\x03\x00\x00\xBA\x84\xC5\x48\x00\x8B\x02\x89\x1A\x3C\x79\x73\x5F\x29\xC3\x8B\x15\xA0\x86\x4B\x00\x4B\x75\x04\x85\xD2\x75\x13\x43\x43\x75\x05\x83\xFA\x0A\x75\x0A\x83\xFB\x0B\x74\x05\x83\xFB\xF5\x75\x3D\x6B\x15\x98\x86\x4B\x00\x7B\x80\xBC\x10\x36\x89\x4B\x00\x06\x75\x2C\x8B\xD8\xB1\x0B\xF6\xF1\x40\x88\xE1\xF6\x24\x24\xC1\xE0\x10\x88\xC8\xF6\x24\x24\x8B\xF0\x8B\xC8\x8B\xD3\x8B\xC7\xE8\x6F\x03\x00\x00\x8B\xCE\x8B\xD3\x8B\xC5\xE8\x64\x03\x00\x00\x5E\x6B\xF6\x0B\x58\xE8\x1E\x04\xF6\xFF\x68\x20\x00\xCC\x00\x6A\x00\x6A\x00\x57\x56\x56\xFF\x35\x7C\xC5\x48\x00\xFF\x35\x78\xC5\x48\x00\x50\xE8\x0C\xA7\xF4\xFF\x5B\x5E\x5F\x5D\xC2\x04\x00\x90\x57\x56\x53\x8B\x80\x20\x01\x00\x00\xE8\xEA\x03\xF6\xFF\x8B\xF0\x50\xE8\x16\xA7\xF4\xFF\xA3\xB8\xA1\x4B\x00\x8B\xF8\x31\xC0\xFF\x35\x34\xA2\x4B\x00\x50\x6A\x03\x50\x54\xE8\x1D\xA7\xF4\xFF\xA3\xC4\xA1\x4B\x00\xA1\x30\xA2\x4B\x00\x89\x44\x24\x0C\x54\xE8\x09\xA7\xF4\xFF\xA3\xC8\xA1\x4B\x00\x83\xC4\x10\x68\xFC\xA1\x4B\x00\xE8\xE7\xA6\xF4\xFF\xA3\xCC\xA1\x4B\x00\x68\x5E\xBC\x4B\x00\xE8\xF4\x6C\xF4\xFF\x68\xF0\x9D\x48\x00\x50\x68\xF0\xA1\x4B\x00\x50\x68\xE8\xA1\x4B\x00\x50\x68\xDC\xA1\x4B\x00\x50\xE8\xAB\xA5\xF4\xFF\xA3\xD0\xA1\x4B\x00\xE8\xA1\xA5\xF4\xFF\xA3\xD4\xA1\x4B\x00\xE8\x97\xA5\xF4\xFF\xA3\xD8\xA1\x4B\x00\xE8\x8D\xA5\xF4\xFF\xA3\xEC\x9D\x48\x00\x6A\x12\xE8\x41\xA7\xF4\xFF\xA3\xDC\xA6\x48\x00\x31\xDB\x43\x68\xE0\x01\x00\x00\x68\xB8\x01\x00\x00\x56\xE8\x61\xA6\xF4\xFF\x89\x04\x9D\xBC\xA1\x4B\x00\x50\x57\xE8\xA3\xA7\xF4\xFF\x8B\x04\x9D\x14\xC5\x48\x00\xE8\xA3\x34\xF6\xFF\xE8\x16\x03\xF6\xFF\x31\xD2\xB9\xB8\x01\x00\x00\x68\x20\x00\xCC\x00\x52\x52\x50\x51\x51\x52\x52\x57\xE8\x09\xA6\xF4\xFF\x4B\x74\xB5\x80\x0D\xB6\xA1\x4B\x00\x03\xC6\x05\xB5\xA1\x4B\x00\x01\x5B\x5E\x5F\xC3\xC6\x05\xB5\xA1\x4B\x00\x00\x68\xC5\xA6\x4B\x00\x53\x31\xDB\x43\x8B\x04\x9D\x14\xC5\x48\x00\xE8\x54\x34\xF6\xFF\xE8\xC7\x02\xF6\xFF\x8B\x15\xB8\xA1\x4B\x00\xB9\xB8\x01\x00\x00\x68\x20\x00\xCC\x00\x6A\x00\x6A\x00\x52\x51\x51\x6A\x00\x6A\x00\x50\xFF\x34\x9D\xBC\xA1\x4B\x00\x52\xE8\x1A\xA7\xF4\xFF\xE8\xA5\xA5\xF4\xFF\x4B\x74\xBE\x5B\xC3\x80\x3D\xB5\xA1\x4B\x00\x00\x74\x31\x56\xBE\xB8\xA1\x4B\x00\x6A\x00\x6A\x00\xFF\x36\xE8\xA6\xA5\xF4\xFF\x50\xFF\x36\xE8\xEE\xA6\xF4\xFF\xFC\xAD\x50\xE8\xD6\xA5\xF4\xFF\xAD\x50\xE8\xDF\xA5\xF4\xFF\x81\xFE\xCC\xA1\x4B\x00\x76\xF1\x5E\xC3\x90\x31\xC9\x66\x3D\xFF\xFF\x75\x0A\xC7\x02\x3F\x3F\x3F\x00\x8D\x41\x03\xC3\x66\x3D\x0A\x00\x72\x16\x41\x66\x3D\x64\x00\x72\x0F\x41\x66\x3D\xE8\x03\x72\x08\x41\x66\x3D\x10\x27\x72\x01\x41\x51\x53\x8D\x1C\x11\xB1\x0A\x31\xD2\x66\xF7\xF1\x83\xC2\x30\x88\x13\x4B\x66\x85\xC0\x75\xF0\x5B\x58\x40\xC3\x0F\x1F\x00\xB2\xFE\x3C\x08\x72\x2D\x3C\x3D\x73\x07\x3C\x1D\x73\x25\xB0\xFF\xC3\x3C\x61\x73\x05\x2C\x3D\xD0\xE8\xC3\xB2\x12\x3C\x6A\x72\x13\x42\x3C\x7A\x74\x0E\x8D\x50\xA3\xD0\xEA\x2C\x85\x3C\x1A\xB0\xFF\x0F\x43\xD0\x88\xD0\xC3\x66\x90\x55\x57\x56\x53\x83\xEC\x0C\x89\x54\x24\x08\x8B\x2D\x04\x89\x4B\x00\x45\x8B\x1D\x8C\x86\x4B\x00\x0F\xB6\xD0\xC1\xE2\x04\x8D\xB2\x10\x99\x48\x00\x8B\x7E\x08\x0F\xAF\xFD\x8D\x48\xF4\x80\xF9\x02\x72\x04\x3C\x11\x75\x0C\x83\x3D\xD8\x86\x4B\x00\x01\x0F\x94\xC0\xEB\x11\x83\x3D\xF4\x86\x4B\x00\x01\x0F\x94\xC1\x3C\x13\x0F\x94\xC0\x21\xC8\x88\x04\x24\x8B\xCB\x29\xF9\x85\xC9\x7F\x1F\x8B\xC1\xF7\xD8\x31\xD2\xF7\xF5\x40\xBA\xFF\x7F\x00\x00\x39\xD0\x0F\x47\xC2\x80\xCC\x80\x66\xB9\xFF\xFF\xE9\x85\x00\x00\x00\x80\x3C\x24\x00\x74\x02\x01\xD9\x8B\x06\xF7\xED\x89\x44\x24\x04\x85\xC0\x7E\x05\x48\x31\xD2\xF7\xF1\x8B\x4E\x04\x8B\xF0\x0F\xAF\xCD\x31\xC0\x2B\x0D\x90\x86\x4B\x00\x0F\x48\xC8\x8B\x44\x24\x08\x01\xF0\x0F\xAF\xC8\xB8\xFF\x7F\x00\x00\x85\xC9\x74\x47\x85\xF6\x74\x1A\x8B\x44\x24\x04\x48\x31\xD2\xF7\xF6\x01\xF8\x80\x3C\x24\x00\x74\x02\xD1\xE8\x29\xD8\x31\xD2\xF7\xF5\x40\xBB\xFF\x7F\x00\x00\x39\xD8\x0F\x42\xD8\x3B\x0D\x88\x86\x4B\x00\x72\x03\x80\xCF\x80\x8D\x41\xFF\x31\xD2\xF7\xF5\x40\xB9\xFF\xFF\x00\x00\x39\xC8\x0F\x42\xC8\x8B\xC3\xC1\xE0\x10\x66\x89\xC8\x83\xC4\x0C\x5B\x5E\x5F\x5D\xC3\x55\x8B\xEA\x83\xE5\x7F\x8B\x2C\xAD\x00\x9C\x48\x00\x83\xFD\xFE\x74\xEC\x57\x56\x53\x83\xEC\x20\x8B\xD8\x0F\xB7\xF1\xC1\xE9\x10\x8B\xF9\x55\x80\x64\x24\x03\x7F\xC0\xEA\x07\x88\x14\x24\x85\xED\x78\x0B\x6A\x0D\x53\xFF\x35\x38\xA2\x4B\x00\xEB\x09\x6A\x10\x53\xFF\x35\x28\xA2\x4B\x00\x53\xE8\x2C\xA5\xF4\xFF\xE8\x17\xA5\xF4\xFF\x80\x3C\x24\x00\x75\x28\x6A\x01\x53\xE8\xF9\xA4\xF4\xFF\xFF\x35\xC4\xA1\x4B\x00\x53\xE8\xD5\xA4\xF4\xFF\x89\x44\x24\x04\xFF\x35\xCC\xA1\x4B\x00\x53\xE8\xC5\xA4\xF4\xFF\x89\x44\x24\x08\x53\xFF\x15\xD0\xA1\x4B\x00\x8B\xC5\x8D\x54\x24\x0C\xE8\xDB\xFD\xFF\xFF\x8D\x54\x24\x0C\x8B\xE8\x66\x83\x7C\x24\x02\x00\x74\x72\x83\xEF\x0F\x46\x55\x52\x57\x56\x53\xE8\xFB\xA4\xF4\xFF\x66\x8B\x44\x24\x02\x66\x3D\xFF\x7F\x74\x1E\x8D\x54\x24\x14\xE8\xAB\xFD\xFF\xFF\x89\x44\x24\x1C\x8D\x54\x24\x14\x8D\x4F\xF4\x50\x52\x51\x56\x53\xE8\xD2\xA4\xF4\xFF\x53\xFF\x15\xD4\xA1\x4B\x00\x53\xFF\x15\xD8\xA1\x4B\x00\x8D\x54\x24\x0C\x55\x52\x57\x56\x53\xE8\xB6\xA4\xF4\xFF\x66\x81\x7C\x24\x02\xFF\x7F\x74\x5B\x83\xEF\x0C\x8D\x54\x24\x14\xFF\x74\x24\x1C\x52\x57\x56\x53\xE8\x99\xA4\xF4\xFF\xEB\x45\xA1\x10\xC5\x48\x00\x8B\x80\x54\x02\x00\x00\x8B\x40\x2C\x8D\x4C\x24\x14\x89\x31\x89\x79\x0C\x29\xC7\x89\x79\x04\x01\xC6\x89\x71\x08\x6A\x25\x51\x55\x52\x53\x53\x53\x6A\x25\x51\x55\x52\x53\xE8\x3B\xA5\xF4\xFF\xFF\x15\xD4\xA1\x4B\x00\xFF\x15\xD8\xA1\x4B\x00\xE8\x2A\xA5\xF4\xFF\x80\x3C\x24\x00\x75\x14\xFF\x74\x24\x04\x53\xE8\xDA\xA3\xF4\xFF\xFF\x74\x24\x08\x53\xE8\xD0\xA3\xF4\xFF\x83\xC4\x24\x5B\x5E\x5F\x5D\xC3\x56\x53\x50\x31\xDB\x6B\x05\x98\x86\x4B\x00\x7B\x8D\xB0\x36\x89\x4B\x00\x8A\x04\x33\xE8\x26\xFD\xFF\xFF\x84\xC0\x0F\x89\x00\x01\x00\x00\xFE\xC0\x74\x09\x83\x3D\x2C\x87\x4B\x00\x00\x74\x23\xB8\xFE\xFF\xFF\xFF\x8D\x14\x9D\x00\x9C\x48\x00\x39\x02\x74\x09\x89\x02\x80\x0D\xB6\xA1\x4B\x00\x03\x43\x83\xFB\x79\x75\xC4\x58\x5B\x5E\xC3\x31\xD2\x89\x14\x24\x8B\xC3\xB2\x0B\xF6\xF2\x8B\xC8\x84\xED\x74\x0C\x8A\x44\x33\xFF\xE8\xD4\xFC\xFF\xFF\x88\x04\x24\x80\xFD\x0A\x74\x0D\x8A\x44\x33\x01\xE8\xC3\xFC\xFF\xFF\x88\x44\x24\x01\x84\xC9\x74\x0D\x8A\x44\x33\xF5\xE8\xB2\xFC\xFF\xFF\x88\x44\x24\x02\x80\xF9\x0A\x74\x0D\x8A\x44\x33\x0B\xE8\xA0\xFC\xFF\xFF\x88\x44\x24\x03\x8D\x04\x24\x31\xC9\x8A\x10\x80\xFA\x1D\x75\x06\x81\xC1\xC8\x00\x00\x00\x80\xFA\x1E\x75\x03\x83\xC1\x64\x40\x8D\x54\x24\x04\x39\xC2\x75\xE2\xA1\x04\x89\x4B\x00\x8D\x50\x01\x0F\xAF\xCA\xA1\x88\x86\x4B\x00\x66\x81\x3C\x24\x10\x10\x74\x09\x66\x81\x7C\x24\x02\x10\x10\x75\x09\x85\xC0\x7E\x05\x40\xD1\xE8\x01\xC1\x89\x14\x24\x85\xC9\x0F\x84\x33\xFF\xFF\xFF\x31\xD2\x8D\x41\xFF\xF7\x34\x24\x40\x3B\x0D\x88\x86\x4B\x00\x0F\x93\xC2\xC1\xE2\x1F\xB9\xFF\xFF\x00\x00\x39\xC1\x0F\x42\xC1\x09\xD0\xE9\x12\xFF\xFF\xFF\x31\xD2\x8B\x0D\x98\x86\x4B\x00\x83\xF9\x20\x75\x0C\x3C\x14\x0F\x94\xC2\xE8\x3F\xFC\xFF\xFF\xEB\xE2\x83\xF9\x32\x75\x17\x39\x15\x04\x89\x4B\x00\x74\xEC\x39\x15\x08\x89\x4B\x00\x75\xE4\x3C\x0F\x0F\x94\xC2\xEB\xDD\x83\xF9\x28\x75\x14\x80\x7E\x47\x07\x74\xD2\x80\x7E\x05\x0B\x74\xCC\x83\xFB\x4D\x0F\x92\xC2\xEB\xC4\x83\xF9\x31\x75\x18\x80\x7E\x3C\x07\x74\xB9\x83\xFB\x2C\x73\xB4\x39\x15\xAC\xC5\x48\x00\x7E\xAC\xE9\xBB\xFE\xFF\xFF\x83\xF9\x14\x75\xA2\x80\x7E\x52\x07\x74\x9C\x3C\x11\x74\xE4\xEB\x96\x66\x90\x8B\x15\x10\xC5\x48\x00\x8B\x92\x54\x02\x00\x00\x8B\x52\x2C\x89\x50\x08\x89\x50\x0C\xD1\xEA\x8B\x0D\x00\x9E\x48\x00\x29\xD1\x89\x08\x8B\x0D\x04\x9E\x48\x00\x29\xD1\x89\x48\x04\xC3\x0F\x1F\x00\xE8\xFF\x2E\xF6\xFF\xE8\x72\xFD\xF5\xFF\x8B\xF8\x0F\xB6\x2D\xD2\xC5\x48\x00\x8D\x5C\x2D\x02\xA0\xE4\x9D\x48\x00\x84\xD8\x75\xDC\xA8\x06\x75\x28\x8B\x15\x78\xC5\x48\x00\x8B\x0D\x7C\xC5\x48\x00\xBE\x00\x9E\x48\x00\xA0\xE5\x9D\x48\x00\x83\xE0\x3F\x8D\x04\xC6\x29\x16\x29\x4E\x04\x83\xC6\x08\x39\xF0\x73\xF4\x08\x1D\xE4\x9D\x48\x00\x68\x20\x00\xCC\x00\x51\x51\x57\x83\xEC\x10\x8B\xC4\xE8\x6C\xFF\xFF\xFF\x59\x5A\x89\x4C\x24\x0C\x89\x54\x24\x10\x68\xB8\x01\x00\x00\x6A\x00\xA1\xB8\xA1\x4B\x00\x50\xFF\x34\xAD\xBC\xA1\x4B\x00\x50\xE8\x70\xA1\xF4\xFF\xE8\xFB\x9F\xF4\xFF\x8B\xC7\xEB\x1F\x0F\x1F\x00\xC6\x05\xB8\x86\x4B\x00\x01\xC6\x05\xE4\x9D\x48\x00\x01\x8B\x80\x20\x01\x00\x00\xE8\xCF\xFC\xF5\xFF\x0F\x1F\x00\x53\x8B\xD8\x51\x50\x68\x89\x00\xFA\x00\x83\xEC\x10\x0F\xB6\x05\xE5\x9D\x48\x00\xC0\xE8\x06\xFF\x34\x85\x20\xA2\x4B\x00\x53\xFF\x15\xEC\x9D\x48\x00\x8B\xC4\xE8\xF4\xFE\xFF\xFF\xFF\x35\xDC\xA6\x48\x00\x53\xE8\x10\xA1\xF4\xFF\x89\x44\x24\x18\x53\xE8\xC6\xA0\xF4\xFF\xE8\x01\xA1\xF4\xFF\x8B\xC3\x5B\x66\x90\x8A\x15\xE5\x9D\x48\x00\x80\xE2\x3F\x74\x2F\x0F\xB6\xD2\x42\x51\x50\x52\x68\x00\x9E\x48\x00\x50\xFF\x35\xC8\xA1\x4B\x00\x50\x6A\x07\x50\xE8\xFD\xA0\xF4\xFF\xE8\xD0\xA0\xF4\xFF\x89\x44\x24\x10\xE8\x97\xA0\xF4\xFF\xE8\xC2\xA0\xF4\xFF\xC3\x90\x55\x57\x56\x53\x8B\x88\x54\x02\x00\x00\x8B\x71\x2C\x8B\x80\x20\x01\x00\x00\xE8\x2C\xFC\xF5\xFF\x8B\xE8\x31\xDB\x43\x8B\x04\x9D\x14\xC5\x48\x00\xE8\xA3\x2D\xF6\xFF\xE8\x16\xFC\xF5\xFF\x8B\xF8\x8D\x54\x1B\x02\x84\x15\xE4\x9D\x48\x00\x74\x37\xE8\x83\xFF\xFF\xFF\x68\x20\x00\xCC\x00\x68\xB8\x01\x00\x00\x6A\x00\xFF\x35\xB8\xA1\x4B\x00\x83\xEC\x10\x8B\xC4\xE8\x3B\xFE\xFF\xFF\x57\xB9\xB8\xA1\x4B\x00\xFF\x74\x99\x04\xFF\x31\xE8\x52\xA0\xF4\xFF\xE8\xDD\x9E\xF4\xFF\x38\x1D\xD2\xC5\x48\x00\x75\x1F\x6B\xF6\x0B\x68\x20\x00\xCC\x00\x6A\x00\x6A\x00\x57\x56\x56\xB9\x7C\xC5\x48\x00\xFF\x31\xFF\x71\xFC\x55\xE8\xB6\x9E\xF4\xFF\x4B\x74\x80\xC6\x05\xB8\x86\x4B\x00\x00\xC6\x05\xE4\x9D\x48\x00\x00\x5B\x5E\x5F\x5D\xC3"},

    {0x46396F, 5, "\xE8\x48\x6D\x05\x00"},
    {0x4638E4, 5, "\xE8\xD3\x6D\x05\x00"},
    {0x484B50, 5, "\xE8\x67\x5B\x03\x00"},
    {0x44314E, 4, "\x9E\x71\x07\x00"},
    {0x443276, 4, "\x76\x70\x07\x00"},
    {0x417EA8, 4, "\xF4\x23\x0A\x00"},
    {0x41A5C6, 5, "\xE8\x71\xFC\x09\x00"},

    {0x442C4A, 58, "\x40\x8B\xF0\xEB\x02\xEB\x07\x80\x0D\xB6\xA1\x4B\x00\x03\x89\x37\x8B\xC6\x8A\x80\x1F\x9B\x48\x00\xB1\x0B\xF6\xF1\x8B\x93\x54\x02\x00\x00\x8B\x4A\x2C\x88\xE5\xF6\xE1\xA3\x50\xC5\x48\x00\x50\x88\xE8\xF6\xE1\xA3\x4C\xC5\x48\x00\xEB\x15"},
    {0x450BE7, 9, "\x80\x0D\xB6\xA1\x4B\x00\x04\x66\x90"},
    {0x451939, 20, "\xC7\x04\x45\x4E\xC7\x48\x00\x00\x00\x00\x00\x80\x0D\xB6\xA1\x4B\x00\x03\x66\x90"},
    {0x44A54A, 25, "\xBA\x54\xC5\x48\x00\x8B\x02\x2D\xC6\x00\x00\x00\x89\x42\x08\x89\x42\x64\x80\x0D\xB6\xA1\x4B\x00\x04"},
    {0x449E66, 13, "\x31\xDB\x89\x1C\x4A\x80\x0D\xB6\xA1\x4B\x00\x08\x90"},

    {0x442F1D, 42, "\x68\x61\x2F\x44\x00\x68\x04\xAA\x4B\x00\x90\x80\x3D\xB5\xA1\x4B\x00\x00\x74\x12\x80\x3D\xB7\xA1\x4B\x00\x00\x75\x0C\x80\x3D\xCC\x86\x4B\x00\x01\x74\x03\x83\xC4\x04\xC3"},
    {0x45458F, 164, "\x68\x10\x46\x45\x00\xA1\x70\xC5\x48\x00\x8A\x80\x1F\x9B\x48\x00\x50\xBE\xA0\x86\x4B\x00\x6B\x56\x04\x0B\x03\x16\x39\xD0\x75\x07\x8B\xC3\xE8\xEE\xED\xFE\xFF\xBA\x4C\xC5\x48\x00\x8B\x42\x30\x03\x42\x04\x8B\x4A\x2C\x03\x0A\x8B\x93\x54\x02\x00\x00\x8B\x52\x2C\x01\xC2\x66\x52\x66\x51\x50\x8B\x44\x24\x08\x6B\x56\xF8\x7B\x8A\x84\x10\x36\x89\x4B\x00\x48\x50\x8B\x93\x20\x01\x00\x00\x8B\x83\xB0\x01\x00\x00\xE8\x4C\x38\xFC\xFF\x8B\x83\x20\x01\x00\x00\xE8\x4D\x63\xFC\xFF\x59\x5A\xE8\x1E\xE9\xFE\xFF\xE9\x7D\x62\x06\x00\x90\xB9\xAC\xC5\x48\x00\x6B\x01\x06\x80\x7C\x08\x9A\x15\x0F\x85\x91\x01\x00\x00\x80\x7C\x08\x9C\x01\x0F\x85\x86\x01\x00\x00\xFF\x09\x8B\x01\x90"},
    {0x454741, 7, "\xE8\x4E\xFE\xFF\xFF\xEB\x6C"},

    {0x48074B, 49, "\xA1\x14\xC5\x48\x00\x0F\x45\x05\x18\xC5\x48\x00\xE8\x7C\xD3\xF9\xFF\x50\xFF\x35\x1C\xC5\x48\x00\x8B\x15\x4C\xC5\x48\x00\x8B\x0D\x50\xC5\x48\x00\xE8\x44\x9E\xF9\xFF\x58\xE8\x66\x00\x00\x00\xEB\x15"},
    {0x4807C5, 110, "\xFF\x05\x58\xC5\x48\x00\xFF\x05\x54\xC5\x48\x00\x8B\xC3\xE8\xB8\x02\x00\x00\xE9\x4C\x02\x00\x00\x0F\x1F\x00\xE8\x43\x27\xFC\xFF\xE8\x66\xA1\xF9\xFF\x8B\x93\x54\x02\x00\x00\x8B\x52\x2C\x8B\x0D\x5C\xC5\x48\x00\x8A\x35\x68\xC5\x48\x00\xF6\xC6\x01\x75\x04\x28\xD1\xF6\xD9\x80\xEE\x02\x80\xFE\x01\x76\x03\xC1\xE1\x10\xB6\x00\x03\x15\x50\xC5\x48\x00\xC1\xE2\x10\x66\x8B\x15\x4C\xC5\x48\x00\x01\xD1\x6B\x17\x06\x8A\x54\x32\x02\xE9\x59\xA0\x03\x00"},
    {0x480A29, 95, "\xA1\x18\xC5\x48\x00\xE8\xA5\xD0\xF9\xFF\x50\xFF\x35\x1C\xC5\x48\x00\x8B\x15\x4C\xC5\x48\x00\x8B\x0D\x50\xC5\x48\x00\xE8\x6D\x9B\xF9\xFF\x58\xE8\x8F\xFD\xFF\xFF\x66\x90\x6B\x17\x06\x0F\xB7\x7C\x32\x02\x0F\xB7\x74\x32\x04\xBA\x00\x9C\x48\x00\x8B\x04\xBA\xC7\x04\xBA\xFE\xFF\xFF\xFF\x89\x04\xB2\x6B\x05\x98\x86\x4B\x00\x7B\x05\x36\x89\x4B\x00\x8A\x0C\x38\xC6\x04\x38\x06\x88\x0C\x30"},

    {0x47D2D8, 14, "\x80\x3D\xB5\xA1\x4B\x00\x00\x0F\x84\x73\xD2\x03\x00\xC3"},
    {0x463874, 14, "\x80\x3D\xB5\xA1\x4B\x00\x00\x0F\x85\xE7\x6D\x05\x00\xC3"}
    };

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