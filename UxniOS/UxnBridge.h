#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UxnBridge : NSObject

@property (nonatomic, assign) CGImageRef bgImageRef;
@property (nonatomic, assign) CGImageRef fgImageRef;

- (BOOL)load:(NSString *)romFile;

- (CGSize)screenSize;
- (void)redraw;

@end

NS_ASSUME_NONNULL_END
