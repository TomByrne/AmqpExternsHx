package amqp;

import amqp.AmqpChannel;

/**
 * ...
 * @author Thomas Byrne
 */
extern class AmqpConfirmChannel extends AmqpChannelBase
{
	/*
	 * publish mimics the stream.Writable interface in its return value; it will return false if the channel’s write buffer is ‘full’, and true otherwise. If it returns false, it will emit a 'drain' event at some later time.
	 */
	function publish(exchange:String, routingKey:String, content:AmqpBuffer, options:AmqpPublishOptions, callback:AmqpError->{}->Void):Bool;
	
	/*
	 * Send a single message with the content given as a buffer to the specific queue named, bypassing routing. The options and return value are exactly the same as for #publish.
	 */
	function sendToQueue(queue:String, content:AmqpBuffer, options:{}, callback:AmqpError->{}->Void):Bool;
	
	/*
	 * Resolves the promise, or invokes the callback, when all published messages have been confirmed. If any of the messages has been nacked, this will result in an error; otherwise the result is no value. Either way, the channel is still usable afterwards. It is also possible to call waitForConfirms multiple times without waiting for previous invocations to complete.
	 */
	function waitForConfirms(callback:AmqpError->{}->Void):Bool;
}