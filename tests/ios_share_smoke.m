#import <UIKit/UIKit.h>
#import "../ios/native/PassportShare.m"

@interface PassportShareSmoke : UIResponder <UIApplicationDelegate>
@property(nonatomic, strong) UIWindow *window;
@property(nonatomic) BOOL started;
@property(nonatomic) NSUInteger shareIndex;
@property(nonatomic, strong) NSMutableDictionary *report;
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
    NSDictionary *backup = @{@"format": @"passport-run-backup-v1", @"profile": @{@"version": @1, @"discoveries": @[]}};
    [[NSJSONSerialization dataWithJSONObject:backup options:0 error:nil] writeToFile:[passportShareDirectory() stringByAppendingPathComponent:@"passport-run-backup.json"] atomically:YES];
    NSData *gif = [[NSData alloc] initWithBase64EncodedString:@"R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7" options:0];
    [gif writeToFile:[passportShareDirectory() stringByAppendingPathComponent:@"passport-run-movie.gif"] atomically:YES];
    self.report = [@{@"sheet_presented": @YES, @"cancel_handled": @YES, @"busy_reset": @YES} mutableCopy];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ [self testNextShare]; });
}
- (void)testNextShare {
    NSArray *filenames = @[@"passport-run-room.png", @"passport-run-backup.json", @"passport-run-movie.gif"];
    NSArray *keys = @[@"picture_sheet", @"backup_sheet", @"movie_sheet"];
    NSUInteger index = self.shareIndex;
    NSDictionary *request = @{@"id": @"123456789012345678901234", @"filename": filenames[index], @"expires": @(NSDate.date.timeIntervalSince1970 + 10)};
    [[NSJSONSerialization dataWithJSONObject:request options:0 error:nil] writeToFile:[passportShareDirectory() stringByAppendingPathComponent:@"passport-share-request.json"] atomically:YES];
    __block NSUInteger polls = 0;
    [NSTimer scheduledTimerWithTimeInterval:0.25 repeats:YES block:^(NSTimer *timer) {
        polls += 1;
        UIViewController *shown = self.window.rootViewController.presentedViewController;
        BOOL sheet = [shown isKindOfClass:UIActivityViewController.class];
        if ((!sheet || shown.isBeingPresented) && polls < 48) return;
        [timer invalidate];
        if (sheet) {
            ((UIActivityViewController *)shown).completionWithItemsHandler(nil, NO, nil, nil);
            [shown dismissViewControllerAnimated:NO completion:nil];
        }
        NSData *result = [NSData dataWithContentsOfFile:[passportShareDirectory() stringByAppendingPathComponent:@"passport-share-result.json"]];
        NSDictionary *status = result ? [NSJSONSerialization JSONObjectWithData:result options:0 error:nil] : @{};
        self.report[keys[index]] = @(sheet);
        self.report[@"sheet_presented"] = @([self.report[@"sheet_presented"] boolValue] && sheet);
        self.report[@"cancel_handled"] = @([self.report[@"cancel_handled"] boolValue] && [status[@"state"] isEqualToString:@"cancelled"]);
        self.report[@"busy_reset"] = @([self.report[@"busy_reset"] boolValue] && !passportShareBusy);
        self.shareIndex += 1;
        if (self.shareIndex < filenames.count) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ [self testNextShare]; });
        } else {
            [[NSJSONSerialization dataWithJSONObject:self.report options:0 error:nil] writeToFile:[passportShareDirectory() stringByAppendingPathComponent:@"native-smoke-result.json"] atomically:YES];
        }
    }];
}
@end
int main(int argc, char *argv[]) {
    @autoreleasepool { return UIApplicationMain(argc, argv, nil, NSStringFromClass(PassportShareSmoke.class)); }
}
