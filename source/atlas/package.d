module atlas;

import atlas.rows;

import core.stdc.stdlib: qsort;

/**
Stores a rectangular region, with an optional `userData` field to associate it with an external resource (e.g. an image).
*/
struct Rect(U){
	uint w, h;
	static if(!is(U == void)){
		U userData;
	}
	
	//the following data should not be entered by the user, but can be read after calling `pack`.
	uint x = 0, y = 0;
	bool packed = false;
}

enum isRect(T) = is(T TT: Rect!(U), U);

enum Method{
	rows, ///A basic, fast, but somewhat space-wasteful algorithm.
}

/**
Packs `rects` into a rectangular region with size `width` by `height`, using `method`.
Accounts for `padding` grid-spaces of padding on all sides of the `rects`.

Returns: A slice of `rects`, containing only the rectangles that could fit into the packing region.
*/
R[] pack(R)(scope return ref R[] rects, uint width, uint height, Method method, uint padding=0) nothrow @nogc
if(isRect!R){
	with(Method) final switch(method){
		case rows:
			qsort(&rects[0], rects.length, rects[0].sizeof, &sortRectHeight!R);
			break;
	}
	return packSorted(rects, width, height, method, padding);
}

extern(C) int sortRectHeight(R)(const(void)* aPtr, const(void)* bPtr) nothrow @nogc{
	auto a = cast(const(R)*)aPtr;
	auto b = cast(const(R)*)bPtr;
	return b.h - a.h;
}

/**
Same as `pack`, but expects `rects` to be sorted by their height (tallest first) for some methods.
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
			case rows: return packRows(rects, width, height);
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
