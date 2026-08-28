Welcome to your system design interview! Here's your design challenge:

Design a real-time chat application like WhatsApp or Slack that supports millions of concurrent users, group chats, file sharing, and message delivery guarantees.

Use the drawing canvas to the left to create diagrams, system architectures, and visual representations of your solutions. The problem statement has been added to the canvas to get you started.

Think out loud as you work through the problem, and don't hesitate to ask clarifying questions. This interview focuses on your ability to design scalable systems, communicate ideas visually, and think through real-world constraints and trade-offs. I'll guide you through the process and provide feedback at the end.

#
hello  hello  I am Shobha  Shubham
Hi Shubham, welcome! Let's get started.

Before jumping into the design, let's make sure we're clear on the requirements. What do you see as the most important functional requirements for this chat application?

#
hello  hello I am Shubham and I can see your question in the whiteboard at the questions is a designer chat application designer real time chat application like WhatsApp or slap that supports millions of concurrent uses group chat share filing and message delivery guarantees
Great, Shubham! Yes, that's the problem we're tackling today.

Let's start by clarifying the requirements. There are several features mentioned — real-time messaging, group chats, file sharing, and delivery guarantees. What would you prioritize as the core functional requirements, and are there any specific non-functional requirements you'd want to call out, like latency, availability, or consistency?

#
I start writing the functional requirements
Go ahead! Sketch out the functional requirements on the canvas, and let me know when you're ready to discuss them.

#
okay so functional requirement include are uses should be able to send message to another user so it is like a 121 chat and he should be able to send message to a group  and you just use your can share text messages as well as files and message sharing should have like guarantee so it should be at least one and with idiom potential ki
I can see your requirements on the canvas. You've covered the key functional requirements — one-to-one messaging, group messaging, text and file sharing, and message delivery guarantees.

For the non-functional requirements, I see you've listed high availability, low latency, and scalability. Can you give me a rough sense of the scale you're designing for — how many concurrent users, and what kind of message volume are you thinking?

#
also all system should be Resilient
Got it — resilience is an important consideration.

Now, can you put some numbers around the scale? For example, how many concurrent users and what kind of message throughput per day are you designing for?

#
and fault orlerant  so now I'll do estimations
Sounds good, go ahead and work through your estimations on the canvas!

#
so let's assume we have total users  10 million  and daily active users is  half 50% of that that is 5 million
Got it — 10 million total users with 5 million daily active users. What kind of message volume would you estimate per day with that user base?

#
and each user  and  daily sense around 100 messages under 500 messages  and  most of the time we actually don't  we don't always send images so only 10%  of the total messages contain images
Good estimates. So that gives you roughly 2.5 billion messages per day, with about 250 million of those containing images — that's significant volume.

Now that we have a solid understanding of the requirements and scale, let's move to the high-level design. Can you sketch out the major components of this system on the canvas?

#
that is  50 message per day  contain  images  ok
Got it — 50 image messages per user per day. Go ahead and sketch out your high-level architecture on the canvas showing the major components and how they connect!

#
and 20% UPS  is so we have a through a top 25 k  per second  and so we will have a peak through port off  double off the average throughput  that is 50k per second
Good, so you're looking at 25K QPS average and 50K QPS at peak — that's a solid baseline for your design decisions.

Now let's move to the high-level design. Can you sketch out the major components of this chat system on the canvas?

#
let us also calculate the volume storage required  so  5 5 million
Go ahead and work through the storage estimation on the canvas — I'll review it once you're done!

#
latest assume that the files that are shared are like videos and as well as photos so photos have a generally average size of 2 MB and  but videos can have like different size so we can assume that each every size is average file sizes 10 MB
Okay, so with an average file size of 10MB and 50 file messages per user per day, that's a substantial amount of storage. Go ahead and finish the storage calculation on the canvas, and then let's move into the high-level architecture!

#
okay  so daily the storage required will be so we have 5 million users daily and each sending like 50 50 messages of images of type files  and each file is of average size 10 MB  so we will have like 2.5 peg bites of storage required per day
That's 2.5 PB per day — that's a massive amount of storage, which will definitely influence your design decisions around file storage and delivery.

Now that we have a clear picture of the requirements and scale, let's start with the high-level design. Can you sketch out the major components of this chat system and how they connect on the canvas?

#
yeah okay so since  since we require a large amount of storage so  will go with object storage so we can use a w s s 3 for storing these large amount of files  and instead of  client sending request to server and server uploading them to S3 we can directly provide signed urls to user that they can upload the images images of files to S3 directly
Interesting, you're jumping right into the file upload strategy. Before we go deep into specific components, can you first sketch out the overall high-level architecture — showing all the major components like clients, servers, databases, and how they connect together?

#
yeah I like draw the architecture diagram
Go ahead and draw it on the canvas — I'll review it once you have the major components and their connections laid out!

#
also one more function requirement that I consider we should be able to send notifications to receiver of the messages in real time
Good catch — real-time notifications are crucial for a chat application. Go ahead and incorporate that into your high-level architecture as you sketch it out on the canvas!

#
hello I have done the diagram  and so I will give you a work through like what all components that we have so we have a client that is centre of the text message or like file message and then we have to receivers and we have API Gateway which has indication and authorisation + 8 limiting and then we have right text service so text messages  which I will form of string and then we have right file service so that actually help in returning the sign you are of a w s s 3 to the user so that he can directly upload that file then we have read message service and we have a message you that has message events  and we have a notification service  and then we have message store so it contain messages  and then we have group information store so it contains like information about the group and it all its members so it can be like group or it can be a single destination also like a single destination
I can see your diagram — nice work laying out the components. I see the client, API Gateway, Write Text Service, Write File Service, Read Message Service, message queue (Kafka), Notification Service, Message Store with a read replica, Group Info Store, S3 for file storage, and a file compression service.

Let's dive deeper into the design. Can you walk me through what happens end-to-end when a user sends a text message to a group — starting from the client all the way to the receivers getting that message?

#
okay I will give you a walk through and of what happens when I use of send some message to a group okay  so when I'm user try to send a message to the group so he will use post slashtak TPA and that actually is a intersected by the API Gateway which just check the authentication authorisation and there is no meeting means
Go ahead, continue walking me through the flow — what happens after the API Gateway validates the request?

#
that request actually sent to the right tax service so right tax service actually gets destination destination
Continue — what does the Write Text Service do with the destination information?

#
hello  yeah so when it get some message it sends the message to that right text service  write text service rights the message in the message data store also rights tax service rights and event fires and event to message event so it contains like so ID not the full message like message of message and the destination destination ID  then these not the notification service events and  so then notification  from the destination it figures out what are the members of the group by setting the information from the group info data store and it it send the notifications to all the group members using SSC events  to and send post notifications to all the members of the group
Good walkthrough. I notice you mentioned using SSE (Server-Sent Events) for delivering notifications to receivers. For a real-time chat application where both the client and server need to exchange messages frequently, what factors influenced your choice of SSE over other communication approaches?

#
SSC in case like a destination is a group then we we will use SSC service and events SSE  SSE service centre events but in case of a chat 121 set then we can use web sockets
Interesting — you're proposing different protocols for group vs one-to-one messaging. What's your reasoning for using SSE for groups but WebSockets for one-to-one chats, rather than using the same protocol for both?

#
all the members of the  all the receivers of the message of a group might not be interested at that time they can like they can read at their own we can't just use our connections for like only I like fraction of members of the groups are actually reading message at the same time so we might not want to waste our connections
That's an interesting consideration about connection management. But with SSE, the server still needs to maintain an open connection to each client to push events. How would that be different from WebSockets in terms of connection overhead?

#
yeah I think you we need a real time night real time notifications then we can use web sockets like
Okay, so you're leaning toward WebSockets for both cases to enable real-time delivery. Let's move on.

I see you have a file compression service and a compression queue in your diagram. Can you walk me through the end-to-end flow when a user sends a file message?

#
so when are user  so when I user wants to upload a video at the request actually go to post upload file survey upload a post upload file and then it reaches the API Gateway then it reaches to write file service right file service returns signed URL of S3 to the user user uses that signed you are l and upload that to directly to the S3  and after the file is successfully uploaded we have the compressed Q actually read those events like a new uploaded events from the S3 and the file compression service actually reads those event that there is a new file at this location and it actually  after the file compression is done  it sends event to write file service so right file service actually send right the sender and the location of the S3 URL and the destination into the message store and also emits and event to the message event service notification service
Good flow. I have a question about one part — you mentioned the compression service reads upload events from S3. How does the compression service know which destination and sender to associate with that file after compression is complete?

#
yeah apart from  so  let me think of it like how we can solve this issue either we can store matter data along with the file in S3 when the user uploads  so this can solve the issue
That's one approach. Now let's think about the message delivery guarantee you mentioned earlier — at-least-once delivery. How does your current design ensure that a message is actually delivered to the recipient, and how would the recipient's client know if it missed any messages?

#
so once a message actually reads to reaches the rights Tech service or right file service so it actually emits and even to the message Que  so the notification service that is the consumer of the events will so it will do retrieves  and it will send notifications  with with rice with the item puttan see ki so it will try at least one means it will receive the notification send notification with IDM postmc key
So you're relying on Kafka's at-least-once delivery semantics to the notification service. But what about the last mile — how do you ensure the message actually reaches the recipient's device? For example, what happens if the recipient is offline when the notification is sent?

#
dampotency key so our notification service actually will send notification that there is a new message but also like when the user open stap he can like use the read message service that and he can also view older messages also  in the group chat using this read message service
Okay, so you're combining push notifications with a pull mechanism via the Read Message Service for offline users. That covers the delivery scenario.

Let's move to scaling. Given your estimates of 50K QPS at peak, what do you see as the main bottlenecks in your current architecture, and how would you address them?

#
in case of like so we have a high throughput so  there will be height report on database also  and  so instead of one writer instance we can have multiple writer and stances and then they can actually have a corem  Korum and  they can do they can  like decide whether it will be saved at least once
You're talking about multiple writer instances with quorum-based writes. What database technology are you considering for the message store, and how would you partition the data across those multiple writer instances?

#
yeah we will have  we can use no SQL database  like mango db
What would be your partitioning strategy for the messages in MongoDB — how would you shard the data to handle the high write throughput while still supporting efficient reads for both one-to-one and group conversations?

#
we can actually based on Geographic reason  Geographic region
Geographic partitioning is one approach. But think about a common query pattern — when a user opens a chat conversation, they want to see all messages in that thread. How would geographic sharding help or hinder that specific read pattern?

#
to message of sender of a single Centre should be in a same database\
So you're suggesting partitioning by sender. But consider this — in a group chat with members across different shards, when a recipient opens the group conversation, they'd need to read messages written by many different senders. How would that read pattern work with sender-based sharding?

#
so we can do joins  join query in memory and return the result to the user like in case like the message are from different charts
Doing in-memory joins across multiple shards for every group chat read could be expensive at scale, especially for active groups. Is there a different sharding key you could consider that would keep all messages in a single conversation — whether one-to-one or group — together on the same shard?

#
charts we can like key Das group ID at the short key
Good — using the conversation or group ID as the shard key keeps all messages for a conversation co-located, making reads very efficient. For one-to-one chats, you could apply the same concept with a conversation ID.

Now, beyond the database, what other bottlenecks do you see in your architecture at 50K QPS peak, and how would you handle them?

#
so all the messages inside a group actually exist inside  inside  inside a Shad
Right, that's the benefit of sharding by conversation/group ID.

Let's look at other parts of your system — at 50K QPS peak, what about the API Gateway and your WebSocket connections? How would you scale those to handle millions of concurrent users?

#
API Gateway our stateless we can like scale them  we can do horizontal scaling
Good, stateless API Gateways can scale horizontally. What about the WebSocket connections — those are stateful since each client maintains a persistent connection. How would you manage millions of concurrent WebSocket connections across multiple servers?

#
we will need more server for like that actually holds website connections
Right, you'd need multiple WebSocket servers. But here's the key challenge — when a message arrives for a specific user, how does the system know which WebSocket server that user is connected to, so it can deliver the message to the right server?

#
we can do consistent consistent hashing based on user ID or group ID
Consistent hashing is a good approach for distributing connections. But consider a scenario — if a WebSocket server goes down, those users will reconnect to a different server. How does the rest of the system handle that transition, and how would in-flight messages be handled during that window?

#
I am not sure like how we can solve this issue
That's okay. One thing to think about is how your message queue (Kafka) and the pull-based Read Message Service you already designed could help here — since messages are persisted, a reconnecting client could recover missed messages.

Let's shift to another trade-off. You're storing 2.5 PB of files per day in S3. How would you manage storage costs and retrieval performance over time as this data grows?

#
so people actually generally try to see recent messages like past one day or one week messages they don't actually see older messages so we can like instead of S3 we can use a ws3 Glacier or any other storage that has which actually reduce our cost and for messages that are older and will not be frequently  frequently fest buy user
Good thinking — tiering storage with S3 for recent data and Glacier for older data is a practical cost optimization strategy.

We're nearing the end of our session. Let me ask one final question — looking at your overall design, if you had to pick one area where you'd be most concerned about reliability or data loss, which component would it be and why?

#
in case of message store we we have a replication so  so we already the data is replicated Applause multiple message stores  and similarly for group information store also the data is replicated across multiple data stores so we don't have to worry about data lost their and s3 as we are using a w s s 3 AWS actually provides facility provide inbuilt assurance to as that there is will be no data loss  and it has inbuilt application across different availability zones
Good analysis of data durability across your storage layers. You've covered replication for your message store, group info store, and leveraged S3's built-in durability guarantees.

That wraps up our system design interview, Shubham! Here's a summary of what you covered:

Strengths:

Solid requirements gathering with clear estimations for throughput and storage
Good separation of concerns with distinct services for text, files, and notifications
Smart use of signed URLs for direct S3 uploads to offload file transfer from your servers
File compression pipeline with Kafka is a thoughtful addition
Good evolution of your sharding strategy from geographic → sender-based → conversation/group ID
Storage tiering with S3/Glacier for cost optimization
Areas to explore further:

WebSocket connection management at scale — handling server failures and connection routing
Message delivery guarantees end-to-end, especially the last mile to offline clients
Consider how read/unread status and message ordering would work in your design
Think more about the trade-offs between different communication protocols (SSE vs WebSockets)
Overall, you demonstrated good systematic thinking and were willing to iterate on your design decisions when challenged. Nice work!

#
so before we end the session I want you to read my read my skills based on today's interview in this following criteria requirement gathering design problems solving scale and trade of communication and overall feedback
Here's my assessment of your performance today, Shubham:

Requirement Gathering — 7/10 You identified the core functional requirements well — 1:1 messaging, group chat, file sharing, delivery guarantees, and notifications. Your estimations were reasonable with clear throughput and storage calculations. However, you could have explored more edge cases upfront, like offline message delivery, message ordering, read receipts, and user presence — these would have strengthened your foundation.

Design & Problem Solving — 6.5/10 You laid out a solid set of components with clear separation of responsibilities. The file upload flow with signed URLs and the compression pipeline showed good practical thinking. However, some design decisions needed more depth — for example, the SSE vs WebSocket choice wasn't fully reasoned through initially, and the connection between components like the compression service and metadata tracking required prompting to address. The message delivery guarantee discussion stayed mostly at the Kafka level without fully solving the last-mile delivery problem.

Scale & Trade-offs — 6/10 You correctly identified database sharding as important and evolved your sharding key from geographic to conversation-based, which was good. You recognized stateless horizontal scaling for API Gateways. However, the WebSocket scaling challenge — connection routing and failover — remained unresolved. Storage tiering with Glacier was a nice addition. More depth on caching, CDN for files, and read replica strategies would have strengthened this area.

Communication — 7/10 You used the canvas effectively to lay out your architecture with

#
a design and problem solving are different can you like Ray teach one of them  can you rate each one of them
Sure, here's the updated breakdown:

Requirement Gathering — 7/10 Good identification of core functional and non-functional requirements with reasonable scale estimations. Could have explored more edge cases like offline delivery, message ordering, read receipts, and user presence upfront.

Design — 7/10 Strong component separation with dedicated services for text, files, notifications, and reads. Good architectural decisions like signed URLs for direct S3 uploads, Kafka for event-driven communication, and the file compression pipeline. The overall system structure was well thought out. Could have been stronger with a clearer real-time delivery mechanism design and more consideration of how components like the Read Message Service interact with WebSocket servers.

Problem Solving — 6/10 You showed willingness to iterate — evolving your sharding strategy when challenged was good. However, some problems required significant prompting to address, like metadata association in the file compression flow and the SSE vs WebSocket reasoning. The last-mile delivery guarantee and WebSocket failover problems remained unresolved.

Scale & Trade-offs — 6/10 Correct identification of database sharding and stateless gateway scaling. Good storage tiering with S3/Glacier. However, WebSocket connection management at scale was a gap. More depth needed on caching, CDNs, and handling peak load scenarios.

Communication — 7/10 Effective use of the canvas with a clear architecture diagram. You walked through flows logically. Could improve by being more structured in articulating trade-offs and reasoning before making

#
okay and what would be your overall verdict it will be a pass border line or need some work
Based on your overall performance, I'd put you at Borderline.

Here's why:

What worked in your favor:

Solid requirements and estimations
Good architectural structure with clear component separation
Smart practical decisions like signed URLs and compression pipeline
Willingness to iterate when challenged
What held you back:

Several critical distributed systems challenges remained unresolved (WebSocket failover, last-mile delivery guarantees)
Some design decisions lacked depth until prompted (SSE vs WebSocket, sharding strategy)
Limited discussion on caching, CDNs, and operational concerns like monitoring and fault recovery
Problem solving required significant prompting rather than proactive identification of issues
To move to a clear pass, I'd recommend:

Practice thinking through end-to-end delivery guarantees more deeply — especially the last mile
Spend more time on stateful connection management at scale (WebSockets, connection registries)
Proactively identify bottlenecks and trade-offs before being asked
Explore caching layers, CDNs, and read optimization strategies for high-read systems
You have a solid foundation, Shubham. With more depth on distributed systems challenges and more proactive problem identification, you'd comfortably clear the bar. Keep practicing!

#
and on a scale of 1 to 10 like what would be like my overall performance
I'd rate your overall performance a 6.5/10.

You're above average in structuring a system and laying out components, but below the bar needed for a confident pass at a top-tier company. The gap is primarily in depth — being able to independently identify and solve the hard distributed systems problems without prompting.

A 7.5+ would be a comfortable pass, and you're not far from it. Focus on those areas I mentioned, and you'll get there. Good effort today, Shubham!