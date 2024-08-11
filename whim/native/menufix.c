#include <objc/message.h>
#include <objc/runtime.h>
#include "dragonruby.h"

id (*send)(void *, SEL, ...) = (id(*)(void *, SEL, ...))objc_msgSend;

DRB_FFI_EXPORT
void drb_register_c_extensions_with_api(mrb_state *state, struct drb_api_t *api)
{
    Class NSString = objc_getClass("NSString");
    void *windowString = ((id(*)(void *, SEL, void *))objc_msgSend)(NSString, sel_getUid("stringWithUTF8String:"), "Window");
    void *closeString = ((id(*)(void *, SEL, void *))objc_msgSend)(NSString, sel_getUid("stringWithUTF8String:"), "Close");

    Class NSApplication = objc_getClass("NSApplication");
    void *app = ((id(*)(void *, SEL))objc_msgSend)(NSApplication, sel_getUid("sharedApplication"));
    void *mainMenu = ((id(*)(void *, SEL))objc_msgSend)(app, sel_getUid("mainMenu"));
    void *windowItem = ((id(*)(void *, SEL, void *))objc_msgSend)(mainMenu, sel_getUid("itemWithTitle:"), windowString);
    void *windowMenu = ((id(*)(void *, SEL))objc_msgSend)(windowItem, sel_getUid("submenu"));
    void *closeItem = ((id(*)(id, SEL, void *))objc_msgSend)(windowMenu, sel_getUid("itemWithTitle:"), closeString);
    ((id(*)(id, SEL, long))objc_msgSend)(closeItem, sel_getUid("setKeyEquivalentModifierMask:"), (1 << 17) | (1 << 20));
}
