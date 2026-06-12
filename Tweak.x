#import "Headers.h"

#define PREFS_ID CFSTR("com.noisyflake.internaltest")

static BBServer *notificationserver = nil;

static dispatch_queue_t getBBServerQueue() {
    static dispatch_queue_t queue;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        void *handle = dlopen(NULL, RTLD_GLOBAL);
        if (handle) {
            dispatch_queue_t __weak *pointer = (__weak dispatch_queue_t *) dlsym(handle, "__BBServerQueue");
            if (pointer) {
                queue = *pointer;
            }
            dlclose(handle);
        }
    });
    return queue;
}

%hook BBServer
-(id)initWithQueue:(id)arg1 {
    notificationserver = %orig;
    return notificationserver;
}
%end

@implementation NotificationFaker
+ (instancetype)sharedInstance {
    static NotificationFaker *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[NotificationFaker alloc] init];
    });
    return sharedInstance;
}

-(void)showNotificationWithTitle:(NSString*)title message:(NSString*)message bundleID:(NSString*)bundleID threadIdentifier:(NSString*)threadIdentifier {
    BBBulletin *request = [NSClassFromString(@"BBBulletin") new];
    NSDate *date = [NSDate date];

    request.section = bundleID;
    request.sectionID = bundleID;
    request.bulletinID = [self newUUID];
    request.bulletinVersionID = [self newUUID];
    request.publisherBulletinID = [self newUUID];
    request.recordID = [self newUUID];
    request.title = title;
    request.message = message;
    request.date = date;
    request.publicationDate = date;
    request.clearable = YES;

    if (threadIdentifier.length > 0) {
        // Property name varies across iOS versions; try each candidate safely.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        for (NSString *selName in @[@"setThreadIdentifier:", @"setSubsectionID:", @"setThreadID:"]) {
            SEL sel = NSSelectorFromString(selName);
            if ([request respondsToSelector:sel]) {
                [request performSelector:sel withObject:threadIdentifier];
                break;
            }
        }
#pragma clang diagnostic pop
    }

    BBAction *defaultAction = [NSClassFromString(@"BBAction") actionWithIdentifier:@"com.apple.UNNotificationDefaultActionIdentifier"];
    request.defaultAction = defaultAction;

    dispatch_sync(getBBServerQueue(), ^{
        [notificationserver publishBulletin:request destinations:14];
    });
}

-(NSString *)newUUID {
    NSUUID *uuid = [NSUUID UUID];
    return [uuid UUIDString];
}
@end

static void sendTestNotificationCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    CFPreferencesAppSynchronize(PREFS_ID);

    NSString *bundleID = (__bridge_transfer NSString *)CFPreferencesCopyAppValue(CFSTR("selectedBundleID"), PREFS_ID);
    NSString *sender   = (__bridge_transfer NSString *)CFPreferencesCopyAppValue(CFSTR("notifSender"),      PREFS_ID);
    NSString *title    = (__bridge_transfer NSString *)CFPreferencesCopyAppValue(CFSTR("notifTitle"),       PREFS_ID);
    NSString *message  = (__bridge_transfer NSString *)CFPreferencesCopyAppValue(CFSTR("notifMessage"),     PREFS_ID);

    if (!bundleID) bundleID = @"com.apple.MobileSMS";
    if (!message || message.length == 0) message = @"This is a fake notification";

    NSString *notifTitle;
    NSString *threadID;

    if (sender.length > 0) {
        // Sender overrides title and creates a per-sender notification group
        notifTitle = sender;
        threadID   = sender;
    } else {
        notifTitle = (title.length > 0) ? title : @"Notification";
        threadID   = nil;
    }

    [[NotificationFaker sharedInstance] showNotificationWithTitle:notifTitle
                                                          message:message
                                                         bundleID:bundleID
                                               threadIdentifier:threadID];
}

%ctor {
    %init;

    CFNotificationCenterAddObserver(
        CFNotificationCenterGetDarwinNotifyCenter(),
        NULL,
        sendTestNotificationCallback,
        CFSTR("com.noisyflake.internaltest/sendTestNotification"),
        NULL,
        CFNotificationSuspensionBehaviorDeliverImmediately
    );
}
