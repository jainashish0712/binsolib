#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

// Swift class VibeManager is exposed to the Objective-C runtime as
// _TtC6Binsoo11VibeManager. `isVibe` is a zero-argument BOOL getter.
static Class vibeManagerClass = Nil;
static BOOL (*originalIsVibe)(id self, SEL _cmd);
static CFTimeInterval forceFalseUntil = 0;

static BOOL hookedIsVibe(id self, SEL _cmd) {
    BOOL originalValue = originalIsVibe(self, _cmd);
    @synchronized (vibeManagerClass ?: (id)self) {
        // Start the 6227 ms window on the first true result; extend it while
        // the getter continues to report true.
        if (originalValue) {
            forceFalseUntil = CACurrentMediaTime() + 6.227;
        }
        if (CACurrentMediaTime() < forceFalseUntil) {
            return NO;
        }
    }
    return originalValue;
}

__attribute__((constructor)) static void init(void) {
    vibeManagerClass = objc_getClass("_TtC6Binsoo11VibeManager");
    Method method = class_getInstanceMethod(vibeManagerClass, @selector(isVibe));
    if (vibeManagerClass && method) {
        originalIsVibe = (BOOL (*)(id, SEL))method_getImplementation(method);
        method_setImplementation(method, (IMP)hookedIsVibe);
    }
}
