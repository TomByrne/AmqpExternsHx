package amqp;

import haxe.extern.EitherType;

/**
 * http://www.squaremobius.net/amqp.node/channel_api.html
 * 
 * @author Thomas Byrne
 */

extern class AmqpChannel extends AmqpChannelBase
{
	/*
	 * publish mimics the stream.Writable interface in its return value; it will return false if the channel’s write buffer is ‘full’, and true otherwise. If it returns false, it will emit a 'drain' event at some later time.
	 */
	function publish(exchange:String, routingKey:String, content:AmqpBuffer, ?options:AmqpPublishOptions):Bool;
	
	/*
	 * Send a single message with the content given as a buffer to the specific queue named, bypassing routing. The options and return value are exactly the same as for #publish.
	 */
	function sendToQueue(queue:String, content:AmqpBuffer, ?options:{}):Bool;
}

extern class AmqpChannelBase 
{
	/**
	 * Close a channel. Will be resolved with no value once the closing handshake is complete.

There’s not usually any reason to close a channel rather than continuing to use it until you’re ready to close the connection altogether. However, the lifetimes of consumers are scoped to channels, and thereby other things such as exclusive locks on queues, so it is occasionally worth being deliberate about opening and closing channels.
	 */
	function close(?callback:(AmqpError->Void)):Void;
	function on(event:AmqpChannelEvents, ?callback:(Void->Void)):Void;
	
	
	////////////////////////               QUEUES
	/**
	 * Assert a queue into existence. This operation is idempotent given identical arguments; however, it will bork the channel if the queue already exists but has different properties (values supplied in the arguments field may or may not count for borking purposes; check the borker’s, I mean broker’s, documentation).
	 * queue is a string; if you supply an empty string or other falsey value (including null and undefined), the server will create a random name for you.
	 */
	function assertQueue(?queue:String, ?options:AmpqAssertQueueOptions, ?callback:(AmqpError->AmqpQueueState-> Void)):Void;
	/**
	 * Check whether a queue exists. This will bork the channel if the named queue doesn’t exist; if it does exist, you go through to the next round! There’s no options, unlike #assertQueue(), just the queue name. The reply from the server is the same as for #assertQueue().
	 */
	function checkQueue(queue:String, ?callback:(AmqpError->AmqpQueueState-> Void)):Void;
	/**
	 * Delete the queue named. Naming a queue that doesn’t exist will result in the server closing the channel, to teach you a lesson (except in RabbitMQ version 3.2.0 and after1).
	 * You should leave out the options altogether if you want to delete the queue unconditionally.
	 * The server reply contains a single field, messageCount, with the number of messages deleted or dead-lettered along with the queue.
	 */
	function deleteQueue(queue:String, ?options:AmpqDeleteQueueOptions, ?callback:(AmqpError->AmqpRemoveResult->Void)):Void;
	/**
	 * Remove all undelivered messages from the queue named. Note that this won’t remove messages that have been delivered but not yet acknowledged; they will remain, and may be requeued under some circumstances (e.g., if the channel to which they were delivered closes without acknowledging them).
	 */
	function purgeQueue(queue:String, ?callback:(AmqpError->AmqpRemoveResult->Void)):Void;
	/**
	 * Assert a routing path from an exchange to a queue: the exchange named by source will relay messages to the queue named, according to the type of the exchange and the pattern given. The RabbitMQ tutorials give a good account of how routing works in AMQP.
	 * 'args' is an object containing extra arguments that may be required for the particular exchange type (for which, see your server’s documentation). It may be omitted if it’s the last argument, which is equivalent to an empty object.
	 */
	function bindQueue(queue:String, source:String, pattern:String, ?args:{}, ?callback:(AmqpError->{}->Void)):Void;
	/**
	 * Remove a routing path between the queue named and the exchange named as source with the pattern and arguments given. Omitting args is equivalent to supplying an empty object (no arguments). Beware: attempting to unbind when there is no such binding may result in a punitive error (the AMQP specification says it’s a connection-killing mistake; RabbitMQ before version 3.2.0 softens this to a channel error, and from version 3.2.0, doesn’t treat it as an error at all1. Good ol’ RabbitMQ).
	 */
	function unbindQueue(queue:String, source:String, pattern:String, ?args:{}, ?callback:(AmqpError->{}->Void)):Void;
	
	
	
	////////////////////////               EXCHANGES
	/**
	 * Assert an exchange into existence. As with queues, if the exchange exists already and has properties different to those supplied, the channel will ‘splode; fields in the arguments object may or may not be ‘splodey, depending on the type of exchange. Unlike queues, you must supply a name, and it can’t be the empty string. You must also supply an exchange type, which determines how messages will be routed through the exchange.
	 * NB There is just one RabbitMQ extension pertaining to exchanges in general (alternateExchange); however, specific exchange types may use the arguments table to supply parameters.
	 */
	function assertExchange(exchange:String, type:String, ?options:AmpqAssertExchangeOptions, ?callback:(AmqpError->{exchange:String}->Void)):Void;
	/**
	 * Check that an exchange exists. If it doesn’t exist, the channel will be closed with an error. If it does exist, happy days.
	 */
	function checkExchange(exchange:String, ?callback:(AmqpError->AmqpExchangeState-> Void)):Void;
	
	/**
	 * Delete an exchange.
	 * If the exchange does not exist, a channel error is raised (RabbitMQ version 3.2.0 and after will not raise an error).
	 */
	function deleteExchange(exchange:String, ?options:AmpqDeleteExchangeOptions, ?callback:(AmqpError->{}->Void)):Void;
	
	/**
	 * Bind an exchange to another exchange. The exchange named by destination will receive messages from the exchange named by source, according to the type of the source and the pattern given. For example, a direct exchange will relay messages that have a routing key equal to the pattern.
	 * NB Exchange to exchange binding is a RabbitMQ extension.
	 */
	function bindExchange(destination:String, source:String, pattern:String, ?args:{}, ?callback:(AmqpError->{}->Void)):Void;
	
	/**
	 * Remove a binding from an exchange to another exchange. A binding with the exact source exchange, destination exchange, routing key pattern, and extension args will be removed. If no such binding exists, it’s – you guessed it – a channel error, except in RabbitMQ >= version 3.2.0, for which it succeeds trivially.
	 */
	function unbindExchange(destination:String, source:String, pattern:String, ?args:{}, ?callback:(AmqpError->{}->Void)):Void;
	
	
	////////////////////////               MESSAGING
	/*
	 * Set up a consumer with a callback to be invoked with each message.
	 */
	function consume(queue:String, callback:AmqpMsg->Void, ?options:AmqpConsumeOptions, ?callback:AmqpError->{consumerTag:String}->Void):Void;
	
	/*
	 * Ask a queue for a message, as an RPC. This will be resolved with either false, if there is no message to be had (the queue has no messages ready), or a message in the same shape as detailed in #consume.
	 */
	function cancel(consumerTag:String, callback:AmqpError->{}->Void):Void;
	
	/*
	 * This instructs the server to stop sending messages to the consumer identified by consumerTag. Messages may arrive between sending this and getting its reply; once the reply has resolved, however, there will be no more messages for the consumer, i.e., the message callback will no longer be invoked.
	 * The consumerTag is the string given in the reply to #consume, which may have been generated by the server.
	 */
	function get(queue:String, ?options:AmqpGetOptions, callback:AmqpError->EitherType<Bool, AmqpMsg>->Void):Void;
	
	/*
	 * Acknowledge the given message, or all messages up to and including the given message.
	 * If a #consume or #get is issued with noAck: false (the default), the server will expect acknowledgements for messages before forgetting about them. If no such acknowledgement is given, those messages may be requeued once the channel is closed.
	 * If allUpTo is true, all outstanding messages prior to and including the given message shall be considered acknowledged. If false, or omitted, only the message supplied is acknowledged.
	 * It’s an error to supply a message that either doesn’t require acknowledgement, or has already been acknowledged. Doing so will errorise the channel. If you want to acknowledge all the messages and you don’t have a specific message around, use #ackAll.
	 */
	function ack(message:Dynamic, ?allUpTo:Bool):Void;
	
	/*
	 * Acknowledge all outstanding messages on the channel. This is a “safe” operation, in that it won’t result in an error even if there are no such messages.
	 */
	function ackAll():Void;
	
	/*
	 * Reject a message. This instructs the server to either requeue the message or throw it away (which may result in it being dead-lettered).
	 * If allUpTo is truthy, all outstanding messages prior to and including the given message are rejected. As with #ack, it’s a channel-ganking error to use a message that is not outstanding. Defaults to false.
	 * If requeue is truthy, the server will try to put the message or messages back on the queue or queues from which they came. Defaults to true if not given, so if you want to make sure messages are dead-lettered or discarded, supply false here.
	 * This and #nackAll use a RabbitMQ-specific extension.
	 */
	function nack(message:Dynamic, ?allUpTo:Bool, ?requeue:Bool):Void;
	
	/*
	 * Reject all messages outstanding on this channel. If requeue is truthy, or omitted, the server will try to re-enqueue the messages.
	 */
	function nackAll():Void;
	
	/*
	 * Reject a message. Equivalent to #nack(message, false, requeue), but works in older versions of RabbitMQ (< v2.3.0) where #nack does not.
	 */
	function reject(message:Dynamic, ?requeue:Bool):Void;
	
	/*
	 * Set the prefetch count for this channel. The count given is the maximum number of messages sent over the channel that can be awaiting acknowledgement; once there are count messages outstanding, the server will not send more messages on this channel until one or more have been acknowledged. A falsey value for count indicates no such limit.
	 * NB RabbitMQ v3.3.0 changes the meaning of prefetch (basic.qos) to apply per-consumer, rather than per-channel. It will apply to consumers started after the method is called. See rabbitmq-prefetch.
	 * Use the global flag to get the per-channel behaviour. To keep life interesting, using the global flag with an RabbitMQ older than v3.3.0 will bring down the whole connection.
	 */
	function prefetch(message:Dynamic, ?requeue:Bool):Void;
	
	/*
	 * Requeue unacknowledged messages on this channel. The server will reply (with an empty object) once all messages are requeued.
	 */
	function recover(callback:AmqpError->{}->Void):Void;
}

@:enum abstract AmqpChannelEvents(String){
	/**
	 * A channel will emit 'close' once the closing handshake (possibly initiated by #close()) has completed; or, if its connection closes.
	 */
	var close = 'close';
	/**
	 * A channel will emit 'error' if the server closes the channel for any reason. Such reasons include
	 * - an operation failed due to a failed precondition (usually something named in an argument not existing)
	 * - an human closed the channel with an admin tool
	 */
	var error = 'error';
	/**
	 * If a message is published with the mandatory flag (it’s an option to Channel#publish in this API), it may be returned to the sending channel if it cannot be routed. Whenever this happens, the channel will emit return with a message object (as described in #consume) as an argument.
	 */
	var return_ = 'return';
	/**
	 * Like a stream.Writable, a channel will emit 'drain', if it has previously returned false from #publish or #sendToQueue, once its write buffer has been emptied (i.e., once it is ready for writes again).
	 */
	var drain = 'drain';
}

@:noCompletion
typedef AmpqAssertQueueOptions =
{
	?exclusive:Bool,			// if true, scopes the queue to the connection (defaults to false)
	?durable:Bool,				// if true, the queue will survive broker restarts, modulo the effects of exclusive and autoDelete; this defaults to true if not supplied, unlike the others
	?autoDelete:Bool,			// if true, the queue will be deleted when the number of consumers drops to zero (defaults to false)
	?arguments:Dynamic,			// additional arguments, usually parameters for some kind of broker-specific extension e.g., high availability, TTL
	?messageTtl:Int,			// (0 <= n < 2^32): expires messages arriving in the queue after n milliseconds
	?expires:Int,				// (0 < n < 2^32): the queue will be destroyed after n milliseconds of disuse, where use means having consumers, being declared (asserted or checked, in this API), or being polled with a #get
	?deadLetterExchange:String,	// an exchange to which messages discarded from the queue will be resent. Use deadLetterRoutingKey to set a routing key for discarded messages; otherwise, the message’s routing key (and CC and BCC, if present) will be preserved. A message is discarded when it expires or is rejected or nacked, or the queue limit is reached.
	maxLength:UInt,				// sets a maximum number of messages the queue will hold. Old messages will be discarded (dead-lettered if that’s set) to make way for new messages.
	maxPriority:UInt,			// makes the queue a priority queue.
}

@:noCompletion
typedef AmpqDeleteQueueOptions =
{
	?ifUnused:Bool,				// if true and the queue has consumers, it will not be deleted and the channel will be closed. Defaults to false.
	?ifEmpty:Bool,				// if true and the queue contains messages, the queue will not be deleted and the channel will be closed. Defaults to false.
}

@:noCompletion
typedef AmpqAssertExchangeOptions =
{
	?durable:Bool,				// if true, the exchange will survive broker restarts. Defaults to true.
	?internal:Bool,				// if true, messages cannot be published directly to the exchange (i.e., it can only be the target of bindings, or possibly create messages ex-nihilo). Defaults to false.
	?autoDelete:Bool,			// if true, the exchange will be destroyed once the number of bindings for which it is the source drop to zero. Defaults to false.
	?alternateExchange:String,	// an exchange to send messages to if this exchange can’t route them to any queues.
	?arguments:Dynamic,			// any additional arguments that may be needed by an exchange type.
}

@:noCompletion
typedef AmpqDeleteExchangeOptions =
{
	?ifUnused:Bool,				// if true and the exchange has bindings, it will not be deleted and the channel will be closed.
}

@:noCompletion
typedef AmqpQueueState =
{
	queue: String,
	messageCount: UInt,
	consumerCount: UInt,
}

@:noCompletion
typedef AmqpExchangeState =
{
	// ???
}

@:noCompletion
typedef AmqpRemoveResult =
{
	messageCount: UInt,		// the number of messages deleted or dead-lettered along with the queue.
}

@:noCompletion
typedef AmqpPublishOptions =
{
	?expiration:String,						// if supplied, the message will be discarded from a queue once it’s been there longer than the given number of milliseconds. In the specification this is a string; numbers supplied here will be coerced to strings for transit.
	?userId:String,							// If supplied, RabbitMQ will compare it to the username supplied when opening the connection, and reject messages for which it does not match.
	?CC:EitherType<String, Array<String>>,	// an array of routing keys as strings; messages will be routed to these routing keys in addition to that given as the routingKey parameter. A string will be implicitly treated as an array containing just that string. This will override any value given for CC in the headers parameter. NB The property names CC and BCC are case-sensitive.
	?priority:UInt,							// a priority for the message; ignored by versions of RabbitMQ older than 3.5.0, or if the queue is not a priority queue (see maxPriority above).
	?persistent:Bool, 						// If truthy, the message will survive broker restarts provided it’s in a queue that also survives restarts. Corresponds to, and overrides, the property deliveryMode.
	?deliveryMode:EitherType<UInt, Bool>,	// Either 1 or falsey, meaning non-persistent; or, 2 or truthy, meaning persistent. That’s just obscure though. Use the option persistent instead.
	
	//Used by RabbitMQ but not sent on to consumers:
	?mandatory:Bool,						// if true, the message will be returned if it is not routed to a queue (i.e., if there are no bindings that match its routing key).
	?BCC:EitherType<String, Array<String>>,	// like CC, except that the value will not be sent in the message headers to consumers.
	
	//Not used by RabbitMQ and not sent to consumers:
	?immediate:Bool,						// in the specification, this instructs the server to return the message if it is not able to be sent immediately to a consumer. No longer implemented in RabbitMQ, and if true, will provoke a channel error, so it’s best to leave it out.

	//Ignored by RabbitMQ (but may be useful for applications):
	?contentType:String,					// a MIME type for the message content
	?contentEncoding:String,				// a MIME encoding for the message content
	?headers:{},							// application specific headers to be carried along with the message content. The value as sent may be augmented by extension-specific fields if they are given in the parameters, for example, ‘CC’, since these are encoded as message headers; the supplied value won’t be mutated.
	?correlationId:String,					// usually used to match replies to requests, or similar
	?replyTo:String,						// often used to name a queue to which the receiving application must send replies, in an RPC scenario (many libraries assume this pattern)
	?messageId:String,						// arbitrary application-specific identifier for the message
	?timestamp:Float,						// a timestamp for the message
	?type:String,							// an arbitrary application-specific type for the message
	?appId:String,							// an arbitrary identifier for the originating application
}

@:noCompletion
typedef AmqpConsumeOptions =
{
	?consumerTag:String,					// a name which the server will use to distinguish message deliveries for the consumer; mustn’t be already in use on the channel. It’s usually easier to omit this, in which case the server will create a random name and supply it in the reply.
	?noLocal:Bool,							// in theory, if true then the broker won’t deliver messages to the consumer if they were also published on this connection; RabbitMQ doesn’t implement it though, and will ignore it. Defaults to false.
	?noAck:Bool,							// if true, the broker won’t expect an acknowledgement of messages delivered to this consumer; i.e., it will dequeue messages as soon as they’ve been sent down the wire. Defaults to false (i.e., you will be expected to acknowledge messages).
	?exclusive:Bool,						// if true, the broker won’t let anyone else consume from this queue; if there already is a consumer, there goes your channel (so usually only useful if you’ve made a ‘private’ queue by letting the server choose its name).
	?priority:Int,							// gives a priority to the consumer; higher priority consumers get messages in preference to lower priority consumers. See this RabbitMQ extension’s documentation
	?arguments:{},							// arbitrary arguments. Go to town.
}

@:noCompletion
typedef AmqpGetOptions =
{
	?noAck:Bool,							// if true, the message will be assumed by the server to be acknowledged (i.e., dequeued) as soon as it’s been sent over the wire. Default is false, that is, you will be expected to acknowledge the message.
}