package;

import openfl.display.Sprite;

class Main extends Sprite {
	
	private static var loader:Loader;
	
	public function new() {
		super();
		init();
	}
	
	private function init():Void {
		if (loader == null) {
			loader = new Loader();
			loader.show();
			loader.preload();
		}
	}
	
}
