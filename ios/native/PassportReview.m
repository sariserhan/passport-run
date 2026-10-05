#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>

// Shows Apple's rating sheet when the game writes Documents/passport-review-request.
// iOS decides whether it actually appears (at most three times a year per user).
static void passportPollReview(void) {
    if (UIApplication.sharedApplication.applicationState != UIApplicationStateActive) return;
    NSString *directory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *path = [directory stringByAppendingPathComponent:@"passport-review-request"];
    if (![NSFileManager.defaultManager fileExistsAtPath:path]) return;
    [NSFileManager.defaultManager removeItemAtPath:path error:nil];
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if ([scene isKindOfClass:UIWindowScene.class] && scene.activationState == UISceneActivationStateForegroundActive) {
            [SKStoreReviewController requestReviewInScene:(UIWindowScene *)scene];
            return;
        }
    }
}
__attribute__((constructor)) static void preparePassportReview(void) {
    [NSNotificationCenter.defaultCenter addObserverForName:UIApplicationDidFinishLaunchingNotification object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *notification) {
        [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer *timer) { passportPollReview(); }];
    }];
}
