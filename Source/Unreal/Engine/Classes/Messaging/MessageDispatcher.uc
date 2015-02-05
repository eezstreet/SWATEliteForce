// IGA class
class MessageDispatcher extends Core.Object
	native;

struct native ReceiverInfo
{
	var Actor receiver;
	var class<Message> messageClass;
};

// receivers and triggerers are stl multimaps defined natively which is 24 bytes
var transient noexport private const int receivers[6];

// registerReceiver
// Registers a receiver's interest in a message
// triggeredByFilter is a comma-separated list of actor labels
native function registerReceiver(Actor receiver, class<Message> messageClass, string triggeredByFilter);

// dispatch
// Dispatches a message to all interested receivers
// The msg object is destroyed after dispatch - you must not hold any references to a message object once
// it has been dispatched.
// msg is set to None during the dispatch call, to emphasise this.
native function dispatch(Actor dispatcher, out Message msg);

// deleteMessage
native function deleteMessage(Message msg);