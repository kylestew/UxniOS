#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UxnBridge : NSObject

- (BOOL)load:(NSString *)romFile;
- (nullable CGImageRef)redraw;

@end

NS_ASSUME_NONNULL_END
