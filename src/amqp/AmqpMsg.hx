package amqp;

import haxe.DynamicAccess;

/**
 * ...
 * @author Thomas Byrne
 */
typedef AmqpMsg =
{
	content: AmqpBuffer,
	fields: AmqpMsgFields,
	properties: AmqpMsgProperties,
}

typedef AmqpMsgFields =
{
    consumerTag: String,
    deliveryTag: Int,
    exchange: String,
    redelivered: Bool,
    routingKey: String,
}

typedef AmqpMsgProperties =
{
    appId: String,
    clusterId: String,
    contentEncoding: String,
    contentType: String,
    correlationId: String,
    deliveryMode: String,
    expiration: String,
    headers: DynamicAccess<String>,
    messageId: String,
    priority: Dynamic,
    replyTo: String,
    timestamp: String,
    type: String,
    userId: String,
}