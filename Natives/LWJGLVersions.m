#import "LWJGLVersions.h"
#import "utils.h"

static void parseVersion(NSString *string, int *major, int *minor, int *patch) {
    int parts[3] = {0, 0, 0};
    NSArray<NSString *> *split = [string componentsSeparatedByString:@"."];
    for (NSUInteger i = 0; i < split.count && i < 3; i++) {
        NSScanner *scanner = [NSScanner scannerWithString:split[i]];
        int value = 0;
        if ([scanner scanInt:&value]) parts[i] = value;
    }
    *major = parts[0];
    *minor = parts[1];
    *patch = parts[2];
}

static NSComparisonResult compareVersions(NSString *a, NSString *b) {
    int a3[3], b3[3];
    parseVersion(a, &a3[0], &a3[1], &a3[2]);
    parseVersion(b, &b3[0], &b3[1], &b3[2]);
    for (int i = 0; i < 3; i++) {
        if (a3[i] != b3[i]) return a3[i] < b3[i] ? NSOrderedAscending : NSOrderedDescending;
    }
    return NSOrderedSame;
}

@implementation AMLWJGLVersion
- (NSString *)folder {
    return [@"lwjgl-" stringByAppendingString:self.version];
}
@end

@implementation AMLWJGLSelection
@end

@implementation AMLWJGLVersions

+ (NSArray<AMLWJGLVersion *> *)bundledVersions {
    static NSArray<AMLWJGLVersion *> *versions;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSString *path = [NSBundle.mainBundle.bundlePath stringByAppendingPathComponent:@"lwjgl_versions.txt"];
        NSString *text = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
        NSMutableArray *list = [NSMutableArray new];
        for (NSString *line in [text componentsSeparatedByCharactersInSet:NSCharacterSet.newlineCharacterSet]) {
            NSString *trimmed = [line stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
            if (trimmed.length == 0 || [trimmed hasPrefix:@"#"]) continue;
            NSArray<NSString *> *fields = [trimmed componentsSeparatedByCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
            fields = [fields filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"length > 0"]];
            if (fields.count < 2) {
                NSLog(@"[LWJGL] skipped malformed line in lwjgl_versions.txt: %@", trimmed);
                continue;
            }
            AMLWJGLVersion *entry = [AMLWJGLVersion new];
            entry.version = fields[0];
            entry.nativeSubfolder = fields[1];
            for (NSUInteger i = 2; i < fields.count; i++) {
                if ([fields[i] isEqualToString:@"sdl"]) entry.hasSDL = YES;
                else if ([fields[i] isEqualToString:@"lwjgl2"]) entry.hasLWJGL2 = YES;
            }
            [list addObject:entry];
        }
        [list sortUsingComparator:^NSComparisonResult(AMLWJGLVersion *a, AMLWJGLVersion *b) {
            return compareVersions(a.version, b.version);
        }];
        if (list.count == 0) NSLog(@"[LWJGL] no versions listed in %@", path);
        versions = list;
    });
    return versions;
}

+ (AMLWJGLSelection *)selectForRequiredVersion:(NSString *)requiredVersion versionId:(NSString *)versionId {
    NSArray<AMLWJGLVersion *> *table = self.bundledVersions;
    if (table.count == 0) return nil;

    AMLWJGLSelection *result = [AMLWJGLSelection new];
    BOOL hasRequired = [requiredVersion isKindOfClass:NSString.class] && requiredVersion.length > 0;

    int reqMajor = 0, reqMinor = 0, reqPatch = 0;
    if (!hasRequired) {
        // no lwjglVersion in the json: 26.x needs the SDL build, everything else runs on the LWJGL 2 compatible one
        int idMajor = 0, idMinor = 0, idPatch = 0;
        if ([versionId isKindOfClass:NSString.class]) parseVersion(versionId, &idMajor, &idMinor, &idPatch);
        BOOL wantsSDL = idMajor >= 26;
        for (AMLWJGLVersion *entry in table.reverseObjectEnumerator) {
            if (wantsSDL ? entry.hasSDL : entry.hasLWJGL2) {
                result.version = entry;
                break;
            }
        }
        if (!result.version) result.version = wantsSDL ? table.lastObject : table.firstObject;
        NSLog(@"[LWJGL] no lwjglVersion for %@, using %@", versionId, result.version.version);
        return result;
    }

    parseVersion(requiredVersion, &reqMajor, &reqMinor, &reqPatch);
    if (reqMajor < 3) {
        // LWJGL 2 games run through the lwjglx layer
        for (AMLWJGLVersion *entry in table.reverseObjectEnumerator) {
            if (entry.hasLWJGL2) {
                result.version = entry;
                break;
            }
        }
        if (result.version) {
            NSLog(@"[LWJGL] game wants LWJGL %@, using the lwjglx layer in %@", requiredVersion, result.version.version);
        } else {
            result.version = table.firstObject;
            result.warning = [NSString stringWithFormat:@"This version wants LWJGL %@, but this build has no LWJGL 2 compatibility layer. It will start with LWJGL %@ and may not work.", requiredVersion, result.version.version];
        }
        return result;
    }

    // oldest bundled version that is not older than the request
    for (AMLWJGLVersion *entry in table) {
        if (compareVersions(entry.version, requiredVersion) != NSOrderedAscending) {
            result.version = entry;
            break;
        }
    }
    if (result.version) {
        int bMajor, bMinor, bPatch;
        parseVersion(result.version.version, &bMajor, &bMinor, &bPatch);
        if (bMajor != reqMajor || bMinor != reqMinor) {
            NSLog(@"[LWJGL] game wants LWJGL %@, no %d.%d build is bundled, using %@", requiredVersion, reqMajor, reqMinor, result.version.version);
        }
        return result;
    }

    result.version = table.lastObject;
    result.warning = [NSString stringWithFormat:@"This version wants LWJGL %@, which is newer than the newest bundled one (%@). It will start with %@ and may not work.", requiredVersion, result.version.version, result.version.version];
    NSLog(@"[LWJGL] %@", result.warning);
    return result;
}

@end
