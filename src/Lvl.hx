package;

import openfl.display.BitmapData;
import openfl.display.Bitmap;
import openfl.display.Tilemap;
import openfl.display.Tileset;
import openfl.display.Tile;
import openfl.geom.Rectangle;
import openfl.geom.Matrix;
import openfl.Assets;
import openfl.Lib;

typedef Tiles = { //tiles.json
	tsize: Int,
	scale: Int,
	layers: Array<Array<{id:Int}>>
}

typedef GameMap = { //map format
	w: Int,
	h: Int,
	layers: Array<Array<Array<Int>>>,
	objects: {
		player: {x:Int, y:Int}
	}
}

class Lvl {
	
	public static var tilemap:Tilemap;
	public static var origTileset:BitmapData;
	public static var origTsize:Int; //for rescaling
	public static var tiles:Array<Tile> = []; //all tiles
	public static var layersLength:Array<Int>;
	public static var layersNum:Int;
	public static var map:GameMap;
	
	public static var screen:Array<Array<Array<Tile>>> = [];
	public static var screenW = 0; //tiles on screen
	public static var screenH = 0;
	public static var tsize = 0; //tile size
	public static var scale = 0; //tile scale
	public static var camera = {
		x : 0.0, y : 0.0, //current
		sx : 0.0, sy : 0.0, //saved
	};
	
	public function new() {}
	
	public static function init():Void {
		initTiles();
		loadMap(1);
		
		resize();
	}
	
	private static function initTiles():Void {
		var stage = Lib.current.stage;
		var text = Assets.getText("res/tiles.json");
		var json:Tiles = haxe.Json.parse(text);
		var layers = json.layers;
		tsize = json.tsize;
		layersNum = layers.length;
		layersLength = [0];
		
		var tileNum = 0;
		for (l in layers) tileNum += l.length + 1;
		origTileset = new BitmapData(tileNum * tsize, tsize, true, 0x0);
		origTsize = tsize;
		var offx = 0;
		
		for (l in 0...layersNum) {
			var layer = layers[l];
			layersLength.push(layer.length + 1);
			offx += tsize; //first tile is empty
			
			for (tile in layer) {
				var bmd = Assets.getBitmapData("tiles/"+l+"/"+tile.id+".png");
				var mat = new Matrix();
				mat.translate(offx, 0);
				origTileset.draw(bmd, mat);
				offx += tsize;
			}
		}
		
		tilemap = new Tilemap(stage.stageWidth, stage.stageHeight, false);
		_rescale(json.scale);
		
		#if debug
		var bitmap = new Bitmap(origTileset);
		bitmap.alpha = 0.2;
		stage.addChild(bitmap);
		#end
	}
	
	private static function loadMap(id:Int):Void {
		var text = Assets.getText("maps/"+id+".json");
		map = haxe.Json.parse(text);
		
		tilemap.removeTiles();
		for (l in 0...layersNum) screen[l] = [];
	}
	
	public static function getTile(layer:Int, x:Int, y:Int):Int {
		if (x > -1 && y > -1 && x < map.w && y < map.h) {
			return map.layers[layer][y][x] + layersLength[layer];
		}
		return 0;
	}
	
	public static function setTile(layer:Int, id:Int, x:Int, y:Int):Void {
		if (x > -1 && y > -1 && x < map.w && y < map.h) {
			map.layers[layer][y][x] = id;
		}
	}
	
	public static function update(force=false):Void {
		if (camera.x == camera.sx && camera.y == camera.sy && !force) return;
		//camera in tiles
		var ctx = Std.int(camera.x/tsize);
		var cty = Std.int(camera.y/tsize);
		var offx = camera.x % tsize;
		var offy = camera.y % tsize;
		
		for (l in 0...layersNum)
			for (iy in 0...screenH)
				for (ix in 0...screenW) {
					var id = getTile(l, ix + ctx, iy + cty);
					
					screen[l][iy][ix].id = id;
					if (id == 0) screen[l][iy][ix].visible = false;
					else screen[l][iy][ix].visible = true;
					
					screen[l][iy][ix].x = ix*tsize - offx;
					screen[l][iy][ix].y = iy*tsize - offy;
				}
		
		camera.sx = camera.x;
		camera.sy = camera.y;
	}
	
	public static function resize():Void {
		var stage = Lib.current.stage;
		//new screen size in tiles
		var newW = Math.ceil(stage.stageWidth/tsize) + 1;
		var newH = Math.ceil(stage.stageHeight/tsize) + 1;
		//camera in tiles
		var ctx = Std.int(camera.x/tsize);
		var cty = Std.int(camera.y/tsize);
		var offx = camera.x % tsize;
		var offy = camera.y % tsize;
		
		if (newW > screenW) { //w++
			
			for (l in 0...layersNum)
			for (ix in screenW...newW)
				for (iy in 0...screenH) { //for old h
					var id = getTile(l, ix+ctx, iy+cty);
					
					screen[l][iy].push(new Tile(id, ix*tsize-offx, iy*tsize-offy));
					if (id == 0) screen[l][iy][ix].visible = false;
					
					tilemap.addTile(screen[l][iy][ix]); //iy*screenH+ix
				}
			
		} else if (newW < screenW) { //w--
			
			for (l in 0...layersNum)
			for (ix in newW...screenW)
				for (iy in 0...screenH) { //for old h
					tilemap.removeTile(screen[l][iy][ix]); //iy*screenH+newW
				}
			
			for (l in 0...layersNum)
			for (ix in newW...screenW)
				for (iy in 0...screenH) {
					screen[l][iy].pop();
				}
		}
		
		if (newH > screenH) { //h++
			
			for (l in 0...layersNum)
			for (iy in screenH...newH) {
				screen[l].push([]);
				for (ix in 0...newW) {
					var id = getTile(l, ix+ctx, iy+cty);
					
					screen[l][iy].push(new Tile(id, ix*tsize-offx, iy*tsize-offy));
					if (id == 0) screen[l][iy][ix].visible = false;
					
					tilemap.addTile(screen[l][iy][ix]); //iy*newW+ix
				}
			}
			
		} else if (newH < screenH) { //h--
			
			for (l in 0...layersNum)
			for (iy in newH...screenH)
				for (ix in 0...newW) {
					tilemap.removeTile(screen[l][iy][ix]); //iy*newH
				}
			
			for (l in 0...layersNum)
			for (iy in newH...screenH) screen[l].pop();
		}
		
		screenW = newW;
		screenH = newH;
		tilemap.width = stage.stageWidth;
		tilemap.height = stage.stageHeight;
		
		#if debug
		trace(screen[0][0].length*screen[0].length, screenW*screenH, tilemap.numTiles);
		#end
	}
	
	private static function _rescale(scale:Int):Void {
		var tileNum = Std.int(origTileset.width / origTsize);
		trace(tileNum);
		tsize = origTsize * scale;
		Lvl.scale = scale;
		
		var bmdset = new BitmapData(tileNum * tsize, tsize, true, 0x0);
		var mat = new Matrix();
		mat.scale(scale, scale);
		bmdset.draw(origTileset, mat);
		
		var rects = [];
		for (i in 0...tileNum) {
			rects.push(new Rectangle(i * tsize, 0, tsize, tsize));
		}
		tilemap.tileset = new Tileset(bmdset, rects);
	}
	
	public static function rescale(scale:Int):Void {
		_rescale(scale);
		
		tilemap.removeTiles();
		for (l in 0...layersNum) screen[l] = [];
		screenW = 0;
		screenH = 0;
		
		resize();
		update(true);
	}
}
