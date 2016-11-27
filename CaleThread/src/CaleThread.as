package
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.system.MessageChannel;
	import flash.system.Worker;
	import flash.utils.getTimer;
	
	import deltax.worker.CMDKeys;
	import deltax.worker.MsgChannelKey;
	
	public class CaleThread extends Sprite
	{
		private var _msgToCaleThread:MessageChannel;
		private var _msgToMainThread:MessageChannel;
		
		private var _preFrameTime:uint;
		
		public function CaleThread()
		{
			this._msgToCaleThread = Worker.current.getSharedProperty(MsgChannelKey.MAIN_TO_CALE) as MessageChannel;
			this._msgToMainThread = Worker.current.getSharedProperty(MsgChannelKey.CALE_TO_MAIN) as MessageChannel;
			
			this._msgToCaleThread.addEventListener(Event.CHANNEL_MESSAGE,reciveMsgHandler);
			
			if(stage)
			{
				onStageHandler();
			}else
			{
				this.addEventListener(Event.ADDED_TO_STAGE,onStageHandler);
			}
		}
		
		private function onStageHandler(evt:Event=null):void
		{
			this.removeEventListener(Event.ADDED_TO_STAGE,onStageHandler);
			
			this.stage.frameRate = 60;
			this.addEventListener(Event.ENTER_FRAME,onEnterFrameHandler);
		}
		
		private function onEnterFrameHandler(evt:Event):void
		{
			var curTime:uint = getTimer();
//			trace("CALE_THREAD_FRAME_INTERVAL=====",curTime - _preFrameTime);
			_preFrameTime = curTime;
//			if(curTime - _preFrameTime>1000)
//			{
//				sendMsgToMainThread("MSG_INTERVAL",curTime);
//				_preFrameTime = curTime;
//			}
		}
		
		private function reciveMsgHandler(evt:Event):void
		{
			var arr:Array = this._msgToCaleThread.receive();
			var cmd:String = arr[0];
			switch(cmd)
			{
				case CMDKeys.TEST:
					trace(arr[1]);
					sendMsgToMainThread(CMDKeys.TEST,"cale thread is all ready!!");
					break;
			}
		}
		
		public function sendMsgToMainThread(cmd:String,value:*):void
		{
			var arr:Array=[cmd,value];
			this._msgToMainThread.send(arr);
		}
	}
}