#ifndef RESOURCE_H
#define RESOURCE_H 1

#ifndef RCDATA
#define RCDATA 10
#endif
#ifndef MANIFEST
#define MANIFEST 24
#endif

#define DLG_FONT_SIZE 9

#define RT_EXERB                        RCDATA
#define ID_EXERB                        1
#define IDD_EXCEPTION                   1
#define IDI_RUBY                        1
#define IDM_MANIFEST                    1

#define ID_CLOSE                        1000
#define IDC_EDIT_MESSAGE                1001
#define IDC_EDIT_BACKTRACE              1002
#define IDC_EDIT_TYPE                   1003

#define IDC_STATIC_TITLE                1100
#define IDC_STATIC_MESSAGE              1101
#define IDC_STATIC_BACKTRACE            1102
#define IDC_STATIC_TYPE                 1103

#ifndef IDC_STATIC
#define IDC_STATIC -1
#endif

#define EXERB_RES_EXERB_VERSION1 3,2,2,0

#endif
