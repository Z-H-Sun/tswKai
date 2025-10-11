#include "patch.h"

#define hwnd hWndConf // in this file, hwnd is mainly for the config window
extern HWND hWndConf;
extern char tsw_exe_conf_path[];

BOOL has_item_changed, is_chinese_exe, is_v_3_1_0;
FILE* tsw_exe_conf_f = NULL;
struct __pascal_short_string {
  unsigned char fontName_len;
  char fontName[LF_FACESIZE];
} readFontName_s; // ascii
WCHAR readFontName_w[LF_FACESIZE]; // unicode
INT_PTR readFontIndex; // initial index in dropbox

/**
 * Checks if the given Unicode font name is too long for compatibility with TSW's ANSI font creation.
 *
 * Windows truncates Unicode font names longer than 31 TCHARs, but TSW uses the ANSI API, where the
 * ANSI-encoded font name may exceed 31 bytes if non-ASCII characters are present. In such cases,
 * Windows cannot find the font by name. This function determines if the font name is too long to avoid
 * this issue.
 *
 * @param fontName_w Pointer to a null-terminated Unicode (WCHAR) string representing the font name.
 * @return TRUE if the font name is too long for ANSI compatibility; FALSE otherwise.
 */
BOOL isFontNameTooLong(WCHAR* fontName_w) { // when the Unicode font name is too long (>31 TCHARs), Windows will truncate the Unicode font name to 31 TCHARs, which is OK and Windows can still find this font; however, TSW uses the ANSI version API to create fonts, so the font name is stored in the ANSI encoding, and the ANSI font name can exceed 31 bytes if the 31-TCHAR-long Unicode font name contains non-ASCII characters, in which case Windows cannot find the font with this name, so we need to avoid these long-named fonts
  int len;
  if (!is_chinese_exe || // non-Chinese exe: use system code page for transcoding
      !(len = WideCharToMultiByte(CP_GB2312, 0, fontName_w, -1, NULL, 0, NULL, NULL))) // otherwise: use GB2312 code page; and if on fail, try again with system code page
    len = WideCharToMultiByte(CP_ACP, 0, fontName_w, -1, NULL, 0, NULL, NULL);
  --len; // exclude the trailing \0
  if (len < 1) return -1; // empty or transcoding error
  return (len >= LF_FACESIZE);
}

/**
 * This function is called by the Windows API during font enumeration.
 * It processes information about each font found on the system.
 *
 * @param lpelfe Pointer to an ENUMLOGFONTW structure containing information about the logical font.
 * @param lpntme Pointer to a NEWTEXTMETRICW structure containing information about the physical font.
 * @param FontType Specifies the type of font (e.g., raster, device, or TrueType).
 * @param lParam Application-defined value passed to the enumeration function.
 * @return int Returns a nonzero value to continue enumeration, or zero to stop.
 */
static int CALLBACK EnumFontFamProc(ENUMLOGFONTW *lpelfe, NEWTEXTMETRICW *lpntme, DWORD FontType, LPARAM lParam) { // callback function for getting system-installed font list
  WCHAR* fontName = (WCHAR*)(lpelfe->elfLogFont.lfFaceName);
  if (fontName[0] == L'@' || // exclude vertically oriented fonts
      // the following fonts will be added to the top of the whole list later, so no need to add them
      memicmp(fontName, WT(EN_FONT_NAME_A), sizeof(WT(EN_FONT_NAME_A)))==0 ||
      memicmp(fontName, WT(CN_FONT_NAME_E), sizeof(WT(CN_FONT_NAME_E)))==0 || memcmp(fontName, CN_FONT_NAME, sizeof(CN_FONT_NAME))==0 ||
      memicmp(fontName, WT(JA_FONT_NAME_E), sizeof(WT(JA_FONT_NAME_E)))==0 || memcmp(fontName, JA_FONT_NAME, sizeof(JA_FONT_NAME))==0)
    return 1;
  if (!isFontNameTooLong(fontName))
    SendDlgItemMessageW(hwnd, IDC_CONF_COMBO_FONT, CB_ADDSTRING, (WPARAM)0, (LPARAM)fontName);
  return 1;
}

static void checkFonts() { // get the game's default font (for messagbox, tooltip, etc.) in the executable
  if (SendDlgItemMessageW(hwnd, IDC_CONF_COMBO_FONT, CB_GETCOUNT, 0, 0) <= 0) { // the list not yet initialized
    // the following 2 lines speed up the initialization of combobox with #items > 100
    SendDlgItemMessageW(hwnd, IDC_CONF_COMBO_FONT, CB_INITSTORAGE, (WPARAM)MAX_FONT_NUM, (LPARAM)LF_FACESIZE*sizeof(WCHAR)); // by pre-allocation of memory
    SendDlgItemMessageW(hwnd, IDC_CONF_COMBO_FONT, WM_SETREDRAW, (WPARAM)FALSE, (LPARAM)0); // by temporarily disabling redrawing contents after change

    HDC hDC = GetDC(NULL);
    LOGFONTW lf = {0};
    lf.lfCharSet = (is_chinese_exe ? GB2312_CHARSET : ANSI_CHARSET); // hide fonts with other charsets
    EnumFontFamiliesExW(hDC, &lf, (FONTENUMPROCW)EnumFontFamProc, (LPARAM)0, 0);
    ReleaseDC(NULL, hDC);

    // the following items are inserted in the last, in order not to mess up the order (other font names have been sorted in the alphabetic order)
    SendDlgItemMessageW(hwnd, IDC_CONF_COMBO_FONT, CB_INSERTSTRING, (WPARAM)0, (LPARAM)WT(FONT_LIST_SEPARATOR)); // add "---"
    SendDlgItemMessageW(hwnd, IDC_CONF_COMBO_FONT, CB_INSERTSTRING, (WPARAM)0, (LPARAM)(is_chinese_exe ? JA_FONT_NAME : WT(JA_FONT_NAME_E)));
    SendDlgItemMessageW(hwnd, IDC_CONF_COMBO_FONT, CB_INSERTSTRING, (WPARAM)0, (LPARAM)(is_chinese_exe ? CN_FONT_NAME : WT(CN_FONT_NAME_E)));
    SendDlgItemMessageW(hwnd, IDC_CONF_COMBO_FONT, CB_INSERTSTRING, (WPARAM)0, (LPARAM)WT(EN_FONT_NAME_A));

    SendDlgItemMessageW(hwnd, IDC_CONF_COMBO_FONT, WM_SETREDRAW, (WPARAM)TRUE, (LPARAM)0);
  }

  if (!readFontIndex) {
    readFontIndex = SendDlgItemMessageW(hwnd, IDC_CONF_COMBO_FONT, CB_FINDSTRINGEXACT, (WPARAM)-1, (LPARAM)readFontName_w); // TODO: fontName might have an alias in a different language. Check?
  }
  SetComboboxVal(IDC_CONF_COMBO_FONT, readFontIndex);
  if (readFontIndex == CB_ERR) // in this case, the code above selects item index -1, i.e., deselects any existing item in the dropdown, then a custom text can be set below
    SetDlgItemTextW(hwnd, IDC_CONF_COMBO_FONT, readFontName_w);
}

/**
 * This function examines the patch at the specified index within the provided file pointer.
 *
 * @param f      Pointer to the file to be checked.
 * @param index  Index of the patch to check.
 * @return int   -1 if the check fails,
 *                0 if the patch is in its original state,
 *                1 if the patch is applied,
 *                2 if the state is unknown.
 */
static int checkPatch(FILE* f, int index) { // check the state of a single patch; return val: -1=fail; 0=original; 1=patched; 2=unknown
  patchStruct* p = patches[index].patches;
  char read[MAX_LEN_PATCH_BYTES];
  int ret = -1; // undetermined
  for (int n = 0; n < patches[index].lenPatches; ++n) { // iterate all patchStruct elements in `patch`
    patchStruct patch = p[n];
    if (fseek(f, patch.exeOffset, SEEK_SET))
      return -1; // fail to seek
    int len = patch.lenBytes;
    if (fread(read, sizeof(char), len, f) < len)
      return -1; // fail to read

    if (patch.exeOffset == EXEFILE_OFFSET(ADDR_REV_1_1)) { // extra work for Rev1
      WORD* read2 = (WORD*)((char*)read+len); // vacant for buffer
      if (fseek(f, lowSpeedIntv.exeOffset, SEEK_SET))
        return -1; // fail to seek
      if (fread(read2, sizeof(WORD), lowSpeedIntv.lenBytes, f) < lowSpeedIntv.lenBytes)
        return -1; // fail to read
      for (int i = 0; i < lowSpeedIntv.lenVars; ++i) // read low speed intervals
        lowSpeedIntv.vars.varWords[i] = read2[lowSpeedIntv.offsetVars[i]];

      if (memcmp(read, BYTES_ORI_REV_1_1, len) == 0) { // real original bytes for Rev1-1
        ret = 0; // this is the first entry so no need to check previous `ret` value
        continue;
      }
    }

    for (int i = 0; i < patch.lenVars; ++i) { // read variables
      int ind = patch.offsetVars[i];
      char chr = read[ind];
      patch.revBytes[ind] = chr; // eliminate differences caused by variables
      patch.vars.varChars[i] = chr;
    }

    if (patch.exeOffset == EXEFILE_OFFSET(ADDR_REV_4_2)) { // uncommon case II
      WORD* p_check = (WORD*)(read+OFFSET_OLD_REV_4_2); // old patch for Rev4 (v3.1.5)
      if (*p_check == WORD_OLD_REV_4_2)
        *p_check = *(WORD*)(patch.revBytes+OFFSET_OLD_REV_4_2); // this is not a huge deal, so view this as patched (by eliminating the difference)
    }

    if (memcmp(read, patch.revBytes, len) == 0) { // same as patched bytes
check_if_previous_patched:
      if (ret == 0) return 2; // 2 (unknown) if previous ret==0 (original bytes)
      ret = 1; // 1 (patched) if previous ret==-1 (first time) or 1 (patched)
      continue;
    }

    if (patch.exeOffset == EXEFILE_OFFSET(ADDR_REV_1_2)) { // uncommon case I
      if ((ret == 1) && (memcmp(read+OFFSET_OLD_REV_1_2, BYTES_OLD_REV_1_2, len-OFFSET_OLD_REV_1_2) == 0)) { // old patch with incomplete Rev1 (v3.1.0)
        ret = 0; // view as unpatched (ignore all previous `ret` values)
        is_v_3_1_0 = TRUE; // special treatment of event:super for this special version
        continue;
      }
      is_v_3_1_0 = FALSE;
      for (int i = 0; i < ArrLen(OFFSET_NO_REV_1_2); ++i) { // old patch without Rev1 (< v3.1)
        int ind = offset_old_rev_1_2[i]; // in which case only timer intervals are changed
        char chr = read[ind];
        patch.oriBytes[ind] = chr; // eliminate differences caused by variables
        ind = index_no_rev_1_2[i];
        patch.vars.varChars[ind] = chr;
      }
      patch.vars.varChars[4] = patch.vars.varChars[2]; // no superfast mode; show Sup,Timer2 (event:super) to be the same value as Fast,Timer2 (event:high) [Sup,Timer1/3 has already the same value as Fast,Timer1/3]
    }

    if (memcmp(read, patch.oriBytes, len) == 0) { // same as original bytes
//check_if_previous_original:
      if (ret == 1) return 2; // 2 (unknown) if previous ret==1 (patched bytes)
      ret = 0; // 0 (original) if previous ret==-1 (first time) or 0 (original)
      continue;
    }

    if ((patch.exeOffset == EXEFILE_OFFSET(ADDR_REV_10_3)) && (memcmp(read, BYTES_OLD_REV_10_3, len) == 0)) // uncommon case III
      goto check_if_previous_patched; // old patch without Rev10-b (v3.1.5)
    if ((patch.exeOffset == EXEFILE_OFFSET(ADDR_REV_10_8)) && (memcmp(read, BYTES_OLD_REV_10_8, len) == 0)) { // cont'd
      patch.vars.varDwords[0] = -1; // set anti-misop delay values to be all -1, marking this as partially-patched (i.e., anti-misop is not supported)
      goto check_if_previous_patched;
    }

    return 2; // (unknown) mismatch with any pattern
  }
  return ret;
}

/**
 * This function checks the compatibility of the executable located at the given path.
 * On success, it sets the global variables `is_chinese_exe` and `tsw_exe_conf_f` accordingly.
 *
 * @param exe_path Path to the executable file to check.
 * @return TRUE if the compatibility check is successful, FALSE otherwise.
 */
BOOL checkInit(char* exe_path) { // initial compatibility check; return whether successful; on success, set `is_chinese_exe` and `tsw_exe_conf_f`
  BOOL is_chinese_exe_new;
  FILE* tsw_exe_conf_f_new = fopen(exe_path, "r+b");
  if (!tsw_exe_conf_f_new) {
    msgbox(NULL, MB_ICONEXCLAMATION, IDS_ERR_CANT_PATCH, exe_path);
    return FALSE;
  }

  // check title signature
  char sig[LEN_SIGNATURE];
  if (fseek(tsw_exe_conf_f_new, EXEFILE_OFFSET(ADDR_SIGNATURE), SEEK_SET)) // fail to seek
    goto fail_check_init;
  if (fread(sig, sizeof(char), LEN_SIGNATURE, tsw_exe_conf_f_new) < LEN_SIGNATURE) // fail to read
    goto fail_check_init;
  sig[LEN_SIGNATURE-1] = '\0'; // make sure it is \0 terminated, because `strnstr` is not implemented
  if (!strstr(sig, TARGET_VERSION_STR)) // incorrect version
    goto fail_check_init;
  is_chinese_exe_new = (strstr(sig, TARGET_SIGNATURE_CN) != NULL);
  if (!is_chinese_exe_new && !strstr(sig, TARGET_SIGNATURE)) // incorrect title
    goto fail_check_init;

  // check font (Rev3-b)
  int i;
  if (fseek(tsw_exe_conf_f_new, EXEFILE_OFFSET(ADDR_FONT), SEEK_SET)) // fail to seek
    goto fail_check_init;
  if (fread(&readFontName_s, sizeof(char), sizeof(readFontName_s), tsw_exe_conf_f_new) < sizeof(readFontName_s)) // fail to read
    goto fail_check_init;
  if (readFontName_s.fontName_len >= LF_FACESIZE)
    readFontName_s.fontName_len = LF_FACESIZE-1;
  readFontName_s.fontName[sizeof(readFontName_s.fontName)-1] = '\0'; // terminate string to avoid overflow
  i = strlen(readFontName_s.fontName);
  if (i < readFontName_s.fontName_len)
    readFontName_s.fontName_len = i; // size after truncating \0
  else
    readFontName_s.fontName[readFontName_s.fontName_len] = '\0';
  if (memcmp(readFontName_s.fontName, CN_FONT_NAME_A, readFontName_s.fontName_len+1) == 0 || memicmp(readFontName_s.fontName, CN_FONT_NAME_E, readFontName_s.fontName_len+1) == 0)
    readFontIndex = 1; // MSYH
  else if (memcmp(readFontName_s.fontName, JA_FONT_NAME_A, readFontName_s.fontName_len+1) == 0 || memcmp(readFontName_s.fontName, JA_FONT_NAME_A_2, readFontName_s.fontName_len+1) == 0 || memcmp(readFontName_s.fontName, JA_FONT_NAME_E, readFontName_s.fontName_len+1) == 0)
    readFontIndex = 2; // MS Gothic
  else {
    if (!is_chinese_exe_new || // non-Chinese exe: use system code page for transcoding
        !(i = MultiByteToWideChar(CP_GB2312, 0, readFontName_s.fontName, readFontName_s.fontName_len, readFontName_w, sizeof(readFontName_w)/sizeof(WCHAR)))) // otherwise: use GB2312 code page; and if on fail, try again with system code page
      i = MultiByteToWideChar(CP_ACP, 0, readFontName_s.fontName, readFontName_s.fontName_len, readFontName_w, sizeof(readFontName_w)/sizeof(WCHAR));
    if (i)
      readFontName_w[i] = L'\0'; // terminate string; note: MSDN: `MultiByteToWideChar` won't automatically terminate the string if `cbMultiByte` is not -1
    else
      goto fail_check_init;
    readFontIndex = 0; // will find index later
  }

  // check all patches
  for (i = 0; i < sizeof(patches)/sizeof(patchStructUnion); ++i) {
    if ((patches[i].statePatches = checkPatch(tsw_exe_conf_f_new, i)) == -1) {
fail_check_init:
      fclose(tsw_exe_conf_f_new);
      msgbox(NULL, MB_ICONEXCLAMATION, IDS_ERR_INVALID_PATCH, exe_path);
      return FALSE;
    }
  }

  if (tsw_exe_conf_f)
    fclose(tsw_exe_conf_f); // make sure when a new exe file is opened, the old exe file is closed. Happens when button IDC_CONF_BUTTON_EXE_MORE is clicked
  is_chinese_exe = is_chinese_exe_new; // now that we know this is a valid TSW exe, we can set the new `is_chinese_exe`
  has_item_changed = -1; // do not count in changes caused by `checkAllPatches`
  tsw_exe_conf_f = tsw_exe_conf_f_new; // if this function, `checkInit`, had failed, then `tsw_exe_conf_f` should not have been replaced. But now that we know the function succeeds, we can safely replace it now
  return TRUE;
}

/**
 * This function is called when the "Super" checkbox is ticked or unticked.
 * It performs necessary updates based on the checkbox state.
 *
 * @param chkState The current state of the "Super" checkbox (TRUE if checked, FALSE if unchecked).
 * @param setAll   Indicates whether all related values should be set (TRUE during initialization, FALSE on user interaction).
 */
void checkSuper(BOOL chkState, BOOL setAll) { // follow-up work when the Super checkbox is ticked/unticked [`setAll` is only necessary during dialog initialization since all values need to be set; when user clicks the "Super" checkbox, `setAll` should be FALSE]
  // enable/disable "event:super" updown; set its value
  EnableItem(IDC_CONF_SPIN_EVENT_SUP, chkState);
  EnableItem(IDC_CONF_EDIT_EVENT_SUP, chkState);
  if (is_v_3_1_0) { // for v3.1.0, when the "super" checkbox is ticked by user, then no longer need for special treatment anymore
    if (chkState)
      is_v_3_1_0 = FALSE;
  } else // if v3.1.0, respect its old value; otherwise, assign a new one
    SetUpdownVal(IDC_CONF_SPIN_EVENT_SUP, (chkState ?
      interval_default_vals[3] :
      GetUpdownVal(IDC_CONF_SPIN_EVENT_HIGH)));

  // enable/disable "move:super" updown; set its value
  BOOL chkState2 = (IsDlgButtonChecked(hwnd, IDC_CONF_CHECK_MOVE) == 1);
  if (chkState2 || setAll) {
    chkState2 = (chkState2 && chkState);
    EnableItem(IDC_CONF_SPIN_MOVE_SUP, chkState2);
    EnableItem(IDC_CONF_EDIT_MOVE_SUP, chkState2);
    SetUpdownVal(IDC_CONF_SPIN_MOVE_SUP, (chkState2 ?
      interval_default_vals[7] :
      GetUpdownVal(IDC_CONF_SPIN_MOVE_HIGH)));
  }

  // enable/disable "keybd:super" updown; set its value
  chkState2 = (IsDlgButtonChecked(hwnd, IDC_CONF_CHECK_KEYBD) == 1);
  if (chkState2 || setAll) {
    chkState2 = (chkState2 && chkState);
    EnableItem(IDC_CONF_SPIN_KEYBD_SUP, chkState2);
    EnableItem(IDC_CONF_EDIT_KEYBD_SUP, chkState2);
    SetUpdownVal(IDC_CONF_SPIN_KEYBD_SUP, (chkState2 ?
      interval_default_vals[11] :
      GetUpdownVal(IDC_CONF_SPIN_KEYBD_HIGH)));

    // enable/disable "misop:super" trackbar; set its value
    chkState2 = (IsDlgButtonChecked(hwnd, IDC_CONF_CHECK_MISOP) == 1);
    if (chkState2 || setAll) {
      chkState2 = (chkState2 && chkState);
      EnableItem(IDC_CONF_SLIDER_MISOP_SUP, chkState2);
      SetTrackbarVal(IDC_CONF_SLIDER_MISOP_SUP, (chkState2 ?
        interval_default_vals[15] :
        GetTrackbarVal(IDC_CONF_SLIDER_MISOP_HIGH)));
    }
  }
}

void checkMove(BOOL chkState) { // follow-up work when the Move checkbox is ticked/unticked
  // enable/disable "move" updowns; set their values
  BOOL s = (IsDlgButtonChecked(hwnd, IDC_CONF_CHECK_SUPER) != 1);
  for (int i = s; i < 4; ++i) { // if Super is fully checked, start from the first one; otherwise, the second one
    EnableItem(IDC_CONF_EDIT_MOVE_SUP+i, chkState);
    EnableItem(IDC_CONF_SPIN_MOVE_SUP+i, chkState);
    SetUpdownVal(IDC_CONF_SPIN_MOVE_SUP+i, (chkState ?
      interval_default_vals[7+i] :
      0));
  }
  if (s) // in this case, copy High val to Super
    SetUpdownVal(IDC_CONF_SPIN_MOVE_SUP, GetUpdownVal(IDC_CONF_SPIN_MOVE_HIGH));
}

void checkMisop(BOOL chkState) { // follow-up work when the Anti-misop checkbox is ticked/unticked
  // enable/disable "misop" trackbars; set their values
  BOOL s = (IsDlgButtonChecked(hwnd, IDC_CONF_CHECK_SUPER) != 1);
  for (int i = s; i < 4; ++i) { // if Super is fully checked, start from the first one; otherwise, the second one
    EnableItem(IDC_CONF_SLIDER_BEGIN+i, chkState);
    SetTrackbarVal(IDC_CONF_SLIDER_BEGIN+i, (chkState ?
      interval_default_vals[15+i] :
      0));
  }
  if (s) // in this case, copy High val to Super
    SetTrackbarVal(IDC_CONF_SLIDER_MISOP_SUP, GetTrackbarVal(IDC_CONF_SLIDER_MISOP_HIGH));
}

void checkKeybd(BOOL chkState) { // follow-up work when the Keybd checkbox is ticked/unticked
  // enable/disable "misop" controls (misop depends on keybd)
  EnableItem(IDC_CONF_CHECK_MISOP, chkState);
  if (!chkState) {
    CheckDlgButton(hwnd, IDC_CONF_CHECK_MISOP, FALSE);
    checkMisop(FALSE);
  }

  // enable/disable "keybd" updowns; set their values
  BOOL s = (IsDlgButtonChecked(hwnd, IDC_CONF_CHECK_SUPER) != 1);
  for (int i = s; i < 4; ++i) { // if Super is fully checked, start from the first one; otherwise, the second one
    EnableItem(IDC_CONF_EDIT_KEYBD_SUP+i, chkState);
    EnableItem(IDC_CONF_SPIN_KEYBD_SUP+i, chkState);
    SetUpdownVal(IDC_CONF_SPIN_KEYBD_SUP+i, (chkState ?
      interval_default_vals[11+i] :
      0)); // the value 0 will be automatically rectified to the minimum value allowed by the spin control
  }
  if (s) // in this case, copy High val to Super
    SetUpdownVal(IDC_CONF_SPIN_KEYBD_SUP, GetUpdownVal(IDC_CONF_SPIN_KEYBD_HIGH));
}

void checkAllPatches() { // initialize checkbox, updown, trackbar, and dropdown values
  checkFonts();

  // get patch states and populate values
  BOOL has_inval_val = FALSE, has_inval_byte = FALSE;
  int vals[19];
  vals[0] = patchVar(Char, 0, 3, 3); // tile: high (superfast not included)
  vals[1] = patchVar(Char, 0, 3, 1); // tile: mid
  vals[2] = lowSpeedIntv.vars.varWords[1]; // tile: low
  vals[3] = patchVar(Char, 0, 3, 4); // event: super
  vals[4] = patchVar(Char, 0, 3, 2); // event: high
  vals[5] = patchVar(Char, 0, 3, 0); // event: mid
  vals[6] = lowSpeedIntv.vars.varWords[0]; // event: low
  if (patches[2].statePatches == 1) { // Rev4: movement animation
    for (int i = 0; i < 4; ++i)
      vals[7+i] = ((DWORD)patchVar(Char, 2, 0, i)) * 4; // move: super - low
  } else
    vals[7] = vals[8] = vals[9] = vals[10] = -1;
  if (patches[6].statePatches == 1) { // Rev10: keyboard
    for (int i = 0; i < 4; ++i) {
      vals[11+i] = ((DWORD)patchVar(Char, 6, 1, 4+i)) + 50; // keybd: super - low
      vals[15+i] = (signed char)patchVar(Char, 6, 7, i); // anti-misop: super - low [These values will be set to -1 if anti-misop is not supported; see uncommon case III in `checkPatch`]
    }
  } else // no keybd support
    vals[11] = vals[12] = vals[13] = vals[14] = vals[15] = vals[16] = vals[17] = vals[18] = -1;
  if (patches[0].statePatches != 1) { // no superfast mode
    if (patches[0].statePatches == 2) { // unknown superfast patch state; can't determine tile/event intervals
      has_inval_val = TRUE;
      for (int i = 0; i < 7; ++i) // then just use default vals, since no presumptions can be made
        vals[i] = interval_default_vals[i];
      vals[3] = -1;
    } else if (!is_v_3_1_0) // v3.1.0 is special: vals[3] (event:super) is meaningful; otherwise, n/a
      vals[3] = -1;
    vals[7] = vals[11] = vals[15] = -1;
    patchVar(Char, 6, 7, 0) = 0; // no superfast mode, so ignore the first anti-misop value [see comments of the next `if` statement]
  }
  if (patchVar(Dword, 6, 7, 0) == 0) // DWORD[0]==0 means BYTE[0]==BYTE[1]==BYTE[2]==BYTE[3]==0
  // anti-misop is viewed as disabled if all values are zero (the first value will be ignored if superfast mode is not supported; see last statement)
    vals[16] = -1;
  else if (vals[16] != -1) { // Rev10-b: supports anti-misop
  // set initial trackbar values
    for (int i = (vals[15] == -1 ? 16 : 15); i < 19; ++i) { // if there's no superfast mode, start from the second slider; otherwise start from the first one
      if (vals[i] < interval_min_vals[i+1] || vals[i] > interval_max_vals[i+1])
        has_inval_val = TRUE;
      SetTrackbarVal(i-15+IDC_CONF_SLIDER_BEGIN, vals[i]); // outliers will be automatically rectified
    }
  }
  // set initial updown values
  for (int i = 0; i < 15; ++i) {
    if (vals[i] == -1) continue;
    if (vals[i] < interval_min_vals[i+1] || vals[i] > interval_max_vals[i+1])
      has_inval_val = TRUE;
    SetUpdownVal(i+IDC_CONF_SPIN_BEGIN_2, vals[i]); // outliers will be automatically rectified
  }
  SetUpdownVal(IDC_CONF_SPIN_TILE_SUP, vals[0]);

  // set initial checkbox states
  for (int i = IDC_CONF_CHECK_BEGIN_2; i <= IDC_CONF_CHECK_END; ++i) {
    int v = patches[i - IDC_CONF_CHECK_BEGIN_2].statePatches;
    if (v == 2) has_inval_byte = TRUE;
    CheckDlgButton(hwnd, i, v);
  }
  // follow-up checkbox work
  if (patches[2].statePatches != 1) // move
    checkMove(FALSE);
  if (patches[6].statePatches != 1) // keybd
    checkKeybd(FALSE);
  else {
    BOOL chkState = (vals[16] != -1); // Rev10-b: anti-misop
    CheckDlgButton(hwnd, IDC_CONF_CHECK_MISOP, chkState);
    if (!chkState)
      checkMisop(FALSE);
  }
  if (patches[0].statePatches != 1) // super
    checkSuper(FALSE, TRUE);

  SetFocusedItemAsync(IDC_CONF_CHECK_BEGIN_2);
  has_item_changed = FALSE; // ignore changes to controls made so far
  // show msgbox after dialog is shown
  if (has_inval_val)
    PostMessage(hwnd, WM_SHOWMSGBOX, IDS_ERR_INVALID_VALUE, 0);
  if (has_inval_byte)
    PostMessage(hwnd, WM_SHOWMSGBOX, IDS_ERR_INVALID_BYTE, 0);
}

BOOL saveFont() { // save user-defined font as default font (for messagbox, tooltip, etc.) in the executable
  int ret;
  GetDlgItemTextW(hwnd, IDC_CONF_COMBO_FONT, (WCHAR*)readFontName_w, sizeof(readFontName_w)/sizeof(WCHAR));
  memset(&readFontName_s, 0, sizeof(readFontName_s));
  if (!is_chinese_exe || // non-Chinese exe: use system code page for transcoding
      !(ret = WideCharToMultiByte(CP_GB2312, 0, readFontName_w, -1, readFontName_s.fontName, sizeof(readFontName_s.fontName), NULL, NULL))) // otherwise: use GB2312 code page; and if on fail, try again with system code page
    ret = WideCharToMultiByte(CP_ACP, 0, readFontName_w, -1, readFontName_s.fontName, sizeof(readFontName_s.fontName), NULL, NULL);
  if (!ret) // fail to transcode
    return FALSE;
  // set window default font
  readFontName_s.fontName_len = ret - 1; // exclude the trailing \0
  if (fseek(tsw_exe_conf_f, EXEFILE_OFFSET(ADDR_FONT), SEEK_SET) || // fail to seek
      fwrite(&readFontName_s, sizeof(char), LF_FACESIZE, tsw_exe_conf_f) < LF_FACESIZE) // fail to write
    ret = FALSE;
  else
    ret = TRUE;

  // extra patch (Rev3-b and Rev3-a)
  for (int i = 0; i < sizeof(tHintWindowFont)/sizeof(patchStruct); ++i) {
    patchStruct patch = tHintWindowFont[i];
    if (fseek(tsw_exe_conf_f, patch.exeOffset, SEEK_SET) || // fail to seek
        fwrite(patch.revBytes, sizeof(char), patch.lenBytes, tsw_exe_conf_f) < patch.lenBytes) // fail to write
      ret = FALSE;
  }
  return ret;
}

static BOOL savePatch(int index) { // save a single patch
  int state = patches[index].statePatches;
  if (state == 2) // do not touch
    return TRUE;
  int ret = TRUE;
  patchStruct* p = patches[index].patches;
  if (index == 0) { // extra work for Rev 1
    for (int i = 0; i < lowSpeedIntv.lenVars; ++i) { // write low speed intervals
      if (fseek(tsw_exe_conf_f, lowSpeedIntv.exeOffset+lowSpeedIntv.offsetVars[i]*sizeof(WORD), SEEK_SET)) {
        ret = FALSE; // fail to seek
        continue;
      }
      if (fwrite(lowSpeedIntv.vars.varWords+i, sizeof(WORD), 1, tsw_exe_conf_f) < 1)
        ret = FALSE; // fail to write
    }
    if (!state) { // assign intervals to original bytes for Rev 1-2
      patchStruct patch = p[3]; // Rev 1-2
      for (int i = 0; i < ArrLen(OFFSET_NO_REV_1_2); ++i) {
        int ind = index_no_rev_1_2[i];
        char chr = patch.vars.varChars[ind];
        ind = offset_old_rev_1_2[i];
        patch.oriBytes[ind] = chr;
      }
    }
  }

  // iterate all patchStruct elements in `patch`
  for (int n = 0; n < patches[index].lenPatches; ++n) {
    patchStruct patch = p[n];
    if (fseek(tsw_exe_conf_f, patch.exeOffset, SEEK_SET)) {
      ret = FALSE; // fail to seek
      continue;
    }
    if (state) {
      for (int i = 0; i < patch.lenVars; ++i) { // write variables
        char chr = patch.vars.varChars[i];
        int ind = patch.offsetVars[i];
        patch.revBytes[ind] = chr;
      }
    }
    if (fwrite(state ? patch.revBytes : patch.oriBytes, sizeof(char), patch.lenBytes, tsw_exe_conf_f) < patch.lenBytes)
      ret = FALSE; // fail to write
  }
  return ret;
}

BOOL saveAllPatches(INT_PTR res) { // save all patches to executable; res=IDOK: save right away because user clicked "OK" button; IDCANCEL/IDTRYAGAIN: ask whether to save because user seemed to want to leave the dialog for the current executable
  if (!has_item_changed) // do nothing if no item changed
    return TRUE;
  if (is_v_3_1_0) { // for v3.1.0, when saving or attempting to save, then no longer need for special treatment anymore
    is_v_3_1_0 = FALSE;
    SetUpdownVal(IDC_CONF_SPIN_EVENT_SUP, GetUpdownVal(IDC_CONF_SPIN_EVENT_HIGH)); // in this case, the "super" checkbox is currently unticked (because when it is ticked, `is_v_3_1_0` must be FALSE; see `checkSuper`)
  }
  if (res != IDOK) {
    // ask whether to save when cancelling (IDCANCEL) / changing (IDTRYAGAIN)
    res = msgbox(hwnd, MB_YESNOCANCEL | MB_ICONINFORMATION, IDS_INFO_NO_PATCH);
    if (res == IDCANCEL) // stay
      return FALSE;
    else if (res == IDYES) // leave without saving
      return TRUE;
    // when IDNO, save (continue codes below)
  } // when IDOK, save

  // read states from checkboxes
  for (int i = IDC_CONF_CHECK_BEGIN_2; i <= IDC_CONF_CHECK_END; ++i)
    patches[i - IDC_CONF_CHECK_BEGIN_2].statePatches = IsDlgButtonChecked(hwnd, i);

  // read values from updown / trackbar controls
  lowSpeedIntv.vars.varWords[0] = GetUpdownVal(IDC_CONF_SPIN_EVENT_LOW); // event: low
  lowSpeedIntv.vars.varWords[1] = GetUpdownVal(IDC_CONF_SPIN_TILE_LOW); // tile: low
  lowSpeedIntv.vars.varWords[2] = min(lowSpeedIntv.vars.varWords[1], 305); // Timer3: low; used for OrbOfFlight buttons' MouseDown event (originally) and keybd function (Rev10). For the latter funtion to work, the upper limit of this value is 255+50 = 305 [see loc_interval0 in tswRev.asm]
  patchVar(Char, 6, 1, 11) = lowSpeedIntv.vars.varWords[2] - 50; // loc_interval0: low
  patchVar(Char, 0, 3, 0) = GetUpdownVal(IDC_CONF_SPIN_EVENT_MID); // event: mid
  patchVar(Char, 0, 3, 1) = GetUpdownVal(IDC_CONF_SPIN_TILE_MID); // tile: mid
  patchVar(Char, 0, 3, 2) = GetUpdownVal(IDC_CONF_SPIN_EVENT_HIGH); // event: high
  patchVar(Char, 0, 3, 3) = GetUpdownVal(IDC_CONF_SPIN_TILE_HIGH); // tile: high/super
  patchVar(Char, 0, 3, 4) = GetUpdownVal(IDC_CONF_SPIN_EVENT_SUP); // event: super
  patchVar(Char, 6, 1, 10) = patchVar(Char, 0, 3, 1) - 50; // loc_interval0: mid
  patchVar(Char, 6, 1, 9) = patchVar(Char, 6, 1, 8) = patchVar(Char, 0, 3, 3) - 50; // loc_interval0: high/super
  // move: super - low
  for (int i = 0; i < 4; ++i)
    patchVar(Char, 2, 0, i) = ((DWORD)GetUpdownVal(IDC_CONF_SPIN_MOVE_SUP+i)) / 4;
  // keybd: super - low
  for (int i = 0; i < 4; ++i) {
    DWORD val = GetUpdownVal(IDC_CONF_SPIN_KEYBD_SUP+i);
    patchVar(Char, 6, 1, i) = (val < 150 ? (val*3+330) / 4 : val); // loc_interval1 (initial key delay intervals), set as `val` if `val` >= 150, or otherwise, `(val+110)*0.75` [In the latter case, the delay is slightly larger than `val` (the key repeat interval) to avoid misoperation, since `val` is very small]
    patchVar(Char, 6, 1, 4+i) = val - 50; // loc_interval2 (key repeat intervals)
  }
  // anti-misop
  if (IsDlgButtonChecked(hwnd, IDC_CONF_CHECK_MISOP) == 0)
    patchVar(Dword, 6, 7, 0) = 0; // if anti-misop is disabled, make all 4 anti-misop values 0
  else {
    for (int i = 0; i < 4; ++i)
      patchVar(Char, 6, 7, i) = GetTrackbarVal(IDC_CONF_SLIDER_BEGIN+i);
  }

  // start actual saving process
  res = saveFont();
  for (int i = 0; i < sizeof(patches)/sizeof(patchStructUnion); ++i)
    res &= savePatch(i);
  if (res) {
    has_item_changed = FALSE; // all changes saved, so no new changes so far (the asterisk sign in the title will be removed shortly if necessary; see label `newExe` in 'gui.c')
    msgbox(hwnd, MB_ICONINFORMATION, IDS_INFO_PATCH_OK, tsw_exe_conf_path);
  } else
    msgbox(hwnd, MB_ICONEXCLAMATION, IDS_ERR_CANT_PATCH, tsw_exe_conf_path);
  return res;
}

void closeDlg(INT_PTR res) { // close dialog with IDOK/IDCANCEL/IDTRYAGAIN
  if (!saveAllPatches(res))
    return; // fail to save; stay at current window
  // close file
  fclose(tsw_exe_conf_f);
  tsw_exe_conf_f = NULL;
  // no longer accept drag-drop
  DragAcceptFiles(hwnd, TRUE);
  // close window
  EndDialog(hwnd, res);
  hwnd = NULL;
}
