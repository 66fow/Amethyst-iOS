#import "MoltenVKConfig.h"
#import "LauncherPreferences.h"

extern char **environ;

// pref, env var, value when the pref is on, value when it is off
static NSArray<NSArray<NSString *> *> *envTable(void) {
    return @[
        @[@"video.moltenvk_fast_math", @"MVK_CONFIG_FAST_MATH_ENABLED", @"2", @"0"],
        @[@"video.moltenvk_argument_buffers", @"MVK_CONFIG_USE_METAL_ARGUMENT_BUFFERS", @"1", @"0"],
        // MoltenVK's default is nearest, which is what the launcher has always used
        @[@"video.moltenvk_smooth_scaling", @"MVK_CONFIG_SWAPCHAIN_MIN_MAG_FILTER_USE_NEAREST", @"0", @"1"],
    ];
}

@implementation MoltenVKConfig

+ (void)applyEnvironmentFromPreferences {
    NSString *custom = getPrefObject(@"java.env_variables") ?: @"";
    for (NSArray<NSString *> *row in envTable()) {
        // a value typed into the java env vars field wins over the toggle
        if ([custom containsString:[row[1] stringByAppendingString:@"="]]) continue;
        setenv(row[1].UTF8String, (getPrefBool(row[0]) ? row[2] : row[3]).UTF8String, 1);
    }
}

+ (NSString *)activeConfigSummary {
    NSMutableArray *vars = [NSMutableArray new];
    for (char **e = environ; *e; e++) {
        if (strncmp(*e, "MVK_", 4) == 0) [vars addObject:@(*e)];
    }
    [vars sortUsingSelector:@selector(compare:)];
    return [vars componentsJoinedByString:@" "];
}

@end
