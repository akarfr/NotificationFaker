#import <Preferences/Preferences.h>

@interface PSSpecifier (Dynamic)
- (void)setValues:(NSArray *)values titles:(NSArray *)titles;
@end

@interface NFRootListController : PSListController
- (void)sendTestNotification:(PSSpecifier *)specifier;
- (NSArray<NSDictionary *> *)sortedInstalledApps;
@end

@implementation NFRootListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		NSMutableArray *specs = [[self loadSpecifiersFromPlistName:@"Root" target:self] mutableCopy];

		// Inject dynamic installed app list into the Select App specifier
		NSArray *apps = [self sortedInstalledApps];
		NSMutableArray *names = [NSMutableArray array];
		NSMutableArray *ids   = [NSMutableArray array];
		for (NSDictionary *app in apps) {
			[names addObject:app[@"name"]];
			[ids   addObject:app[@"bundleID"]];
		}

		for (PSSpecifier *spec in specs) {
			if ([[spec propertyForKey:@"key"] isEqualToString:@"selectedBundleID"]) {
				[spec setValues:ids titles:names];
				break;
			}
		}

		_specifiers = specs;
	}
	return _specifiers;
}

- (NSArray<NSDictionary *> *)sortedInstalledApps {
	Class wsClass = NSClassFromString(@"LSApplicationWorkspace");
	if (!wsClass) return @[];

	id workspace = [wsClass performSelector:@selector(defaultWorkspace)];
	NSArray *allApps = [workspace performSelector:@selector(allInstalledApplications)];

	NSMutableArray *result = [NSMutableArray array];
	for (id app in allApps) {
		NSString *bundleID = [app performSelector:@selector(bundleIdentifier)];
		NSString *name     = [app performSelector:@selector(localizedName)];
		if (bundleID.length > 0 && name.length > 0) {
			[result addObject:@{@"name": name, @"bundleID": bundleID}];
		}
	}

	[result sortUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
		return [a[@"name"] localizedCaseInsensitiveCompare:b[@"name"]];
	}];

	return result;
}

- (void)openGitHub:(PSSpecifier *)specifier {
	NSURL *url = [NSURL URLWithString:@"https://github.com/akarfr"];
	[[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
}

- (void)sendTestNotification:(PSSpecifier *)specifier {
	CFNotificationCenterPostNotification(
		CFNotificationCenterGetDarwinNotifyCenter(),
		CFSTR("com.noisyflake.internaltest/sendTestNotification"),
		NULL,
		NULL,
		YES
	);
}

@end
