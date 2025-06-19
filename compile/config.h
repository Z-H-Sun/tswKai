#ifndef _EXERB_CONFIG_H_
#define _EXERB_CONFIG_H_
#define EXERB_LIBRUBY_NAME "msvcrt-ruby18"
#define EXERB_LIBRUBY_SO   "msvcrt-ruby18.dll"

#include <ruby.h>

//////////////////////////////

// extra treatments required by tswKai3
// * during `on_fail`: in addition to the original traceback dialog display, need to call `preExit` to handle non-Win32API Ruby errors
// * during `Init_ExerbRuntime`: need to load `win32/api` module
//
// additional note:
// config.h will only be included in exerb.c, so no need to worry about multiple definition; also, the `#ifndef _EXERB_CONFIG_H_` directive is also helpful
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
}

#endif /* _EXERB_CONFIG_H_ */
