#pragma once

#import <Foundation/Foundation.h>

@interface AMLWJGLVersion : NSObject
@property(nonatomic, copy) NSString *version;
@property(nonatomic, copy) NSString *nativeSubfolder;
@property(nonatomic) BOOL hasSDL;
@property(nonatomic) BOOL hasLWJGL2;
// jar folder name, same one JavaApp/libs and -Dpojav.lwjglVersion use
@property(nonatomic, readonly) NSString *folder;
@end

@interface AMLWJGLSelection : NSObject
@property(nonatomic, strong) AMLWJGLVersion *version;
// shown to the user when set, the pick is a stretch for this game
@property(nonatomic, copy) NSString *warning;
@end

@interface AMLWJGLVersions : NSObject

// parsed from lwjgl_versions.txt in the bundle, oldest first
+ (NSArray<AMLWJGLVersion *> *)bundledVersions;

// requiredVersion is the game's lwjglVersion, versionId is only used when that is missing
+ (AMLWJGLSelection *)selectForRequiredVersion:(NSString *)requiredVersion versionId:(NSString *)versionId;

@end
