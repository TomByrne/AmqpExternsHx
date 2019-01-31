package amqp;

/**
 * ...
 * @author Thomas Byrne
 */
extern class AmqpConnection 
{
	/**
	 * Close the connection cleanly. Will immediately invalidate any unresolved operations, so it’s best to make sure you’ve done everything you need to before calling this. Will be resolved once the connection, and underlying socket, are closed. The model will also emit 'close' at that point.
	 * Although it’s not strictly necessary, it will avoid some warnings in the server log if you close the connection before exiting
	 */
	function close(?callback:(String->Void)):Void;
	function on(event:AmqpConnectionEvents, ?callback:(Dynamic->Void)):Void;
	
	/**
	 * Resolves to an open Channel (The callback version returns the channel; but it is not usable before the callback has been invoked). May fail if there are no more channels available (i.e., if there are already channelMax channels open).
	 */
	function createChannel(callback:(AmqpError->AmqpChannel->Void)):Void;
	
	/**
	 * Open a fresh channel, switched to “confirmation mode”.
	 */
	function createConfirmChannel(callback:(AmqpError->AmqpConfirmChannel->Void)):Void;
}

@:enum abstract AmqpConnectionEvents(String){
	
	/**
	 * Emitted once the closing handshake initiated by #close() has completed; or, if server closed the connection, once the client has sent the closing handshake; or, if the underlying stream (e.g., socket) has closed.
	 */
	var close = 'close';
	

	// Undocumented
	var error = 'error';
}

typedef AmqpConnectionEvent = {};