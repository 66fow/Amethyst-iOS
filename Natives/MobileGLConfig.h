#pragma once

#import <Foundation/Foundation.h>

@interface MobileGLConfig : NSObject

+ (void)applyEnvironmentFromPreferences;
+ (NSString *)activeConfigSummary;

@end
