#import <Foundation/Foundation.h>
#import "UxnBridge.h"
#import "uxn.h"

@implementation UxnBridge

- (instancetype)init {
    if (self == [super init]) { }
    return self;
}

static void console_talk(Device *d, Uint8 b0, Uint8 w) {
    if(w && b0 > 0x7)
        write(b0 - 0x7, (char *)&d->dat[b0], 1);
}

static void run(Uxn *u) {
    evaluxn(u, 0x0100);

//    while(1) {
//    }
}

- (BOOL)load:(NSString *)romFile {
    Uxn u;

    if (!bootuxn(&u)) return NO;

    NSString* filePath = [[NSBundle mainBundle] pathForResource:@"hello" ofType:@"rom"];

    if (!loaduxn(&u, [filePath UTF8String]))
        return NO;

    portuxn(&u, 0x1, "console", console_talk);

    run(&u);

    return YES;
}

@end
