#import "GameSurfaceView.h"
#import "LauncherPreferences.h"
#import "PLProfiles.h"
#import "utils.h"

@interface GameSurfaceView()
@end

@implementation GameSurfaceView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    self.layer.drawsAsynchronously = YES;
    self.layer.opaque = YES;

    return self;
}

+ (Class)layerClass {
    NSString *renderer = [PLProfiles resolveKeyForCurrentProfile:@"renderer"];
    if (renderer && [renderer hasPrefix:@"libOSMesa"]) {
        // Zink (Mesa) renderer uses a regular CALayer
        return CALayer.class;
    } else {
        // Default to Metal-backed layer
        return CAMetalLayer.class;
    }
}

@end
