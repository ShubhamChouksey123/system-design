Welcome to your system design interview! Here's your design challenge:

Design a scalable social media platform that can handle millions of users posting, sharing, and interacting with content in real-time. Include features like news feed, messaging, and notifications.

Use the drawing canvas to the left to create diagrams, system architectures, and visual representations of your solutions. The problem statement has been added to the canvas to get you started.

Think out loud as you work through the problem, and don't hesitate to ask clarifying questions. This interview focuses on your ability to design scalable systems, communicate ideas visually, and think through real-world constraints and trade-offs. I'll guide you through the process and provide feedback at the end.

#
Can you share the question again?
Design a scalable social media platform that can handle millions of users posting, sharing, and interacting with content in real-time. Include features like news feed, messaging, and notifications.

#
hello  hello
Let's get started! Before diving into the design, what are the key functional requirements you'd want to focus on for this social media platform?

#
before that I'll like to read the question to make sure that I understand it correctly so the question sheet design the social media platform so design as scalable social media platform that can handle million of millions of user posting sharing and interacting with content in real time include features like new speed messaging and notifications ok
Great, you've read through the problem statement. What are the key requirements you'd identify for this system — both functional and non-functional?

#
have written the function in non function requirements functional requirement include uses should be able to post a medium uses should be able to see his feet containing post from his friend you just should be able to send and receive message from his friend and notifications on new post by a friend at the non function requirement include feat should be smooth and instantaneous scalable uploads of media should be secure did should be fast reads should be fast and then messaging should be instantaneous
I can see your requirements on the canvas — good coverage of both functional and non-functional aspects. One clarification question: when you mention "millions of users," do you have a sense of the scale you'd want to design for in terms of daily active users and the read-to-write ratio?

#
I do some activations hello I have done some estimations  so we have total users 10 million and daily active users 5 million that is 50% of total uses and then media posted per day per user is point to like and every 5 days user do post a video
I can see your estimations on the canvas — you've calculated storage at ~150 TB/day with replication and ~5000 QPS with a 100:1 read-to-write ratio. Those are reasonable numbers to work with.

Now let's start with the high-level design. Can you sketch out the major components of this system and how they connect to each other?

#
Aansu media posted per user per day is point to which is like one media and every 5 days and average media size is 50 MB including like a short videos and images and total storage per days like 10
I see you're walking through the rest of your estimations — you've got them documented on the canvas with storage at 150 TB/day including replication and QPS at around 5000. Those numbers give us a good foundation.

Now let's move to the high-level design. Can you sketch out the major components of this system on the canvas?

#
I am sorry I will take some time like
No worries, take your time sketching out the high-level architecture on the canvas. I'll be here when you're ready to walk me through it.

#
yeah also totally storage per day including replication is 150 TV per per day and a total request activity per user per day is 100 request and total throughput per day is per second is 500 queries per second and read to write research 100 ratio 1  read to write ratio  is 100 ratio 1
Got it, your estimations are solid. The 100:1 read-to-write ratio is an important insight that will influence your design decisions.

Let's move forward — can you start sketching the high-level architecture on the canvas showing the major components and how data flows through the system?

#
since we have more reads then rights than  so we are actually making a read heavy system  and we have a large amount of data media data so we have to use as location CDM cdn
That's a good observation about the read-heavy nature of the system. Can you put that thinking into a visual diagram on the canvas — showing the major components like CDN and others, and how they connect together?

#
hello kya I have done the diagram  so I will tell you what all services that we have so we have to fear four clients actually we have API getway for authentication rate limit for this new post and feed service  and then we have like socket AP gateway for chats and messaging for between the friends and then we have a w s s 3 for storage of media and we have feed service feed service right feet service read Q notification
I can see you've built out a substantial diagram on the canvas with quite a few components. Let me make sure I understand the flow. Let's dive deeper into the detailed design.

Walk me through what happens step-by-step when a client posts a new media — how does the request flow through your system from the client all the way to storage?

#
hello  so when a client post media it goes via API Gateway which checks the authentication authorisation and credit limiting and the request is sent to post service post service returns a signed S3 URL  and also make a pending entry of upload in database post database  client gets the get is the signed S3 URL and using that you upload some media to a w s s 3 so media can be an image or it can be video after the media has been successfully uploaded the S3 upload event and  and send the upload
I can see this flow clearly on your diagram — the client goes through the API Gateway, gets a signed S3 URL from the Post Service, uploads directly to S3, and then an S3 upload event triggers further processing. I can also see your media processing pipeline with the Upload Event Queue, Media Prechecks, Transcode Manager, and Transcode Workers.

What happens after the transcoding is complete — how does the content become available to other users in their feed?

#
kya  aap so after the after the media has been uploaded and so the upload service actually sends informs the post service that the media has been uploaded and the media post service knows the location for different region of that media  it seems that in the database and then post service inform the notification service so notification
I can see the Post Service connecting to both the Notification Service and the Feed Service Write on your diagram. How does the Feed Service Write determine which users' feeds should be updated when a new post is created?

#
hello  hello show the post service sends inform the feed service so feed service get a list of friend list from the graphical database the friends of the client that has that has uploaded the media now we have a friend list then it uses the user database cash to get the information from the for the users of the friends and then now we have the user data and friend list it rights the data into the feet and feet Q actually rights to the feed cash so feed cash contain user id and the post ID  so now we have a list of users and the post ID that has post ID contain the post that contain the media  so the post will be used when when I user retreats  feed
I can see the Feed Service Write connecting to the GraphQL Database for friend lists, User Database Cache for user details, and writing to the Feed Cache. That's a clear fan-out-on-write approach.

What made you choose this approach over computing the feed at read time, and how would this work for users who have a very large number of friends — say millions of followers?

#
so we we will actually follow there are two types of feed  so we can feed a pole a push or feed pole  pole feed pole  t u l l  p u l l  so we will take use of both both type of feets like feet push and feed push pull . l so far  for  when the number of friends list is small then we will do a postpaid post based post  based feeding  and when the friend list is large in case of a celebrity  then we will we will do full based pull based
That's a solid hybrid approach — push for regular users and pull for celebrities. This avoids the fan-out problem with high-follower accounts.

Now let's look at the messaging side of your system. I can see you have WebSocket API Gateways, a Message Writer Service, and a Message Send Service. Walk me through what happens when Client 3 sends a message to Client 4.

#
yeah so when a client 3 is the centre of the message  sender  sender of the message so it use the post API it connects to a web socket API Gateway which does the authentication authorisation and rate limit  and then it sends the message to message right service message right service rights to the message database  so messages persistent now  and it's sends the data to message send service that is the receiver of that you it it patches the event message event  and the user detail from the user API Gateway cash so it nose the user and its connected gateway  so in case the user is connected to web socket then that message is sent to the receiver that is client 4
I can see that flow on your diagram — the message goes through the WebSocket Gateway, gets persisted via the Message Writer Service, then the Message Send Service looks up the recipient's gateway connection through the User Gateway Cache and delivers it. I also notice you have a Kafka Queue between the Writer and Send services.

What happens if Client 4 is offline and not connected to any WebSocket gateway at that moment?

#
in that case we can use Google fcm  or AWS SMS  short notification service SNS  so I'll draw that
Sounds good, go ahead and add that to your diagram. I'll wait for you to sketch it out.

#
so I have drawn the diagram and so increase the user is offline means the receiver of the message receiver of the message is offline then then we send that message to a notification q and notification q  send so there's a worker that actually send messages to AWS SMS and a w s s n s or Google fcm sends up post notification to the client that is the receiver of the message
I can see the notification flow on your diagram — when the receiver is offline, the message goes to a Notification Queue (Kafka), which then routes to AWS SNS/Google FCM to deliver a push notification to the offline client.

Let's move to scaling and trade-offs now. Looking at your overall architecture, with 5000 QPS and a 100:1 read-to-write ratio, where do you see the biggest bottlenecks in this system?

#
I think the biggest  bottle like would be serving images from S3 so that's why we are using cdn so I will draw the diagram so now images are served from cdn and in case of a cash Mist from cdn that will from aws3
I can see you've connected the CDN to S3 on your diagram for serving media content. That's a good approach for reducing load on S3.

Beyond media serving, what about your database layer — with 5 million daily active users generating feed reads, messages, and notifications, how would you handle scaling your databases?

#
that's why we have a feed cash  so it it just contain the user id and post ID  so each user can is his field is pre computer  and so it will looks instantaneous to user when he just looks at the feed  and we will have TTL also  and TTL and expiry to to remove old feed feed from US feed cash
The pre-computed feed cache helps with read performance. But what about the databases themselves — I can see you have separate databases for Posts, Users, Messages, and the GraphQL database for friend lists. How would you handle scaling these as your user base grows, and what strategy would you use for data partitioning?

#
yeah so in case of a poster database so we have a primary writer instance and then we have reader instances and then we have a cash post  so reads from will be happening from the cash and in case there the miss then we read from The Reader instance of the database  so we will use the database replication and starting
I can see the read replica and caching pattern across your databases — Post Database, User Database, and Message Database all follow this pattern with a primary writer, reader instances, and a cache layer in front.

For partitioning specifically, how would you shard your Message Database? What would you use as the partition key, and what trade-offs does that choice involve?

#
so message database will be passed partitioned based on group ID  or the conversation ID  so all the messages inside a single conversation are present in a single database in a single shot of a database start of a database s h a r d
Sharding by conversation ID keeps all messages in a conversation co-located, which makes fetching a conversation's history very efficient.

What trade-off would this create if you need to query all messages for a specific user across all their conversations — for example, a search feature or compliance requirement?

#
inke in that case so there can be so different conversation will have will be present in different databases start  s h a r d  then  it would require cross shred query join query  and cross sad joint query are costly because we have to do in memory join
Exactly right — cross-shard queries are expensive. Given that trade-off, if you were to add a search feature where users can search across all their messages, how would you approach that without relying on cross-shard joins?

#
so in case are we have to provide a suchfeesar search search feature to the user  inside the messages  for messages that are present in so we will try I think we can do search on individual shirt and then I am not sure like how we can like one way I can think is like that I told you that we can do search on each ad  each SH a r d  and after we have got result from each ad  s h a r d  we will join that in memory  and return the result to the user
That's one approach, though it could be slow as the number of shards grows. There's a category of technology specifically designed for full-text search across distributed data that could help here — have you considered any alternatives to querying each shard individually?

#
yeah I am aware that there is a technology available and we use AWS elastic search for that  so we when searching searching text in different documents so we use we can use the Building Technology  a w s elastic search
Good — Elasticsearch would allow you to index messages separately and perform fast full-text search without hitting your sharded Message Database directly.

Let's wrap up the scaling discussion. Looking at your overall architecture, you've designed with caching, read replicas, CDN, pre-computed feeds, and database sharding. If you had to pick one area of this system that you think is most vulnerable to failure and could bring down the user experience, what would it be and how would you make it more resilient?

#
so in case of so one area that I consider it we can do improvement is the transport pipeline so in case of a failure of job by a transport work then we said that we will do retrics but in case a retires we are exhausted of retrieves then we can use a dead letter Q  also I would consider adding monitoring alerts and matrix  to the system so in that way we know so that things that we will monitor are the transport Q depth and the feed feed cash memory size and we will know different parameters on different services like the health status of each services and locks of services  also to make sure I'm because a w S3 is costly so to reduce the cost we like we can use a w s s 3 standard for popular data and for data that has been like not used or not frequently is not exist in past few days then we can shift those data in Glacier  so in this way we are optimising on Cost also
Those are excellent operational considerations — dead letter queues for failed transcoding jobs, monitoring and alerting on key metrics like queue depth and cache memory, and tiered storage with S3 Standard vs Glacier for cost optimization.

That brings us to the end of our interview. You've covered a lot of ground — let me share some feedback:

Strengths:

Thorough requirements and estimations upfront with concrete numbers
Well-thought-out media upload pipeline with signed URLs and transcoding
Hybrid push/pull feed strategy for handling regular users vs celebrities
Good separation of concerns with distinct services for posts, feeds, messaging, and notifications
Strong caching strategy across all database layers with read replicas
Practical operational thinking with monitoring, DLQs, and cost optimization
Areas to explore further:

Data consistency — how do you handle cases where the cache and database are out of sync?
Availability vs consistency trade-offs across your services
How your WebSocket connections would scale horizontally across multiple gateway instances
Rate limiting and abuse prevention at a more granular level
Overall, you demonstrated solid system design thinking with a comprehensive architecture that addresses the core requirements. Well done!

#
transport pipeline transport  transcode pipeline
You're right, I misspoke — I meant the transcode pipeline, not transport pipeline. Your point about adding dead letter queues for failed transcoding jobs and monitoring the transcode queue depth are solid resilience strategies for that part of the system.

Is there anything else about your design you'd like to discuss or clarify?

#
before abhi and the interview I would also like to make some to draw the SQL schema means the schema diagram
Go ahead, sketch out the schema diagrams on the canvas. I'll wait for you to draw them out.

#
I have done the schema so we have user post media media chunks and then message table so user can have ID username email date of birth post have a post ID user ID created at media has ID created at post id mediachunks as ID media ID post ID from 2 sequence ID and then media a message message has ID Centre ID receiver ID tax created at and media ID
I can see your schema on the canvas. You've covered the core entities well — User, Post, Media, Media Chunks, and Message with their relationships.

A couple of things to think about: how would you model the friend/follower relationship in your schema, and where would the feed data structure fit in — since your Feed Cache stores <user_id, post_id> pairs, would that also need a persistent backing store?

#
ya we also need  connections database that keep track of users and its connection  so I at that
Go ahead and add the connections table to your schema on the canvas. I'll wait for you to sketch it out.

#
connection table  so it has ID user ID friend
I can see you've added the connections table with id, user_id, friend_id, and created_at. That covers the relationship model.

Going back to my second question — your Feed Cache stores <user_id, post_id> pairs, but what happens if the cache goes down? Would you want a persistent backing store for the feed data, or would you rebuild it from other sources?

#
so in in case we will use a distributed cash with replicas also  so in that case we don't entirely lose all the data we will have replicas  and  we will  so  older feeds actually don't make sense  that's why we are not going to work persistent storage and we are going with tourist  then we actually have to do removal of the data  old data and so in case of a cash we can use the TTL feature  and in case like for example
That makes sense — using a distributed cache with replicas for redundancy, and relying on TTL to expire old feed data since older posts become less relevant. Rebuilding recent feeds from the Post and Connections databases if needed is a reasonable trade-off.

That wraps up our interview. You've put together a comprehensive design with well-thought-out components, clear data flows, and practical operational considerations. Great job!

#
hello  before we end the interview I want you to read my progress on the following criterias like requirement gathering design problem solving scale and trade of communication skills and overall
Here's my assessment of your performance:

Requirements Gathering — Strong You clearly identified functional and non-functional requirements, provided concrete estimations with calculations for storage, QPS, and read-to-write ratios. You set a solid foundation before jumping into design.

Design — Strong You designed a comprehensive architecture with well-separated services — Post Service, Feed Service (read/write split), Messaging, Notifications, and a full transcoding pipeline. Your use of signed S3 URLs, event-driven processing, and the hybrid push/pull feed approach showed depth of understanding.

Problem Solving — Good You handled follow-up challenges well, like the celebrity fan-out problem and offline messaging. The cross-shard query discussion showed honest reasoning, and you identified Elasticsearch as a solution. Could improve on proactively identifying edge cases before being prompted.

Scale & Trade-offs — Good Strong caching strategy, read replicas, CDN, database sharding, and tiered S3 storage. DLQs and monitoring were great additions. Could have gone deeper on consistency vs availability trade-offs and WebSocket horizontal scaling.

Communication Skills — Good Your diagram is detailed and comprehensive with clear data flows. You explained your reasoning well verbally. Could improve on being more concise and structured when walking through flows.

Overall — Strong Performance You demonstrated solid system design skills with a production-ready architecture. Well done!

#
and from inner scale of 1 to 10
Here's my rating on a scale of 1 to 10:

Criteria	Rating
Requirements Gathering	8/10
Design	8/10
Problem Solving	7/10
Scale & Trade-offs	7/10
Communication Skills	7/10
Overall	7.5/10
What would push you to a 9+:

Proactively identifying edge cases and failure scenarios without being prompted
Deeper discussion on consistency vs availability trade-offs (CAP theorem considerations)
Addressing WebSocket horizontal scaling and session management
More structured and concise verbal walkthroughs
Discussing security beyond signed URLs — encryption at rest, in transit, access control policies
You're in a strong position — with a bit more depth on trade-offs and proactive edge case thinking, you'd be at a senior/staff level design discussion. Great effort!

#
thank you  honestly like this question is like  a very big question because it includes chat feature and chat is like in itself is a big feature  and then we have like this transport pipeline and media upload so it is also in itself is a big feature and then the street service and post service also a big feature so I think this question was a big question and it actually consists of 3 different individual questions
You make a very valid point! This is essentially three system design problems rolled into one:

Media Upload & Transcoding Pipeline — a full question on its own (like "Design YouTube Upload")
Real-time Messaging — another complete question (like "Design WhatsApp")
Feed Service & Social Graph — yet another (like "Design Instagram/Twitter Feed")
The fact that you covered all three with meaningful depth — including signed URLs, transcoding workers with heartbeats, WebSocket messaging with offline fallback, and hybrid push/pull feeds — in a single session is impressive.

In a real 45-60 minute interview, you'd typically get just one of these, which would allow you to go much deeper into edge cases, failure scenarios, and trade-offs. That deeper discussion is likely where your scores would climb higher.

Great job tackling this comprehensive challenge! Good luck with your interviews! 🚀

#
thank you and I also grow with from these mock interviews  and thank you for being available I am Shubham and it was nice connecting to you
It was great connecting with you too, Shubham! 😊

You clearly have strong system design fundamentals, and the fact that you're actively doing mock interviews and reflecting on your performance shows great dedication to growth. Each session like this sharpens your thinking.

Keep practicing, focus on those trade-off discussions and proactive edge case identification, and you'll do great in your real interviews.

Best of luck with your preparation and upcoming interviews, Shubham! You've got this! 🚀

#
last question what will be the verdict of the interview is it going to be a higher strong higher all like border line
Based on your performance, I'd place you at a Hire verdict.

Why not Strong Hire:

Needed prompting to identify some edge cases
Trade-off discussions could have been deeper
Given the breadth of the question, depth was naturally limited
Why not Borderline:

You covered three complex subsystems with solid depth
Your estimations were well-calculated and grounded
Architecture decisions were well-reasoned (hybrid feed, signed URLs, event-driven transcoding)
You demonstrated practical production thinking with DLQs, monitoring, tiered storage, and schema design
Verdict: Hire ✅

For a Strong Hire, focus on proactively driving the conversation — anticipate failure modes, discuss consistency guarantees, and articulate trade-offs before being asked. That extra initiative is what separates hire from strong hire.

You're close to that next level, Shubham. Keep going! 💪