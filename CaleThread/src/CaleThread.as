package
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.net.URLLoaderDataFormat;
	import flash.system.MessageChannel;
	import flash.system.Worker;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.Endian;
	import flash.utils.getTimer;
	
	import deltax.common.respackage.common.LoaderCommon;
	import deltax.common.respackage.loader.LoaderManager;
	import deltax.worker.CMDKeys;
	import deltax.worker.MsgChannelKey;
	
	public class CaleThread extends Sprite
	{
		private var _msgToCaleThread:MessageChannel;
		private var _msgToMainThread:MessageChannel;
		
		private var _preFrameTime:uint;
		
		private var _animationMap:Dictionary = new Dictionary(true);
		
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
//				case CMDKeys.PARSE_DATA_NOTICE:
//					var key:String = arr[1];
//					var data:ByteArray = Worker.current.getSharedProperty(CMDKeys.SHARE_DATA) as ByteArray;
//					data.endian = Endian.LITTLE_ENDIAN;
//					data.position = 0;
//					_animationMap[key] = parseData(data);
//					sendMsgToMainThread(CMDKeys.SHARE_DATA_CLEAR,key);
//					break;
				case "test":
					LoaderManager.getInstance().load("assets/config/tableData.pak",{onComplete:onFinished},LoaderCommon.LOADER_URL, false, {dataFormat:URLLoaderDataFormat.BINARY});
					break;
			}
		}
		
		private function onFinished(param:Object):void
		{
			trace("cale load success======================");
			sendMsgToMainThread("test","ppppp");
		}
		
		private function parseData(data:ByteArray):Array
		{
			var qx:Number;
			var qy:Number;
			var qz:Number;
			var qw:Number;
			var tx:Number;
			var ty:Number;
			var tz:Number;
			var frameNum:uint = data.readUnsignedInt();
			data.position = 8;
			var jointsNum:uint = data.readUnsignedInt();
			var length:uint = frameNum * jointsNum * 64;
			var frameMatByte:ByteArray = new ByteArray();
			frameMatByte.length = length;
			var localMatByte:ByteArray = new ByteArray();
			localMatByte.length = length;
			for(var i:uint = 0;i<frameNum;i++)
			{
				for(var j:uint = 0;j<jointsNum;j++)
				{
					qx = data.readFloat();
					qy = data.readFloat();
					qz = data.readFloat();
					qw = data.readFloat();
					tx = data.readFloat();
					ty = data.readFloat();
					tz = data.readFloat();
					frameMatByte.writeFloat((1-(qy * qy+qz * qz) * 2));
					frameMatByte.writeFloat(((qx * qy +qw * qz) * 2));
					frameMatByte.writeFloat(((qx * qz - qw * qy)*2));
					frameMatByte.writeFloat(0);
					
					frameMatByte.writeFloat(((qx*qy-qw*qz)*2));
					frameMatByte.writeFloat((1-((qx*qx+qz*qz)*2)));
					frameMatByte.writeFloat((qy*qz+qw*qx)*2);
					frameMatByte.writeFloat(0);
					
					frameMatByte.writeFloat(((qx*qz+qw*qy)*2));
					frameMatByte.writeFloat((qy*qz-qw*qx)*2);
					frameMatByte.writeFloat((1-((qx*qx+qy*qy)*2)));
					frameMatByte.writeFloat(0);
					
					frameMatByte.writeFloat(tx);
					frameMatByte.writeFloat(ty);
					frameMatByte.writeFloat(tz);
					frameMatByte.writeFloat(1);
					
					qx = data.readFloat();
					qy = data.readFloat();
					qz = data.readFloat();
					qw = data.readFloat();
					tx = data.readFloat();
					ty = data.readFloat();
					tz = data.readFloat();
					localMatByte.writeFloat((1-(qy * qy+qz * qz) * 2));
					localMatByte.writeFloat(((qx * qy +qw * qz) * 2));
					localMatByte.writeFloat(((qx * qz - qw * qy)*2));
					localMatByte.writeFloat(0);
					
					localMatByte.writeFloat(((qx*qy-qw*qz)*2));
					localMatByte.writeFloat((1-((qx*qx+qz*qz)*2)));
					localMatByte.writeFloat((qy*qz+qw*qx)*2);
					localMatByte.writeFloat(0);
					
					localMatByte.writeFloat(((qx*qz+qw*qy)*2));
					localMatByte.writeFloat((qy*qz-qw*qx)*2);
					localMatByte.writeFloat((1-((qx*qx+qy*qy)*2)));
					localMatByte.writeFloat(0);
					
					localMatByte.writeFloat(tx);
					localMatByte.writeFloat(ty);
					localMatByte.writeFloat(tz);
					localMatByte.writeFloat(1);
				}
			}
			return [frameMatByte,localMatByte];
		}
		
		public function sendMsgToMainThread(cmd:String,value:*):void
		{
			var arr:Array=[cmd,value];
			this._msgToMainThread.send(arr);
		}
	}
}