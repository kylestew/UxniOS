#import <Foundation/Foundation.h>
#import "UxnBridge.h"
#import "uxn.h"
#import "ppu.h"

@implementation UxnBridge {
}

static Uxn uxn;
static Ppu ppu;
static Device *devscreen, *devmouse;

static Uint8 zoom = 0, debug = 0, reqdraw = 0;

- (instancetype)init {
    if (self == [super init]) {
        if(!initppu(&ppu, 64, 40))
            assert(false);
//            return error("PPU", "Init failure");
    }
    return self;
}

- (void)dealloc {
}

#pragma mark - Helpers

static int clamp(int val, int min, int max) {
    return (val >= min) ? (val <= max) ? val : max : min;
}

#pragma mark - Graphics

- (CGSize)screenSize {
    CGFloat width = ppu.hor * 8;
    CGFloat height = ppu.ver * 8;
    return CGSizeMake(width, height);
}

- (void)redraw {
    // determine if screen needs refresh
    evaluxn(&uxn, mempeek16(devscreen->dat, 0));

    if (!reqdraw) return;
    reqdraw = 0;

    int width = ppu.width;
    int height = ppu.height;
    int length = width * height * sizeof(UInt32);

    CFDataRef bridgedDataBG;
    CFDataRef bridgedDataFG;
    CGDataProviderRef dataProviderBG;
    CGDataProviderRef dataProviderFG;
    CGColorSpaceRef colorSpace;
    CGBitmapInfo infoFlags = (CGBitmapInfo)kCGImageAlphaFirst | kCGBitmapByteOrder32Little; // ARGB

    colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);

    NSData* bgImageData = [[NSData alloc] initWithBytes: ppu.bg.pixels length: length];
    NSData* fgImageData = [[NSData alloc] initWithBytes: ppu.fg.pixels length: length];

    bridgedDataBG = (__bridge CFDataRef)bgImageData;
    bridgedDataFG = (__bridge CFDataRef)fgImageData;

    dataProviderBG = CGDataProviderCreateWithCFData(bridgedDataBG);
    dataProviderFG = CGDataProviderCreateWithCFData(bridgedDataFG);

    _bgImageRef = CGImageCreate(
                                width, height, /* bpc */ 8, /* bpp */ 32, /* pitch */ width * 4,
                                colorSpace, infoFlags,
                                dataProviderBG, /* decode array */ NULL, /* interpolate? */ TRUE,
                                kCGRenderingIntentDefault /* adjust intent according to use */
                                );
    _fgImageRef = CGImageCreate(
                                width, height, /* bpc */ 8, /* bpp */ 32, /* pitch */ width * 4,
                                colorSpace, infoFlags,
                                dataProviderFG, /* decode array */ NULL, /* interpolate? */ TRUE,
                                kCGRenderingIntentDefault /* adjust intent according to use */
                                );

    // Release things the image took ownership of.
    CGDataProviderRelease(dataProviderBG);
    CGDataProviderRelease(dataProviderFG);
    CGColorSpaceRelease(colorSpace);
}

#pragma mark - Input

/* == Mouse ==
 * 0x00 - vector
 * 0x20 - x
 * 0x40 - y
 * 0x60 - state [mouse button]
 * 0x70 - wheel (not implemented)
 */
- (void)domouse:(CGPoint)position taps:(int)taps state:(int)state {
    Uint16 x = clamp(position.x, 0, ppu.hor * 8 - 1);
    Uint16 y = clamp(position.y, 0, ppu.ver * 8 - 1);

    mempoke16(devmouse->dat, 0x2, x);
    mempoke16(devmouse->dat, 0x4, y);

    Uint8 flag = 0x00;
    if (taps == 1) {
        // tap - left click
        flag = 0x01;
    } else if (taps == 2) {
        // two finger tap - right click
        flag = 0x10;
    }
    if (state == 0) {
        // touches began
        devmouse->dat[6] |= flag;
    } else if (state == 1) {
        // touches ended
        devmouse->dat[6] &= (~flag);
    }

    // fire vector
    evaluxn(&uxn, mempeek16(devmouse->dat, 0));
}

#pragma mark - Devices

static void system_talk(Device *d, Uint8 b0, Uint8 w) {
    if(!w) {
        d->dat[0x2] = d->u->wst.ptr;
        d->dat[0x3] = d->u->rst.ptr;
    } else {
        putcolors(&ppu, &d->dat[0x8]);
        reqdraw = 1;
    }
    (void)b0;
}

static void console_talk(Device *d, Uint8 b0, Uint8 w) {
    if(w && b0 > 0x7)
        write(b0 - 0x7, (char *)&d->dat[b0], 1);
}

static void screen_talk(Device *d, Uint8 b0, Uint8 w) {
    if(w && b0 == 0xe) {
        Uint16 x = mempeek16(d->dat, 0x8);
        Uint16 y = mempeek16(d->dat, 0xa);
        Uint8 *addr = &d->mem[mempeek16(d->dat, 0xc)];
        Layer *layer = d->dat[0xe] >> 4 & 0x1 ? &ppu.fg : &ppu.bg;
        Uint8 mode = d->dat[0xe] >> 5;
        if(!mode)
            putpixel(&ppu, layer, x, y, d->dat[0xe] & 0x3);
        else if(mode-- & 0x1)
            puticn(&ppu, layer, x, y, addr, d->dat[0xe] & 0xf, mode & 0x2, mode & 0x4);
        else
            putchr(&ppu, layer, x, y, addr, d->dat[0xe] & 0xf, mode & 0x2, mode & 0x4);
        reqdraw = 1;
    }
}

static void datetime_talk(Device *d, Uint8 b0, Uint8 w) {
    time_t seconds = time(NULL);
    struct tm *t = localtime(&seconds);
    t->tm_year += 1900;
    mempoke16(d->dat, 0x0, t->tm_year);
    d->dat[0x2] = t->tm_mon;
    d->dat[0x3] = t->tm_mday;
    d->dat[0x4] = t->tm_hour;
    d->dat[0x5] = t->tm_min;
    d->dat[0x6] = t->tm_sec;
    d->dat[0x7] = t->tm_wday;
    mempoke16(d->dat, 0x08, t->tm_yday);
    d->dat[0xa] = t->tm_isdst;
    (void)b0;
    (void)w;
}

static void nil_talk(Device *d, Uint8 b0, Uint8 w) {
    (void)d;
    (void)b0;
    (void)w;
}

#pragma mark - Load & Setup

- (BOOL)load:(NSString *)romFile {
    if (!bootuxn(&uxn))
        return NO;
    if (!loaduxn(&uxn, [romFile UTF8String]))
        return NO;

    portuxn(&uxn, 0x0, "system", system_talk);
    portuxn(&uxn, 0x1, "console", console_talk);
    devscreen = portuxn(&uxn, 0x2, "screen", screen_talk);
    // 0x3 - audio0
    // 0x4 - audio1
    // 0x5 - audio2
    // 0x6 - audio3
    // 0x7 ----
    // 0x8 - controller
    devmouse = portuxn(&uxn, 0x9, "mouse", nil_talk);
    // 0xa - file
    portuxn(&uxn, 0xb, "datetime", datetime_talk);
    // 0xc ----
    // 0xd ----
    // 0xe ----
    // 0xf ----

    /* Write screen size to dev/screen */
    mempoke16(devscreen->dat, 2, ppu.hor * 8);
    mempoke16(devscreen->dat, 4, ppu.ver * 8);

    evaluxn(&uxn, 0x0100);

    return YES;
}

@end
