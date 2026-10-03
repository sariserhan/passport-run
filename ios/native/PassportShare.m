#import <UIKit/UIKit.h>

static BOOL passportShareBusy = NO;
static NSString *passportShareDirectory(void) {
    return NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
}
static void passportShareResult(NSString *identifier, NSString *state) {
    NSData *data = [NSJSONSerialization dataWithJSONObject:@{@"id": identifier, @"state": state} options:0 error:nil];
    [data writeToFile:[passportShareDirectory() stringByAppendingPathComponent:@"passport-share-result.json"] atomically:YES];
}
static void passportPollShare(void) {
    if (passportShareBusy || UIApplication.sharedApplication.applicationState != UIApplicationStateActive) return;
    NSString *requestPath = [passportShareDirectory() stringByAppendingPathComponent:@"passport-share-request.json"];
    NSData *data = [NSData dataWithContentsOfFile:requestPath];
    if (!data) return;
    [NSFileManager.defaultManager removeItemAtPath:requestPath error:nil];
    if (data.length > 2048) return;
    id parsed = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    if (![parsed isKindOfClass:NSDictionary.class]) return;
    NSDictionary *request = parsed;
    NSString *identifier = request[@"id"];
    NSString *filename = request[@"filename"];
    if (![identifier isKindOfClass:NSString.class] || identifier.length != 24) return;
    if (![filename isKindOfClass:NSString.class] || ![@[@"passport-run-room.png", @"passport-run-album.png", @"passport-run-journal.png", @"passport-run-photo.png", @"passport-run-scrapbook.png"] containsObject:filename] || ![request[@"expires"] isKindOfClass:NSNumber.class] || [request[@"expires"] doubleValue] < NSDate.date.timeIntervalSince1970) {
        passportShareResult(identifier, @"error"); return;
    }
    NSString *picturePath = [passportShareDirectory() stringByAppendingPathComponent:filename];
    NSDictionary *attributes = [NSFileManager.defaultManager attributesOfItemAtPath:picturePath error:nil];
    if (!attributes || [attributes fileSize] > 20000000) { passportShareResult(identifier, @"error"); return; }
    UIImage *image = [UIImage imageWithContentsOfFile:picturePath];
    if (!image) { passportShareResult(identifier, @"error"); return; }
    UIWindow *window = nil;
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (![scene isKindOfClass:UIWindowScene.class] || scene.activationState != UISceneActivationStateForegroundActive) continue;
        for (UIWindow *candidate in ((UIWindowScene *)scene).windows) if (candidate.isKeyWindow) { window = candidate; break; }
        if (window) break;
    }
    if (!window && [UIApplication.sharedApplication.delegate respondsToSelector:@selector(window)]) window = UIApplication.sharedApplication.delegate.window;
    UIViewController *presenter = window.rootViewController;
    while (presenter.presentedViewController) presenter = presenter.presentedViewController;
    if (!presenter || !presenter.view.window || presenter.isBeingDismissed || presenter.isBeingPresented) { passportShareResult(identifier, @"error"); return; }
    passportShareBusy = YES;
    UIActivityViewController *share = [[UIActivityViewController alloc] initWithActivityItems:@[image] applicationActivities:nil];
    share.popoverPresentationController.sourceView = presenter.view;
    share.popoverPresentationController.sourceRect = CGRectMake(CGRectGetMidX(presenter.view.bounds), CGRectGetMidY(presenter.view.bounds), 1, 1);
    share.popoverPresentationController.permittedArrowDirections = 0;
    share.completionWithItemsHandler = ^(UIActivityType activity, BOOL completed, NSArray *items, NSError *error) {
        passportShareBusy = NO;
        passportShareResult(identifier, error ? @"error" : completed ? @"shared" : @"cancelled");
    };
    [presenter presentViewController:share animated:YES completion:^{ passportShareResult(identifier, @"opened"); }];
#if !__has_feature(objc_arc)
    [share release];
#endif
}
__attribute__((constructor)) static void preparePassportSharing(void) {
    [NSNotificationCenter.defaultCenter addObserverForName:UIApplicationDidFinishLaunchingNotification object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *notification) {
        [NSFileManager.defaultManager removeItemAtPath:[passportShareDirectory() stringByAppendingPathComponent:@"passport-share-request.json"] error:nil];
        [NSTimer scheduledTimerWithTimeInterval:0.25 repeats:YES block:^(NSTimer *timer) { passportPollShare(); }];
    }];
}
