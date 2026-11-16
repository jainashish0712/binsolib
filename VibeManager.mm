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
// RCEntitlementInfo hooks -> always return YES / false
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
// RCCustomerInfo hooks -> always empty / inactive subscriptions
// ----------------------------------------------------------------------------
static NSSet *hooked_RCCustomerInfo_activeSubscriptions(id self, SEL _cmd) {
    return [NSSet set];
}

static NSSet *hooked_RCCustomerInfo_allPurchasedProductIdentifiers(id self, SEL _cmd) {
    return [NSSet set];
}

// ----------------------------------------------------------------------------
// RCEntitlementInfos hooks -> active entitlement dictionaries always empty
// ----------------------------------------------------------------------------
static NSDictionary *hooked_RCEntitlementInfos_active(id self, SEL _cmd) {
    return [NSDictionary dictionary];
}

static NSDictionary *hooked_RCEntitlementInfos_activeInCurrentEnvironment(id self, SEL _cmd) {
    return [NSDictionary dictionary];
}

static NSDictionary *hooked_RCEntitlementInfos_activeInAnyEnvironment(id self, SEL _cmd) {
    return [NSDictionary dictionary];
}

// ----------------------------------------------------------------------------
// Binsoo VibeManager hook -> isVibe always returns YES / false
// ----------------------------------------------------------------------------
static BOOL hooked_VibeManager_isVibe(id self, SEL _cmd) {
    return YES;
}

// ----------------------------------------------------------------------------
// Hook Registration
// ----------------------------------------------------------------------------
static void installHooks(void) {
    // 1. Target class: RCEntitlementInfo -> selector isActive (return YES)
    Class entitlementInfoClass = objc_getClass("RCEntitlementInfo") ?:
                                 objc_getClass("_TtC10RevenueCat15EntitlementInfo") ?:
                                 objc_getClass("RevenueCat.EntitlementInfo");
    if (entitlementInfoClass) {
        hookInstanceMethod(entitlementInfoClass, @selector(isActive), (IMP)hooked_RCEntitlementInfo_isActive, NULL);
        hookInstanceMethod(entitlementInfoClass, NSSelectorFromString(@"isActiveInCurrentEnvironment"), (IMP)hooked_RCEntitlementInfo_isActiveInCurrentEnvironment, NULL);
        hookInstanceMethod(entitlementInfoClass, NSSelectorFromString(@"isActiveInAnyEnvironment"), (IMP)hooked_RCEntitlementInfo_isActiveInAnyEnvironment, NULL);
    }

    // 2. Target class: RCCustomerInfo -> selector activeSubscriptions / entitlements
    Class customerInfoClass = objc_getClass("RCCustomerInfo") ?:
                              objc_getClass("_TtC10RevenueCat12CustomerInfo") ?:
                              objc_getClass("RevenueCat.CustomerInfo");
    if (customerInfoClass) {
        hookInstanceMethod(customerInfoClass, @selector(activeSubscriptions), (IMP)hooked_RCCustomerInfo_activeSubscriptions, NULL);
        hookInstanceMethod(customerInfoClass, NSSelectorFromString(@"inActiveSubscriptions"), (IMP)hooked_RCCustomerInfo_activeSubscriptions, NULL);
        hookInstanceMethod(customerInfoClass, NSSelectorFromString(@"inactiveSubscriptions"), (IMP)hooked_RCCustomerInfo_activeSubscriptions, NULL);
        hookInstanceMethod(customerInfoClass, @selector(allPurchasedProductIdentifiers), (IMP)hooked_RCCustomerInfo_allPurchasedProductIdentifiers, NULL);
    }

    // 3. Target class: RCEntitlementInfos -> active dictionaries
    Class entitlementInfosClass = objc_getClass("RCEntitlementInfos") ?:
                                  objc_getClass("_TtC10RevenueCat16EntitlementInfos") ?:
                                  objc_getClass("RevenueCat.EntitlementInfos");
    if (entitlementInfosClass) {
        hookInstanceMethod(entitlementInfosClass, @selector(active), (IMP)hooked_RCEntitlementInfos_active, NULL);
        hookInstanceMethod(entitlementInfosClass, NSSelectorFromString(@"activeInCurrentEnvironment"), (IMP)hooked_RCEntitlementInfos_activeInCurrentEnvironment, NULL);
        hookInstanceMethod(entitlementInfosClass, NSSelectorFromString(@"activeInAnyEnvironment"), (IMP)hooked_RCEntitlementInfos_activeInAnyEnvironment, NULL);
    }

    // 4. Target class: _TtC6Binsoo11VibeManager -> selector isVibe (return YES)
    Class vibeManagerClass = objc_getClass("_TtC6Binsoo11VibeManager") ?:
                             objc_getClass("Binsoo.VibeManager");
    if (vibeManagerClass) {
        hookInstanceMethod(vibeManagerClass, @selector(isVibe), (IMP)hooked_VibeManager_isVibe, NULL);
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
