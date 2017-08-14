package;

import haxe.Timer;
import openfl.events.Event;
import openfl.system.System;
import openfl.text.TextField;
import openfl.text.TextFormat;

/*
* http://haxecoder.com/post.php?id=24
* @author Kirill Poletaev
*/

class FPS_Mem extends TextField {
	var times:Array<Float>;
	var memPeak = 0.0;
	
	public function new(x=10.0, y=10.0, color:Int = 0x888888) {
		super();
		this.x = x;
		this.y = y;
		width = 150;
		height = 50;
		selectable = false;
		defaultTextFormat = new TextFormat("_sans", 12, color);
		
		times = [];
		addEventListener(Event.ENTER_FRAME, onEnterFrame);
	}
	
	function onEnterFrame(e:Event):Void {
		var now = Timer.stamp();
		times.push(now);
		while (times[0] < now - 1) times.shift();
		
		var mem:Float = Math.round(System.totalMemory / 1024 / 1024 * 100)/100;
		if (mem > memPeak) memPeak = mem;
		if (visible) {
			text = "FPS: " + times.length + "\nMEM: " + mem + " MB\nMEM peak: " + memPeak + " MB";
		}
	}
	
}
