module atlas.rows;

R[] packRows(R)(scope return ref R[] rects, uint width, uint height) nothrow @nogc pure @safe{
	uint y;
	size_t i;
	while(y+rects[i].h < height){
		uint x;
		uint rowH = rects[i].h;
		while(x+rects[i].w < width){
			rects[i].x = x;
			rects[i].y = y;
			rects[i].packed = true;
			
			x += rects[i].w;
			if(++i >= rects.length){
				return rects;
			}
		}
		y += rowH;
	}
	return rects[0..i];
}
