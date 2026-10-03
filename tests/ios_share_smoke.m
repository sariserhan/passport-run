#import <UIKit/UIKit.h>
#import "../ios/native/PassportShare.m"

@interface PassportShareSmoke : UIResponder <UIApplicationDelegate>
@property(nonatomic, strong) UIWindow *window;
@property(nonatomic) BOOL started;
@end
@implementation PassportShareSmoke
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)options {
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.window.rootViewController = [UIViewController new];
    self.window.rootViewController.view.backgroundColor = UIColor.systemTealColor;
    [self.window makeKeyAndVisible];
    return YES;
}
- (void)applicationDidBecomeActive:(UIApplication *)application {
    if (self.started) return;
    self.started = YES;
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(720, 1000)];
    UIImage *image = [renderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
        [UIColor.systemTealColor setFill]; UIRectFill(CGRectMake(0, 0, 720, 1000));
        [@"PASSPORT RUN · MY ROOM" drawAtPoint:CGPointMake(30, 50) withAttributes:@{NSFontAttributeName: [UIFont boldSystemFontOfSize:30], NSForegroundColorAttributeName: UIColor.whiteColor}];
    }];
    [UIImagePNGRepresentation(image) writeToFile:[passportShareDirectory() stringByAppendingPathComponent:@"passport-run-room.png"] atomically:YES];
    NSDictionary *request = @{@"id": @"123456789012345678901234", @"filename": @"passport-run-room.png", @"expires": @(NSDate.date.timeIntervalSince1970 + 10)};
    [[NSJSONSerialization dataWithJSONObject:request options:0 error:nil] writeToFile:[passportShareDirectory() stringByAppendingPathComponent:@"passport-share-request.json"] atomically:YES];
    [NSTimer scheduledTimerWithTimeInterval:3 repeats:NO block:^(NSTimer *timer) {
        UIViewController *shown = self.window.rootViewController.presentedViewController;
        BOOL sheet = [shown isKindOfClass:UIActivityViewController.class];
        if (sheet) ((UIActivityViewController *)shown).completionWithItemsHandler(nil, NO, nil, nil);
        NSData *result = [NSData dataWithContentsOfFile:[passportShareDirectory() stringByAppendingPathComponent:@"passport-share-result.json"]];
        NSDictionary *status = result ? [NSJSONSerialization JSONObjectWithData:result options:0 error:nil] : @{};
        NSDictionary *report = @{@"sheet_presented": @(sheet), @"cancel_handled": @([status[@"state"] isEqualToString:@"cancelled"]), @"busy_reset": @(!passportShareBusy)};
        [[NSJSONSerialization dataWithJSONObject:report options:0 error:nil] writeToFile:[passportShareDirectory() stringByAppendingPathComponent:@"native-smoke-result.json"] atomically:YES];
    }];
}
@end
int main(int argc, char *argv[]) {
    @autoreleasepool { return UIApplicationMain(argc, argv, nil, NSStringFromClass(PassportShareSmoke.class)); }
}
