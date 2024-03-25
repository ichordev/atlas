
import atlas;

import core.thread, core.time;
import std.algorithm.comparison, std.conv, std.exception, std.format, std.random, std.stdio, std.string;

import bindbc.sdl;

void main(string[] args){
	uint width    = args.length > 1 ? args[1].to!uint()   : 800;
	uint height   = args.length > 2 ? args[2].to!uint()   : 800;
	Method method = args.length > 3 ? args[3].to!Method() : Method.pixelScan;
	uint padding  = args.length > 4 ? args[4].to!uint()   : 0;
	
	auto unpackedRects = new Rect!(ubyte[3])[](uniform(800, 1350));
	foreach(ref rect; unpackedRects){
		if(uniform(0,10) == 0){
			rect.w = uniform(24, 96);
		}else{
			rect.w = uniform(10, 24);
		}
		if(uniform(0,10) == 0){
			rect.h = uniform(24, 96);
		}else{
			rect.h = uniform(10, 24);
		}
		rect.userData = [
			cast(ubyte)uniform(0,255),
			cast(ubyte)uniform(0,255),
			cast(ubyte)uniform(0,255),
		];
	}
	auto packStartTime = MonoTime.currTime;
	auto rects = atlas.pack(unpackedRects, width, height, method, padding);
	auto packEndTime = MonoTime.currTime;
	writeln("Took ", (packEndTime - packStartTime).total!"nsecs"() / cast(double)(1.msecs.total!"nsecs"()),"ms");
	writeln("Failed to pack ", unpackedRects.length - rects.length, " rectangles");
	bool rectInRect(R)(R a, R b){
		uint ax2 = a.x + a.w, ay2 = a.y + a.h;
		uint bx2 = b.x + b.w, by2 = b.y + b.h;
		return ax2 > b.x && a.x < bx2 && ay2 > b.y && a.y < by2;
	}
	uint usedPixels;
	uint maxX, maxY;
	foreach(i, rect1; rects){
		usedPixels += (rect1.w + padding*2) * (rect1.h + padding*2);
		maxX = max(maxX, rect1.x + rect1.w + padding);
		maxY = max(maxY, rect1.y + rect1.h + padding);
		foreach(rect2; rects[0..i]){
			if(rectInRect(rect1, rect2)){
				writeln("ERR: ",rect1," intersects ",rect2);
			}
		}
		foreach(rect2; rects[i+1..$]){
			if(rectInRect(rect1, rect2)){
				writeln("ERR: ",rect1," intersects ",rect2);
			}
		}
	}
	uint usedArea = maxX * maxY;
	uint wastedPixels = usedArea - usedPixels;
	writeln("Wasted ",wastedPixels," of ", usedArea," pixels (", (wastedPixels / cast(double)(width*height)) * 100.0, "%)");
	
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
