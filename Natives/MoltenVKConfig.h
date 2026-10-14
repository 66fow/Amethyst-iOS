#pragma once

#import <Foundation/Foundation.h>

@interface MoltenVKConfig : NSObject

+ (void)applyEnvironmentFromPreferences;
+ (NSString *)activeConfigSummary;

@end
