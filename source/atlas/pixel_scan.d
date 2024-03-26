module atlas.pixel_scan;

import core.memory: pureCalloc, pureFree;

void swap(T)(ref T a, ref T b) nothrow @nogc pure @safe{
	auto c = a;
	a = b;
	b = c;
}

R[] packPixelScan(R)(scope return ref R[] rects, uint width, uint height) nothrow @nogc pure @safe{
	size_t nextFreeLen = width * height;
	size_t[] nextFree = (
		() @trusted => (
			cast(size_t*)pureCalloc(nextFreeLen, size_t.sizeof)
		)[0..nextFreeLen]
	)();
	scope(exit){
		() @trusted{
			pureFree(nextFree.ptr);
		}();
	}
	
	uint y;
	size_t i;
	size_t unpackedI;
	while(true){
		uint x;
		scanning: while(x+rects[i].w < width){
			if(y+rects[i].h >= height){
				if(++unpackedI >= rects.length){
					return rects[0..i];
				}
				swap(rects[i], rects[unpackedI]);
				x = 0;
				y = 0;
				continue scanning;
			}
			size_t scanI = x + (y * width);
			foreach(scanY; 0..rects[i].h){
				foreach(scanX; 0..rects[i].w){
					if(nextFree[scanI] != 0){
						x = cast(uint)(nextFree[scanI] % width);
						y = cast(uint)(nextFree[scanI] / width);
						continue scanning;
					}
					scanI++;
				}
				scanI -= rects[i].w; //move to first column
				scanI += width; //move to next row
			}
			size_t fillI = x + (y * width);
			foreach(fillY; 0..rects[i].h){
				nextFree[fillI..fillI+rects[i].w] = fillI+rects[i].w;
				fillI += width; //move to next row
			}
			rects[i].x = x;
			rects[i].y = y;
			rects[i].packed = true;
			
			x = 0;
			y = 0;
			i++;
			unpackedI++;
			if(i >= rects.length || unpackedI >= rects.length){
				return rects;
			}
		}
		y++;
	}
	assert(0);
}
