package;

import openfl.display.BitmapData;
import openfl.display.Bitmap;
import openfl.display.Sprite;
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
	
	#if debug public static var debug = new Sprite(); #end
	public static var tilemap:Tilemap;
	public static var origTileset:BitmapData;
	public static var origTsize:Int; //for rescaling
	public static var layersLength:Array<Int>;
	public static var layersNum:Int;
	public static var map:GameMap;
	
	public static var tiles:Array<Array<Array<Tile>>> = [];
	public static var tilesW = 0; //tiles viewport
	public static var tilesH = 0;
	public static var screenW = 0; //size in tiles
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
		
		#if debug
		Lib.current.stage.addChild(debug);
		#end
	}
	
	private static function initTiles():Void {
		var stage = Lib.current.stage;
		var text = Assets.getText("res/tiles.json");
		var json:Tiles = haxe.Json.parse(text);
		var layers = json.layers;
		tsize = json.tsize;
		layersNum = layers.length;
		layersLength = [0];
		
		var tileNum = 1;
		for (l in layers) tileNum += l.length;
		origTileset = new BitmapData(tileNum * tsize, tsize, true, 0x0);
		origTsize = tsize;
		var offx = tsize;
		
		for (l in 0...layersNum) {
			var layer = layers[l];
			layersLength.push(layer.length);
			
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
		debug.addChild(bitmap);
		#end
	}
	
	private static function loadMap(id:Int):Void {
		var text = Assets.getText("maps/"+id+".json");
		map = haxe.Json.parse(text);
		
		tilemap.removeTiles();
		for (l in 0...layersNum) tiles[l] = [];
	}
	
	public static function getTile(layer:Int, x:Int, y:Int):Int {
		if (x > -1 && y > -1 && x < map.w && y < map.h) {
			var id = map.layers[layer][y][x];
			return id == 0 ? 0 : id + layersLength[layer];
		}
		return 0;
	}
	
	public static function setTile(layer:Int, id:Int, x:Int, y:Int):Void {
		if (x > -1 && y > -1 && x < map.w && y < map.h) {
			map.layers[layer][y][x] = id + layersLength[layer];
		}
	}
	
	public static function update(force=false):Void {
		if (camera.x == camera.sx && camera.y == camera.sy && !force) return;
		//camera in tiles
		var ctx = Std.int(camera.x/tsize);
		var cty = Std.int(camera.y/tsize);
		var offx = camera.x % tsize;
		var offy = camera.y % tsize;
		
		//tiles offset
		var tx = -ctx < 1 ? 0 : -ctx-1;
		var ty = -cty < 1 ? 0 : -cty-1;
		if (tx > screenW-tilesW) tx = screenW-tilesW;
		if (ty > screenH-tilesH) ty = screenH-tilesH;
		
		for (l in 0...layersNum)
			for (iy in 0...tilesH)
				for (ix in 0...tilesW) {
					var id = getTile(l, ix+tx + ctx, iy+ty + cty);
					
					if (id == 0) tiles[l][iy][ix].visible = false;
					else {
						tiles[l][iy][ix].id = id;
						tiles[l][iy][ix].visible = true;
						tiles[l][iy][ix].x = (ix+tx)*tsize - offx;
						tiles[l][iy][ix].y = (iy+ty)*tsize - offy;
					}
				}
		
		camera.sx = camera.x;
		camera.sy = camera.y;
	}
	
	public static function resize():Void {
		var stage = Lib.current.stage; //fix camera resize
		//new screen size in tiles
		screenW = Math.ceil(stage.stageWidth/tsize) + 1;
		screenH = Math.ceil(stage.stageHeight/tsize) + 1;
		//set viewport
		var newW = screenW > map.w ? map.w + 1 : screenW;
		var newH = screenH > map.h ? map.h + 1 : screenH;
		//camera in tiles
		var ctx = Std.int(camera.x/tsize);
		var cty = Std.int(camera.y/tsize);
		var offx = camera.x % tsize;
		var offy = camera.y % tsize;
		
		if (newW > tilesW) { //w++
			
			for (l in 0...layersNum)
			for (ix in tilesW...newW)
				for (iy in 0...tilesH) { //for old h
					var id = getTile(l, ix+ctx, iy+cty);
					
					tiles[l][iy].push(new Tile(id, ix*tsize-offx, iy*tsize-offy));
					if (id == 0) tiles[l][iy][ix].visible = false;
					
					tilemap.addTile(tiles[l][iy][ix]);
				}
			
		} else if (newW < tilesW) { //w--
			
			for (l in 0...layersNum)
			for (ix in newW...tilesW)
				for (iy in 0...tilesH) { //for old h
					tilemap.removeTile(tiles[l][iy][ix]);
				}
			
			for (l in 0...layersNum)
			for (ix in newW...tilesW)
				for (iy in 0...tilesH) {
					tiles[l][iy].pop();
				}
		}
		
		if (newH > tilesH) { //h++
			
			for (l in 0...layersNum)
			for (iy in tilesH...newH) {
				tiles[l].push([]);
				for (ix in 0...newW) {
					var id = getTile(l, ix+ctx, iy+cty);
					
					tiles[l][iy].push(new Tile(id, ix*tsize-offx, iy*tsize-offy));
					if (id == 0) tiles[l][iy][ix].visible = false;
					
					tilemap.addTile(tiles[l][iy][ix]);
				}
			}
			
		} else if (newH < tilesH) { //h--
			
			for (l in 0...layersNum)
			for (iy in newH...tilesH)
				for (ix in 0...newW) {
					tilemap.removeTile(tiles[l][iy][ix]);
				}
			
			for (l in 0...layersNum)
			for (iy in newH...tilesH) tiles[l].pop();
		}
		
		tilesW = newW;
		tilesH = newH;
		tilemap.width = stage.stageWidth;
		tilemap.height = stage.stageHeight;
		
		#if debug
		/*debug.graphics.clear();
		debug.graphics.lineStyle(1, 0xf00000);
		debug.graphics.drawRect(-camera.x, -camera.y, (newW-2)*tsize, (newH-2)*tsize);*/
		trace(tiles[0][0].length*tiles[0].length*layersNum,
			tilesW*tilesH*layersNum, tilemap.numTiles);
		#end
	}
	
	private static function _rescale(scale:Int):Void {
		var tileNum = Std.int(origTileset.width / origTsize);
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
		for (l in 0...layersNum) tiles[l] = [];
		tilesW = 0;
		tilesH = 0;
		
		resize();
		update(true);
	}
}
