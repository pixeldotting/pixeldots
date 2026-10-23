// SDL2 front end. Under cage SDL uses the Wayland driver; the Canvas is shown with nearest-neighbour scaling.
#include <SDL2/SDL.h>
#include <csignal>
#include <cstdio>
#include <string>
#include "app.hpp"

int main(int argc, char** argv) {
    std::string data = argc > 1 ? argv[1] : "data";
    signal(SIGPIPE, SIG_IGN);
    SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "0");
    SDL_SetHint(SDL_HINT_VIDEO_ALLOW_SCREENSAVER, "0");
    if (SDL_Init(SDL_INIT_VIDEO) != 0) { std::fprintf(stderr, "SDL_Init: %s\n", SDL_GetError()); return 1; }
    SDL_Window* win = SDL_CreateWindow("pixeldots setup", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, 960, 540,
                                       SDL_WINDOW_FULLSCREEN_DESKTOP | SDL_WINDOW_RESIZABLE);
    if (!win) { std::fprintf(stderr, "SDL_CreateWindow: %s\n", SDL_GetError()); return 1; }
    SDL_Renderer* ren = SDL_CreateRenderer(win, -1, SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC);
    if (!ren) ren = SDL_CreateRenderer(win, -1, SDL_RENDERER_SOFTWARE);
    if (!ren) { std::fprintf(stderr, "SDL_CreateRenderer: %s\n", SDL_GetError()); return 1; }
    SDL_RenderSetLogicalSize(ren, W, H);
    SDL_RenderSetIntegerScale(ren, SDL_TRUE);
    SDL_Texture* tex = SDL_CreateTexture(ren, SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STREAMING, W, H);
    SDL_ShowCursor(SDL_DISABLE);
    SDL_StartTextInput();

    App app(data);
    Canvas cv;
    Uint32 last = SDL_GetTicks();
    while (!app.quit) {
        SDL_Event e;
        while (SDL_PollEvent(&e)) {
            if (e.type == SDL_QUIT) { app.quit = true; app.exitCode = 1; }
            else if (e.type == SDL_TEXTINPUT) app.text(e.text.text);
            else if (e.type == SDL_KEYDOWN) {
                switch (e.key.keysym.sym) {
                    case SDLK_UP: app.key(K::Up); break;
                    case SDLK_DOWN: app.key(K::Down); break;
                    case SDLK_LEFT: app.key(K::Left); break;
                    case SDLK_RIGHT: app.key(K::Right); break;
                    case SDLK_RETURN: case SDLK_KP_ENTER: app.key(K::Enter); break;
                    case SDLK_ESCAPE: app.key(K::Esc); break;
                    case SDLK_BACKSPACE: app.key(K::Backspace); break;
                    case SDLK_TAB: app.key(K::Tab); break;
                    case SDLK_PAGEUP: app.key(K::PgUp); break;
                    case SDLK_PAGEDOWN: app.key(K::PgDn); break;
                    case SDLK_HOME: app.key(K::Home); break;
                    case SDLK_END: app.key(K::End); break;
                    default: break;
                }
            }
        }
        Uint32 now = SDL_GetTicks();
        app.tick((now - last) / 1000.0);
        last = now;
        app.draw(cv);
        SDL_UpdateTexture(tex, nullptr, cv.px.data(), W * 4);
        SDL_RenderClear(ren);
        SDL_RenderCopy(ren, tex, nullptr, nullptr);
        SDL_RenderPresent(ren);
        SDL_Delay(8);
    }
    int code = app.exitCode;
    SDL_DestroyTexture(tex);
    SDL_DestroyRenderer(ren);
    SDL_DestroyWindow(win);
    SDL_Quit();
    return code;
}
