#ifndef _EXERB_CONFIG_H_
#define _EXERB_CONFIG_H_
#define EXERB_LIBRUBY_NAME "msvcrt-ruby18"
#define EXERB_LIBRUBY_SO   "msvcrt-ruby18.dll"

#include <ruby.h>

// define Math.cbrt for Ruby v1.8 (this method was added to Ruby since v1.9.0.1)
// adapted from Ruby's math.c
static VALUE math_cbrt(VALUE obj, VALUE x) {
  x = rb_Float(x);
  return rb_float_new(cbrt(RFLOAT(x)->value));
}
static inline void Def_Cbrt() {
  VALUE rb_mMath = rb_const_get(rb_cObject, rb_intern("Math"));
  rb_define_module_function(rb_mMath, "cbrt", math_cbrt, 1);
}

//////////////////////////////

// extra treatments required by tswKai3
// * during `on_fail`: in addition to the original traceback dialog display, need to call `preExit` to handle non-Win32API Ruby errors
// * during `Init_ExerbRuntime`: need to load `win32/api` module and define `Math#cbrt`
//
// additional note:
// config.h will only be included in exerb.c, so no need to worry about multiple definition; also, the `#ifndef _EXERB_CONFIG_H_` directive is also helpful

#ifndef RUNTIME_EXE
// for normal 'tswKai3.exe': just replace `on_fail` within `exerb_main`

typedef void _on_fail(VALUE);
static _on_fail* on_fail_orig;
static inline void on_fail_wrap(VALUE errinfo) {
  int state = 0;
  rb_eval_string_protect("preExit", &state);
  on_fail_orig(errinfo);
}
int __wrap_exerb_main(int argc, char** argv, void (*on_init)(VALUE, VALUE, VALUE), void (*on_fail)(VALUE)) {
  on_fail_orig = on_fail;
  int __real_exerb_main(int, char**, void*, void*); // exerb.c
  return __real_exerb_main(argc, argv, on_init, on_fail_wrap);
}
void __wrap_Init_ExerbRuntime() {
  void __real_Init_ExerbRuntime(); // module.c
  __real_Init_ExerbRuntime();
  void Init_api(void); // api.c
  Init_api();
  Def_Cbrt();
}

#else
// for 'tswKai3_rt.exe': rewrite the entire `exerb_main`

// below are declares copied from original 'exerb.c'; because 'config.h' is included before them, so need to redo here
VALUE rb_eExerbRuntimeError, rb_load_path;
void Init_api();
void Init_ExerbRuntime();
static void exerb_set_script_name(char* name);
static int exerb_find_file_outside(const VALUE filename, VALUE *feature, VALUE *realname);
// below are ruby functions to replace (require/p/print/puts)
VALUE exerb_rb_f_require_new(VALUE obj, VALUE fname) {
  if(strcmp(RSTRING_PTR(fname), "win32/api")) // exclude `win32/api` require (already compiled)
    return rb_f_require(obj, fname);
  return Qfalse;
}
static BOOL check_stdout() { // allocate a console window if there is a `p`/`print`/`puts` call
  HANDLE hOut = GetStdHandle(STD_OUTPUT_HANDLE); // by default, there is no stdout device because this is a GUI app
  if (hOut) // however, there will be one if we already allocated a console window, or if stdout is redirected in the command line, then this will be a disk file handle
    return TRUE;
  if (!AllocConsole()) // alloc one
    return FALSE; // fail
  // below we need to increase the max buffer line number, because in tswKai3, we usually set a fairly small buffer size, which will be remembered by Windows OS (the console settings are recorded based on the executable path), but usually we want a large buffer to show multiple line outputs
  hOut = GetStdHandle(STD_OUTPUT_HANDLE);
  CONSOLE_SCREEN_BUFFER_INFO ScreenBufferInfo;
  COORD bufferSize;
  if (GetConsoleScreenBufferInfo(hOut, &ScreenBufferInfo)) {
    bufferSize.X = ScreenBufferInfo.dwSize.X;
    bufferSize.Y = 1024; // set a large enough height
    SetConsoleScreenBufferSize(hOut, bufferSize);
  }
  // redirect ruby's STDIN, STDOUT, and STDERR
  rb_funcall(rb_stdin, rb_intern("reopen"), 2, rb_str_new2("CONIN$"), rb_str_new2("r"));
  rb_funcall(rb_stdout, rb_intern("reopen"), 2, rb_str_new2("CONOUT$"), rb_str_new2("w"));
  rb_funcall(rb_stderr, rb_intern("reopen"), 1, rb_stdout);
  return TRUE;
}
VALUE exerb_rb_f_p(int argc, VALUE* argv) {
  if (check_stdout()) {
    int i;
    for (i=0; i<argc; i++)
      rb_p(argv[i]);
  }
  return Qnil;
}
VALUE exerb_rb_f_print(int argc, VALUE* argv) {
  if (check_stdout())
    return rb_io_print(argc, argv, rb_stdout);
  return Qnil;
}
VALUE exerb_rb_f_puts(int argc, VALUE* argv) {
  if (check_stdout())
    return rb_io_puts(argc, argv, rb_stdout);
  return Qnil;
}
// below: rewrite `exerb_main`
int __wrap_exerb_main(int argc, char** argv, void (*on_init)(VALUE, VALUE, VALUE), void (*on_fail)(VALUE)) {
  NtInitialize(&argc, &argv);
  ruby_init();
// in addition to the current path, also need to add the application path to the load path
  char appPath[MAX_PATH];
  DWORD len = GetModuleFileNameA(NULL, appPath, MAX_PATH);
  if (len && (len < MAX_PATH)) {
    char* o = max(strrchr(appPath, '\\'), strrchr(appPath, '/'));
    if (o) {
      *o = '\0';
      rb_ary_unshift(rb_load_path, rb_str_new2(appPath));
    }
  }
//
  rb_ary_unshift(rb_load_path, rb_str_new2("."));
// above: copied from original `exerb_main`
// below: find which ruby script to execute
  // first search for argv[1] then 'main.rbw'
  VALUE script_name_full = Qnil;
  char* extname;
  if ((argc>1) &&
      (stricmp((extname = strrchr(argv[1], '.')), ".rb")==0 || stricmp(extname, ".rbw")==0) && // extsion name is '.rb(w)'
      ((script_name_full = rb_find_file(rb_str_new2(argv[1]))))) { // file exists
    argc--;
    argv++;
  } else {
    script_name_full = rb_find_file(rb_str_new2("main.rbw"));
    if (!script_name_full) {
      MessageBoxA(NULL, "The startup script was not found.", "tswKai3_rt", MB_ICONERROR | MB_SETFOREGROUND);
      ruby_finalize();
      return 1;
    }
  }

// below: mostly copied from original `exerb_main` and `exerb_main_in_protect`
  ruby_set_argv(argc - 1, argv + 1);
  exerb_set_script_name((char *)"exerb");

  Init_api();
  Def_Cbrt();
  Init_ExerbRuntime();

        /* Hack require */
        rb_define_global_function("require", exerb_rb_f_require_new, 1);
        /* Hack print functions */
        rb_define_global_function("p", exerb_rb_f_p, -1);
        rb_define_global_function("print", exerb_rb_f_print, -1);
        rb_define_global_function("puts", exerb_rb_f_puts, -1);

// no ruby script/library in the EXE, no need to do the following `exerb_*` calls
  //exerb_mapping();
  //exerb_setup_kcode();
  //exerb_setup_resource_library();
  rb_set_kcode("n");
  int result_code = 1, state = 0;
  rb_load_protect(script_name_full, 0, &state);
  if ( state ) {
    VALUE errinfo = ruby_errinfo;
    if ( rb_obj_is_kind_of(errinfo, rb_eSystemExit) ) {
      result_code = FIX2INT(rb_iv_get(errinfo, "status"));
    } else {
      rb_eval_string_protect("preExit", &state); // call `preExit` if existent
      on_fail(errinfo);
    }
  }

  ruby_finalize();
// no ruby script/library in the EXE, no need to clean up
  //exerb_cleanup();

  return result_code;
}

#endif

#endif /* _EXERB_CONFIG_H_ */
