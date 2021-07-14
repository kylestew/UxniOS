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

/*
 static int
 init(void)
 {
     SDL_AudioSpec as;
     if(!initppu(&ppu, 64, 40))
         return error("PPU", "Init failure");
     gRect.x = PAD;
     gRect.y = PAD;
     gRect.w = ppu.width;
     gRect.h = ppu.height;
     if(SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO) < 0)
         return error("Init", SDL_GetError());
     gWindow = SDL_CreateWindow("Uxn", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, (ppu.width + PAD * 2) * zoom, (ppu.height + PAD * 2) * zoom, SDL_WINDOW_SHOWN);
     if(gWindow == NULL)
         return error("Window", SDL_GetError());
     gRenderer = SDL_CreateRenderer(gWindow, -1, 0);
     if(gRenderer == NULL)
         return error("Renderer", SDL_GetError());
     SDL_RenderSetLogicalSize(gRenderer, ppu.width + PAD * 2, ppu.height + PAD * 2);
     bgTexture = SDL_CreateTexture(gRenderer, SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STATIC, ppu.width + PAD * 2, ppu.height + PAD * 2);
     if(bgTexture == NULL || SDL_SetTextureBlendMode(bgTexture, SDL_BLENDMODE_NONE))
         return error("Texture", SDL_GetError());
     fgTexture = SDL_CreateTexture(gRenderer, SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STATIC, ppu.width + PAD * 2, ppu.height + PAD * 2);
     if(fgTexture == NULL || SDL_SetTextureBlendMode(fgTexture, SDL_BLENDMODE_BLEND))
         return error("Texture", SDL_GetError());
     SDL_UpdateTexture(bgTexture, NULL, ppu.bg.pixels, 4);
     SDL_UpdateTexture(fgTexture, NULL, ppu.fg.pixels, 4);
     SDL_StartTextInput();
     SDL_ShowCursor(SDL_DISABLE);
     SDL_zero(as);
     as.freq = SAMPLE_FREQUENCY;
     as.format = AUDIO_S16;
     as.channels = 2;
     as.callback = audio_callback;
     as.samples = 512;
     as.userdata = NULL;
     audio_id = SDL_OpenAudioDevice(NULL, 0, &as, NULL, 0);
     if(!audio_id)
         return error("Audio", SDL_GetError());
     SDL_PauseAudioDevice(audio_id, 0);
     return 1;
 }
 */

- (instancetype)init {
    if (self == [super init]) {

        // TODO: setup windowing access here

        if(!initppu(&ppu, 64, 40))
            assert(false);
//            return error("PPU", "Init failure");
    }
    return self;
}

/*
 static void
 quit(void)
 {
     free(ppu.fg.pixels);
     free(ppu.bg.pixels);
     SDL_UnlockAudioDevice(audio_id);
     SDL_DestroyTexture(bgTexture);
     bgTexture = NULL;
     SDL_DestroyTexture(fgTexture);
     fgTexture = NULL;
     SDL_DestroyRenderer(gRenderer);
     gRenderer = NULL;
     SDL_DestroyWindow(gWindow);
     gWindow = NULL;
     SDL_Quit();
     exit(0);
 }
 */

- (void)dealloc {
}

#pragma mark - Graphics

static void redraw() {

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

#pragma mark - Start & Loop

static void run() {
    evaluxn(&uxn, 0x0100);
    redraw();
}

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

    run();

    return YES;
}

@end
