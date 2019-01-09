package amqp;

import js.Promise;
import haxe.extern.EitherType;

class Amqp
{
	/*
	 * Connect to an AMQP 0-9-1 server, optionally given an AMQP URL (see AMQP URI syntax) and socket options. The protocol part (amqp: or amqps:) is mandatory; defaults for elided parts are as given in 'amqp://guest:guest@localhost:5672'. If the URI is omitted entirely, it will default to 'amqp://localhost', which given the defaults for missing parts, will connect to a RabbitMQ installation with factory settings, on localhost.
	 */
	static inline public function connectCallback(url:AmqpUrl, ?options:{}, ?callback:AmqpError->AmqpConnection->Void):Void
	{
		AmqpCallback.connect(url, options, callback);
	}
}

/**
 * ...
 * @author Thomas Byrne
 */
#if nodejs
@:jsRequire('amqplib/callback_api')
#else
@:native('amqplib/callback_api')
#end

extern private class AmqpCallback {
	public static function connect(url:AmqpUrl, ?options:{}, ?callback:AmqpError->AmqpConnection->Void):Void;
}

typedef AmqpUrl = EitherType < String, {
	?protocol: String,
	hostname: String,
	?port: Int,
	?username: String,
	?password: String,
	?locale: String,		// the desired locale for error messages, I suppose. RabbitMQ only ever uses en_US; which, happily, is the default.
	?frameMax: Int,			// the size in bytes of the maximum frame allowed over the connection. 0 means no limit (but since frames have a size field which is an unsigned 32 bit integer, it’s perforce 2^32 - 1); I default it to 0x1000, i.e. 4kb, which is the allowed minimum, will fit many purposes, and not chug through Node.JS’s buffer pooling.
	?channelMax: Int,		// the maximum number of channels allowed. Default is 0, meaning 2^16 - 1.
	?heartbeat: Int,		// the period of the connection heartbeat, in seconds. Defaults to 0
	?vhost: String,			// For convenience, an absent path segment (e.g., as in the URLs just given) is interpreted as the virtual host named /, which is present in RabbitMQ out of the box. Per the URI specification, just a trailing slash as in 'amqp://localhost/' would indicate the virtual host with an empty name, which does not exist unless it’s been explicitly created. When specifying another virtual host, remember that its name must be escaped; so e.g., the virtual host named /foo is '%2Ffoo'; in a full URI, 'amqp://localhost/%2Ffoo'.
}>;