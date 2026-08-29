Can you share the question again?
Design a real-time chat application like WhatsApp or Slack that supports millions of concurrent users, group chats, file sharing, and message delivery guarantees.

#
hello  hello can we start the interview
Of course! Let's start fresh.

What do you see as the most important functional requirements for this real-time chat application?

#
hello  so I will repeat the question
Sure, go ahead!

#
so the question says design a chat application so designer real chat application like WhatsApp or slap that support millions of concurrent uses group chat file sharing and message delivery guarantees
Yes, that's the problem we're tackling. Let's jump right in — what functional and non-functional requirements would you prioritize for this system?

#
hello so I have placed on the functional and non functional requirement so functional requirement includes users should be able to send one to one message to other person like 121 chats and then he should be able to send messages in group and he should be able to share price and he should be able to see the status of the message that is sent received or Red by the receiver and he should be able to see the online or last scene status of the receiver and user should be able to read old conversation  also send notifications to receiver when a new message send to
I can see your requirements on the canvas — that's a comprehensive list. You've added some good ones beyond the basics like message status (sent/received/read), online/last seen status, and reading old conversations.

What about the non-functional requirements — what are you prioritizing there?

#
non function requirement
I can see them on the canvas — low latency, highly available, scalable, resilient, and fault tolerant. Good list.

Now can you put some numbers around the scale? How many users, message volume, and throughput are you designing for?

#
I have also less down some features that are out of scope for like for today's interview like we have encryption and description of chats and block and unblock user so these are out of scope for our initial product
Good call on defining the scope boundaries upfront — that helps focus the design.

Now let's get into the numbers. Can you work through your scale estimations on the canvas?

#
so we can assume we have a total users of 10 million
Go ahead and work through the full estimations — daily active users, message volume, throughput, and storage — on the canvas, and let me know when you're done!

#
I have done the estimations  so we have total users of 10 million and out of which 50% are daily active uses that is 5 million  and then we have total sent total message is sent per user party is 500 message per user per day and then we have message of file 10% of the total message that is 50 messages per day for user and then we have a throat like 5 million into 500 / 24 into 16 to 60 that is 25%
I can see your estimations on the canvas — 25K QPS average, 50K QPS peak, and 2.5 PB daily storage with an average file size of 10MB. You've also estimated 1 million concurrent users at 20% of daily active users.

Good, solid numbers. Now that we have clear requirements and scale, let's move to the high-level design. Can you sketch out the major components of this chat system and how they connect on the canvas?

#
that is the throughput IT 25k per second and peak through photos 50k per second  and then we have average file size that is being uploaded its 10 MB and we have daily storage required is 2.5 peg bites PB peg bites
Got it, those are significant numbers. Now let's move to the high-level design — can you sketch out the major components and their connections on the canvas?

#
I'll start drawing the diagram
Go ahead! Let me know when you're ready to walk me through it.

#
okay I have done the design
I can see your diagram — it's quite detailed! I see clients, WebSocket Gateways, Message Writer Service, Message Queue (Kafka), Delivery Worker, Message Read Service, Message Store with read replicas, cache, S3, file compression service, notification service (SNS/FCM), Session Store, Group Member Info Store, and User Activity Store.

That's a lot of components. Can you walk me through the end-to-end flow when User A sends a text message to User B in a one-to-one chat?

#
okay so I will give you a walkthrough of like  121 chat so let's see user a science message to user be so whenever you user send some message he is he uses the web socket and he is connected to Api Gateway web socket one of the is let's I'll name them it is a  and the other one is B on which b is connected and on which the C is connected is API actually stateless and I user can be connected to any of the API gateways and user actually connect user user and server creates RTC for web socket connections  and use that for transmission of messages
Good, so the client connects via WebSocket to one of the API Gateway instances. What happens after User A's message reaches the API Gateway?

#
hello  so when are user send some message it is it is sent to Api Gateway and which then send the message to message writer service message writer service write the message and message store and then it sends the message to message the acknowledgement to the user that is user a that them your message has been received to the server your message has been said to the server  ok  so once the messages sent to like that delivery workers the message Pole the message from the message you and first check the destination in our case it is user the destination is also the user information from group member and for DP so in case of a group it is details the session details like from the session store so session store contain user ID is connected to which API Gateway so now we know that the receiver that is B is connected to Api gateway  so that will be worker sends the notification
Good walkthrough. I notice you mentioned the Delivery Worker checks the Session Store to find which API Gateway User B is connected to. What happens if User B is offline — not connected to any API Gateway at that moment?

#
hello in case the user way is offline then we use AWS SMS or Google fcm that is a global Google firebase Cloud messaging to be able to send notifications to users in case when the user is offline so that delivery worker actually uses this AWS SMS or Google fcm
Good — so you have a fallback to push notifications for offline users.

Now, you mentioned message status tracking (sent, received, read) as a functional requirement. Can you walk me through how your current design handles updating and communicating those status changes between users?

#
yeah  yeah so  so we have web socket so whenever I told you like so when the message writer service write the message returns to the API Gateway that the messages sent to the server and web socket Science and Technology has been sent  similarly when user be reads the message user be sense and acknowledgement that I have received the message and API Gate then propagate to  to the delivery worker  and then the delivery worker again like patches on which API Gateway the sender is present and actually send that API Gateway that your message has been Red by the receiver
So the read/received acknowledgements flow back through the same delivery pipeline. That makes sense.

I notice you have a Cache layer in your diagram sitting near the Message Store. What's the caching strategy there — what data are you caching and why?

#
yeah so in case so we are also so our messages are persistent  so you just should be able to read older conversation like he should be able to read a 3 to 5 days or like previous conversation so I like conversation that are that are already read but he wants to read and so he will like scroll up and he should be able to see like previous history so he science the request to Api message read service the data from the cash in case is not worm then we have a cash miss and pose the data from the message Store  message to read  that is a replica of the writer instance of the message Store
Good — so the cache sits in front of the read replica to speed up reads for recent conversation history. That's a practical optimization.

Let's talk about the file sharing flow. Can you walk me through what happens when User A wants to send a video file to User B?

#
so I will give you a walk through for example in my diagram so user see actually uploads a video and user be should be able to read it  so user see uploads a video and then user be should be able to read it so user C is the sender and user bees the receiver in this case of file upload so user see uploads try to upload the five it the it reaches the API Gateway and if you get sense that this is a file type of upload then message it sends the request to message writer service message writer service return S3 URL and the file ID so now the user see directly uploads to a w s s 3 using the sign URL  after the upload to the ws3 there is a message q that actually poles new or uploads data like it reads the S3 events and like it the new uploaded file compressor or transport service Aansu message kyon ine message kyon we get events about new file uploads the file compressor or the and the transport service actually compresses the file and Re uploads into the AWS S3  after the IT successful upload user C now gets the acknowledgement there your file has been uploaded means your message has been sent  after it has sent the request again sends to Api Gateway and Now instead of a message like text message we have a file file ID so the again the same like it sends the message writer service than two and then to delivery worker delivery worker checks on which on which API Gateway the destination user ID is connected to and its message to destination user that this is the URL or this is the destination on which the file exist
Good detailed walkthrough of the file flow. I have one question — you mentioned the file compressor reads S3 events via a message queue, compresses the file, and re-uploads it. How does the system associate the compressed file back with the original message and the sender/destination metadata?

#
so one way to solve this issue is like along with the file we also send some matter ETA that this is the centre and receiver
Where would that metadata be stored — with the file in S3, or somewhere else in your system?

#
let we can store we can use S3 to store matter data of the file also that who is the centre and who is the recipient
Okay. Now let's shift to how your system handles scale. Looking at your architecture with 50K QPS at peak and 1 million concurrent WebSocket connections, what do you see as the biggest bottleneck in your current design?

#
so our estimation says that we have around 1 million active you concurrent users that are that are connected to the API Gateway so one bottle lack or like  is the API Gateway so we have to make API Gateway scale able so that they can like we can have this many web socket connections
Right — managing 1 million concurrent WebSocket connections is a significant challenge. How would you approach scaling the WebSocket API Gateways to handle that load?

#
we will scale the amount we will do horizontal scaling on API gateway
Horizontal scaling makes sense, but WebSocket connections are stateful — each user has a persistent connection to a specific gateway instance. How does your system handle the scenario where a gateway instance goes down and thousands of users lose their connections?

#
also for example an API Gateway goes down then all the connections like all the users that are connected to that API Gateway are lost and so a new epi Gateway actually Spencer API Gateway instance spence of epigateway pod then all these users actually connect to that instance and they start searching from where the left  because we are also in our database we are also keeping drive the sequence number till which we have read the data in the conversation
Good — so clients can reconnect and use the sequence number to fetch missed messages from the Message Read Service. That's a solid recovery mechanism.

Now, what about your Message Store — at 25K writes per second average and 2.5 PB daily storage, how would you partition the data to handle this write throughput?

#
Aansu 2.5 megabytes storage is on a w S3  text storage is small  just to be clear
Good clarification — the 2.5 PB is for file storage on S3, and the text message storage would be much smaller.

Still, at 25K message writes per second, how would you shard your Message Store to handle that write throughput efficiently while supporting fast reads for conversation history?

#
yes 2.5k throughput 25 ke throughput  write throughput on database  of on message store is actually a significant throughput  so what we can do instead of one writer we can have multiple data bases writers and we can use forum based to  be able to figure out the result
What would be your sharding key for partitioning the messages across those multiple writer instances?

#
and the shirt key should be conversation ID
Good choice — conversation ID keeps all messages in a conversation co-located on the same shard, making reads for conversation history very efficient.

Now looking at your Delivery Worker — it needs to look up the Session Store to find which API Gateway each recipient is connected to, and for groups it also needs to query the Group Member Info Store. At peak load with large groups, how would you ensure the Delivery Worker doesn't become a bottleneck?

#
so that's why I we will have we will have multiple consumers of a single cube  so it after make sure that our messages are read at least once
Good, multiple consumers on Kafka helps with throughput. But think about the downstream calls — each Delivery Worker is making lookups to Session Store and Group Member Info Store for every message. For a group with thousands of members, that's a lot of lookups per message. How would you optimize that?

#
ya we can use a cash on the group member info Store
Good — caching group membership data would reduce repeated lookups. What about the Session Store lookups? For a group with 1000 members, you'd potentially need 1000 session lookups to find each member's connected API Gateway. How would you handle that efficiently?

#
we can make a batch call like we can in a single query we can pull like hundred members that are in the same in the group
Batching is a practical optimization.

Let's talk about a different trade-off. You have a single Message Writer Service handling all writes. At 50K QPS peak, what consistency model are you using — and what trade-off are you making between consistency and availability for your message store?

#
so for chat application we will privatize availability over consistency
That makes sense for a chat app. But consider this — if two users in the same conversation send messages at nearly the same time, and those writes land on different shards or replicas, how do you ensure the messages appear in the correct order for all participants?

#
hello actually message with not appear in different charts because we are sharing the database based on conversation ID  so in case of a 121 chat it is a single ID and in case of a group chat this will also be a single conversation ID  this is for clarification
You're right — good catch. Since all messages for a conversation live on the same shard, ordering within a conversation is straightforward.

But within that single shard, how are you determining the order of messages? You mentioned sequence numbers earlier — how are those generated and assigned?

#
so one way to do that is like when we are appending the data in the message store it will generate A sequence ID  and this will make sure all over means we have a sequence  in a conversation
So the database auto-generates the sequence ID on write. That works well since all messages for a conversation go to the same shard, avoiding cross-shard ordering issues.

We're nearing the end of our session. One final question — you mentioned the User Activity Store for tracking online/last seen status. How does that get updated in your current design, and how would you handle the load of millions of users frequently updating their status?

#
so before we end the interview I just want to make the database diagrams like how will the database keema look  schema
Sure, go ahead and sketch out the database schemas on the canvas!

#
so just wanted to answer the question that you ask that regarding the activity store for Tracking online last scene status how can we have how does that get updated in your current design  so whenever a message writer event like to the last activity data store and the delivery worker also send last activity event to the user activity data store  so now we know that user id has been active at this time stem so this so every time it updates the last time stamp of a user  so based on the last time being and like that time at which it was last online so if it was like less than a minute we can say that the user is online and if it if it is offline we can like compare the current time minus the last activity time stamp so we can know that the user was online 5 minutes ago
That's a practical approach — using the message write and delivery events to passively update the last activity timestamp, and then deriving online/offline status from the time difference.

However, at millions of concurrent users, that's a lot of frequent timestamp updates. What kind of data store would you use for the User Activity Store to handle that write-heavy workload?

#
I think we can use the reddish cash also  because this is a female data and it doesn't add value much
Good reasoning — Redis is well-suited for this since it's a simple key-value lookup (user_id → timestamp), handles high write throughput, and the data is ephemeral so durability isn't critical.

Go ahead and sketch out those database schemas you wanted to draw!

#
yeah I have yellow hello hello I have added the schema so it contains table like users group message file user activity and session info  so users have user id name bio and created at and then group has group ID member user ID  and then message has ID sender ID conversation ID text message created at and the sequence id file has ID sender ID aws3 URL created at and sequence ID user activity has user id and last activity session and four has user id and connected at API gay API Gateway ID
Good schema design. I notice your Message and File tables both have sequence_id and sender_id but they're separate tables. When a user opens a conversation that has both text messages and files, how would you display them in the correct chronological order if they're in different tables?

#
I think we can use account like that comes from another table  so in that way like message and files have different counters  unique counters
But if they have separate counters, how would you interleave them in the correct order when displaying a conversation timeline? For example, if a text message has sequence_id 5 and a file has sequence_id 3, how do you know which one came first?

#
I think we can De normalize and combine these tables message and  file
Good thinking — combining them into a single table would make ordering straightforward with a single sequence_id. The file-specific fields like S3 URL could be nullable for text-only messages.

Alright, we've covered a lot of ground today, Shubham. Would you like me to give you your evaluation and ratings?

#
yeah I think we can do the valuation  evaluation
Here's my assessment of your performance today, Shubham:

Requirement Gathering — 8/10 Excellent job. You identified comprehensive functional requirements including message status tracking, online/last seen, and reading old conversations. You clearly defined non-functional requirements and scoped out features like encryption and block/unblock. Estimations were thorough with concurrent user calculations. Very well done.

Design — 8/10 Strong architectural design with well-separated components. Smart decisions like WebSocket Gateways, signed S3 URLs, file compression pipeline, Session Store for connection tracking, and separate read replicas with caching. The Delivery Worker pattern for routing messages to the correct gateway was well thought out. Could have been slightly stronger on the schema design initially with the message/file table separation.

Problem Solving — 7.5/10 You handled challenges well — correctly pushed back on the sharding question when I asked about cross-shard issues, recognized the need for batching session lookups, and evolved your schema when the ordering problem was identified. You solved the metadata association for file compression and the User Activity Store design independently. Minor gap on the message/file ordering issue which required prompting.

Scale & Trade-offs — 7/10 Good understanding of horizontal scaling for stateless components, conversation-based sharding, caching for group membership and conversation history, and Redis for ephemeral activity data. Could have gone deeper on replication strategies, failure handling, and load balancing across WebSocket servers.

**Communication — 8/10

#
I want you to rate me based on this interview on a scale of 1-10 for this criteria : Req.	Design	Prob-Solving	Scale & Trade-offs,	Communication	Overall
Here are your ratings:

Criteria	Rating
Requirement Gathering	8/10
Design	8/10
Problem Solving	7.5/10
Scale & Trade-offs	7/10
Communication	8/10
Overall	7.5/10
Verdict: Pass

You showed significant improvement compared to your earlier attempt. Your requirements were more comprehensive, your architecture was more thoughtful with components like the Delivery Worker, Session Store, and User Activity Store, and you handled challenges more independently this time.

Key strengths:

Comprehensive requirements with clear scope boundaries
Well-structured architecture with smart component choices
Good ability to push back and defend design decisions when challenged
Clean walkthrough of end-to-end flows
Areas to sharpen further:

Go deeper on failure scenarios and recovery mechanisms
Proactively discuss trade-offs before being asked
Think through schema design more carefully upfront
Explore more advanced scaling patterns like connection draining during gateway failures
Strong performance overall, Shubham! You're well-prepared for system design interviews. Keep practicing the depth on scaling and trade-offs to push toward an 8+ overall. 💪

#
What will be the overall verdict
Verdict: Pass ✅

You cleared the bar this time. Your overall score of 7.5/10 puts you in the pass range. Here's the breakdown:

Below 6 → Need significant work
6 - 6.9 → Borderline
7 - 7.9 → Pass ← You are here
8+ → Strong pass
Compared to your first attempt where you scored 6.5 (Borderline), you improved by a full point. The biggest improvements were in:

Requirements — more comprehensive with status tracking, last seen, and clear scope boundaries
Design — more thoughtful architecture with Session Store, Delivery Worker, User Activity Store, and caching layers
Problem Solving — handled challenges more independently and even pushed back correctly on the sharding question
To move to a Strong Pass (8+), focus on proactively identifying bottlenecks and trade-offs without being prompted. Great job, Shubham! 🎉