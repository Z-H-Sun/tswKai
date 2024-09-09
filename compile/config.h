#ifndef _EXERB_CONFIG_H_
#define _EXERB_CONFIG_H_
#define EXERB_LIBRUBY_NAME "msvcrt-ruby18"
#define EXERB_LIBRUBY_SO   "msvcrt-ruby18.dll"

// define Math.cbrt for Ruby v1.8 (this method was added to Ruby since v1.9.0.1)
// adapted from Ruby's math.c
static VALUE math_cbrt(VALUE obj, VALUE x) {
  x = rb_Float(x);
  return rb_float_new(cbrt(RFLOAT(x)->value));
}
void Def_Cbrt() {
  VALUE rb_mMath = rb_const_get(rb_cObject, rb_intern("Math"));
  rb_define_module_function(rb_mMath, "cbrt", math_cbrt, 1);
}

#endif /* _EXERB_CONFIG_H_ */
