package;

import openfl.display.StageScaleMode;
import openfl.events.ProgressEvent;
import openfl.events.Event;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFormat;
import openfl.text.TextField;
import openfl.Lib;

class Loader extends Screen {
	
	public static var loadText:TextField;
	
	public function new() {
		super();
	}
	
	public function preload():Void {
		var stage = Lib.current.stage;
		stage.scaleMode = StageScaleMode.NO_SCALE;
		loadText = loading();
		addChild(loadText);
		
		stage.addEventListener(ProgressEvent.PROGRESS, onProgress);
		stage.addEventListener(Event.COMPLETE, onComplete);
	}
	
	private static function loading():TextField {
		var stage = Lib.current.stage;
		var text = new TextField();
		text.defaultTextFormat = new TextFormat("_sans", 50, 0x888888);
		text.autoSize = TextFieldAutoSize.LEFT;
		text.text = "Loading...";
		text.x = stage.stageWidth/2 - text.width/2;
		text.y = stage.stageHeight/2 - text.height/2;
		return text;
	}
	
	private function onProgress(e:ProgressEvent):Void {
		var percent = e.bytesLoaded / e.bytesTotal;
		loadText.alpha = 1 - percent;
	}
	
	private function onComplete(e:Event):Void {
		trace('loading comlete');
		stage.removeEventListener(ProgressEvent.PROGRESS, onProgress);
		stage.removeEventListener(Event.COMPLETE, onComplete);
		
		var game = new Game();
		game.show();
	}
}
