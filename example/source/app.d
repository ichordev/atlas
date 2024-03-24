
import atlas;

import core.thread, core.time;
import std.algorithm.comparison, std.conv, std.exception, std.format, std.random, std.string;

import bindbc.sdl;

void main(string[] args){
	uint width    = args.length > 1 ? args[1].to!uint()   : 800;
	uint height   = args.length > 2 ? args[2].to!uint()   : 800;
	Method method = args.length > 3 ? args[3].to!Method() : Method.rows;
	uint padding  = args.length > 4 ? args[4].to!uint()   : 0;
	
	auto rects = new Rect!(ubyte[3])[](uniform(50, 80));
	foreach(ref rect; rects){
		rect.w = uniform(8, 180);
		rect.h = uniform(8, 180);
		rect.userData = [
			cast(ubyte)uniform(0,255),
			cast(ubyte)uniform(0,255),
			cast(ubyte)uniform(0,255),
		];
	}
	rects = atlas.pack(rects, width, height, method, padding);
	
	enforce(SDL_Init(SDL_INIT_VIDEO) == 0, format("SDL couldn't initialise: %s", SDL_GetError().fromStringz()));
	
	SDL_Window* window;
	SDL_Renderer* renderer;
	enforce(SDL_CreateWindowAndRenderer(
		width, height,
		SDL_WINDOW_SHOWN,
		&window, &renderer,
	) == 0, format("SDL window/renderer creation error: %s", SDL_GetError().fromStringz()));
	
	SDL_SetWindowTitle(window, "Atlas Example");
	
	mainLoop: while(true){
		SDL_Event event;
		while(SDL_PollEvent(&event)){
			switch(event.type){
				case SDL_KEYDOWN:
					switch(event.key.keysym.scancode){
						case SDL_SCANCODE_ESCAPE:
							break mainLoop;
						default:
					}
					break;
				case SDL_QUIT:
					break mainLoop;
				default:
			}
		}
		
		SDL_SetRenderDrawColour(renderer, 0, 0, 0, 0xFF);
		SDL_RenderClear(renderer);
		
		foreach(rect; rects){
			if(padding){
				SDL_SetRenderDrawColour(
					renderer,
					rect.userData[0] / 2,
					rect.userData[1] / 2,
					rect.userData[2] / 2,
					0xFF,
				);
				auto paddingRect = SDL_Rect(rect.x-padding, rect.y-padding, rect.w+padding*2, rect.h+padding*2);
				SDL_RenderFillRect(renderer, &paddingRect);
			}
			SDL_SetRenderDrawColour(
				renderer,
				rect.userData[0],
				rect.userData[1],
				rect.userData[2],
				0xFF,
			);
			auto drawRect = SDL_Rect(rect.x, rect.y, rect.w, rect.h);
			SDL_RenderFillRect(renderer, &drawRect);
		}
		
		SDL_RenderPresent(renderer);
		Thread.sleep(20.msecs);
	}
	
	SDL_DestroyWindow(window);
	SDL_Quit();
	
}
