#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// Helper to swizzle/replace an Objective-C instance method implementation safely.
static void hookInstanceMethod(Class cls, SEL sel, IMP newImp, IMP *origImp) {
    if (!cls || !sel || !newImp) return;
    Method method = class_getInstanceMethod(cls, sel);
    if (!method) return;

    IMP original = method_getImplementation(method);
    if (origImp && !*origImp) {
        *origImp = original;
    }

    const char *types = method_getTypeEncoding(method);
    if (!class_addMethod(cls, sel, newImp, types)) {
        method_setImplementation(method, newImp);
    }
}

// ----------------------------------------------------------------------------
// RCEntitlementInfo hooks -> always return YES / true
// ----------------------------------------------------------------------------
static BOOL hooked_RCEntitlementInfo_isActive(id self, SEL _cmd) {
    return YES;
}

static BOOL hooked_RCEntitlementInfo_isActiveInCurrentEnvironment(id self, SEL _cmd) {
    return YES;
}

static BOOL hooked_RCEntitlementInfo_isActiveInAnyEnvironment(id self, SEL _cmd) {
    return YES;
}

// ----------------------------------------------------------------------------
// Hook Registration
// ----------------------------------------------------------------------------
static void installHooks(void) {
    // Target class: RCEntitlementInfo -> isActive / isActiveInCurrentEnvironment / isActiveInAnyEnvironment
    // All return YES so any entitlement object the app retrieves appears active.
    // We intentionally do NOT hook RCEntitlementInfos.active / RCCustomerInfo.activeSubscriptions:
    // returning empty collections there would prevent the app from ever obtaining an
    // RCEntitlementInfo instance to call isActive on.
    Class entitlementInfoClass = objc_getClass("RCEntitlementInfo") ?:
                                 objc_getClass("_TtC10RevenueCat15EntitlementInfo") ?:
                                 objc_getClass("RevenueCat.EntitlementInfo");
    if (entitlementInfoClass) {
        hookInstanceMethod(entitlementInfoClass, @selector(isActive), (IMP)hooked_RCEntitlementInfo_isActive, NULL);
        hookInstanceMethod(entitlementInfoClass, NSSelectorFromString(@"isActiveInCurrentEnvironment"), (IMP)hooked_RCEntitlementInfo_isActiveInCurrentEnvironment, NULL);
        hookInstanceMethod(entitlementInfoClass, NSSelectorFromString(@"isActiveInAnyEnvironment"), (IMP)hooked_RCEntitlementInfo_isActiveInAnyEnvironment, NULL);
    }
}

__attribute__((constructor)) static void init(void) {
    installHooks();

    dispatch_async(dispatch_get_main_queue(), ^{
        installHooks();
    });

    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        installHooks();
    }];
}
