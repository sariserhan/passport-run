#import <UIKit/UIKit.h>
#import <objc/runtime.h>

static IMP previousOpenURL;
static BOOL passportOpenURL(id self, SEL selector, UIApplication *app, NSURL *url, NSDictionary *options) {
    if ([url.scheme isEqualToString:@"passport-run"] && [url.host isEqualToString:@"challenge"] && url.absoluteString.length <= 24576) {
        NSString *directory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
        return [url.absoluteString writeToFile:[directory stringByAppendingPathComponent:@"passport-challenge.txt"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
    return previousOpenURL ? ((BOOL (*)(id, SEL, UIApplication *, NSURL *, NSDictionary *))previousOpenURL)(self, selector, app, url, options) : NO;
}

__attribute__((constructor)) static void preparePassportLinks(void) {
    [NSNotificationCenter.defaultCenter addObserverForName:UIApplicationDidFinishLaunchingNotification object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *notification) {
        Class delegate = [UIApplication.sharedApplication.delegate class];
        SEL selector = @selector(application:openURL:options:);
        Method existing = class_getInstanceMethod(delegate, selector);
        if (existing) previousOpenURL = method_getImplementation(existing);
        if (!class_addMethod(delegate, selector, (IMP)passportOpenURL, "B@:@@@")) method_setImplementation(existing, (IMP)passportOpenURL);
        NSURL *url = notification.userInfo[UIApplicationLaunchOptionsURLKey];
        if (url) passportOpenURL(UIApplication.sharedApplication.delegate, selector, UIApplication.sharedApplication, url, @{});
    }];
}
