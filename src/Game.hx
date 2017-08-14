package;

import openfl.events.Event;
import openfl.ui.Keyboard;
import openfl.Lib;

class Game extends Screen {
	
	public function new() {
		super();
		init();
	}
	
	private function init():Void {
		Lvl.init();
		addChild(Lvl.tilemap);
	}
	
	private override function onResize():Void {
		Lvl.resize();
	}
	
	override function onKeyDown(key:Int):Void {
		var k = Keyboard;
		
		if (key == k.MINUS || key == 173) {
			if (Lvl.scale > 1) Lvl.rescale(Lvl.scale - 1);
		} else if (key == k.EQUAL) {
			if (Lvl.scale < 9) Lvl.rescale(Lvl.scale + 1);
		}
	}
	
	private override function onEnterFrame(e:Event):Void {
		var k = Keyboard;
		
		if (keys[k.LEFT] || keys[k.A]) Lvl.camera.x -= 5;
		if (keys[k.RIGHT] || keys[k.D]) Lvl.camera.x += 5;
		if (keys[k.UP] || keys[k.W]) Lvl.camera.y -= 5;
		if (keys[k.DOWN] || keys[k.S]) Lvl.camera.y += 5;
		
		Lvl.update();
	}
}
