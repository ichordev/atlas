module atlas;

import atlas.pixel_scan, atlas.rows;

import core.stdc.stdlib: qsort;

/**
A rectangular region with an optional `userData` field of type `U` to associate it with an external resource (e.g. an image).
*/
struct Rect(U){
	uint w = 0, h = 0;
	static if(!is(U == void)){
		U userData;
	}
	
	//the following data should not be entered by the user, but can be read after calling `pack`.
	uint x = 0, y = 0;
	bool packed = false;
}

enum isRect(T) = is(T TT: Rect!(U), U);

///A method to pack rectangles together.
enum Method{
	/**
	A basic, fast, but wasteful algorithm. (~6–10% waste)
	
	It inserts the tallest unpacked rectangle and moves right until it reaches
	the right edge, then goes down by the height of the tallest rectangle in that row.
	*/
	rows,
	/**
	A relatively simple but slow algorithm, that tends to waste very little space. (~2–6% waste)
	
	It inserts the tallest unpacked rectangle into the topmost, leftmost
	space large enough to accommodate it.
	*/
	pixelScan,
}

/**
Packs `rects` into a rectangular region with size `width` by `height`, using `method`.
Accounts for `padding` grid-spaces of padding on all sides of the `rects`.
The data in `rects` will be re-ordered.

Returns: A slice of `rects`, containing only the rectangles that could fit into the packing region.
*/
R[] pack(R)(scope return ref R[] rects, uint width, uint height, Method method, uint padding=0) nothrow @nogc
if(isRect!R){
	with(Method) final switch(method){
		case rows, pixelScan:
			qsort(&rects[0], rects.length, rects[0].sizeof, &sortRectHeight!R);
			break;
	}
	return packSorted(rects, width, height, method, padding);
}

extern(C) private int sortRectHeight(R)(const(void)* aPtr, const(void)* bPtr) nothrow @nogc{
	auto a = cast(const(R)*)aPtr;
	auto b = cast(const(R)*)bPtr;
	return b.h - a.h;
}

/**
Same as `pack`, but requires `rects` to be sorted by their height (tallest first) for the following methods:
- rows

Note that even for methods that don't require sorting, the results will still be inferior if the rectangles aren't sorted by height.
*/
R[] packSorted(R)(scope return ref R[] rects, uint width, uint height, Method method, uint padding=0) nothrow @nogc pure @safe
if(isRect!R){
	if(padding){
		foreach(ref rect; rects){
			rect.w += padding * 2;
			rect.h += padding * 2;
		}
	}
	auto ret = {
		with(Method) final switch(method){
			case rows:         return packRows(rects, width, height);
			case pixelScan:    return packPixelScan(rects, width, height);
		}
	}();
	if(padding){
		foreach(ref rect; rects){
			rect.x += padding;
			rect.y += padding;
			rect.w -= padding * 2;
			rect.h -= padding * 2;
		}
	}
	return ret;
}
