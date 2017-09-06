package;

import openfl.events.Event;
import openfl.ui.Keyboard;
import openfl.Lib;

class Game extends Screen {
	
	var lvl:Lvl;
	
	public function new() {
		super();
	}
	
	public function init():Void {
		lvl = new Lvl();
		lvl.init();
		addChild(lvl.tilemap);
	}
	
	override function onResize():Void {
		lvl.resize();
	}
	
	override function onKeyDown(key:Int):Void {
		var k = Keyboard;
		
		if (key == k.NUMBER_0) {
			lvl.rescale(1);
		} else if (key == k.MINUS || key == 173) {
			if (lvl.scale > 1) lvl.rescale(lvl.scale - 1);
		} else if (key == k.EQUAL) {
			if (lvl.scale < 9) lvl.rescale(lvl.scale + 1);
		}
	}
	
	override function onEnterFrame(e:Event):Void {
		var k = Keyboard;
		var sx = 0, sy = 0;
		
		if (keys[k.LEFT] || keys[k.A]) sx -= 5;
		if (keys[k.RIGHT] || keys[k.D]) sx += 5;
		if (keys[k.UP] || keys[k.W]) sy -= 5;
		if (keys[k.DOWN] || keys[k.S]) sy += 5;
		if (keys[k.SHIFT]) {
			sx *= 2; sy *= 2;
		}
		
		if (sx != 0) lvl.camera.x += sx;
		if (sy != 0) lvl.camera.y += sy;
		
		lvl.update();
	}
}
