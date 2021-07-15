#import <Foundation/Foundation.h>
#import "UxnBridge.h"
#import "uxn.h"
#import "ppu.h"

@implementation UxnBridge {
}

static Uxn uxn;
static Ppu ppu;
static Device *devscreen;

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

#pragma mark - Graphics

- (CGSize)screenSize {
    CGFloat width = ppu.hor * 8;
    CGFloat height = ppu.ver * 8;
    return CGSizeMake(width, height);
}

- (void)redraw {
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
    CGBitmapInfo infoFlags = (CGBitmapInfo)kCGImageAlphaFirst; // ARGB

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

#pragma mark - Load & Setup

- (BOOL)load:(NSString *)romFile {
    // TODO: these require '&' and I'm not sure why
    if (!bootuxn(&uxn))
        return NO;
    if (!loaduxn(&uxn, [romFile UTF8String]))
        return NO;

    portuxn(&uxn, 0x0, "system", system_talk);
    portuxn(&uxn, 0x1, "console", console_talk);
    devscreen = portuxn(&uxn, 0x2, "screen", screen_talk);

    /* Write screen size to dev/screen */
    mempoke16(devscreen->dat, 2, ppu.hor * 8);
    mempoke16(devscreen->dat, 4, ppu.ver * 8);

    evaluxn(&uxn, 0x0100);

    return YES;
}

@end
