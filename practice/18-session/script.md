Welcome to your system design interview! Here's your design challenge:

Design a scalable notification system that can send millions of push notifications, emails, and SMS messages with high delivery rates and minimal latency.

Use the drawing canvas to the left to create diagrams, system architectures, and visual representations of your solutions. The problem statement has been added to the canvas to get you started.

Think out loud as you work through the problem, and don't hesitate to ask clarifying questions. This interview focuses on your ability to design scalable systems, communicate ideas visually, and think through real-world constraints and trade-offs. I'll guide you through the process and provide feedback at the end.

#
hello
Hey! Let's dive in. Before we start designing, let's make sure we understand the problem well.

What do you see as the key functional requirements for this notification system?

#
hey  let me read the question to make sure I understand it correctly so the problem State Design and notification system designer a scalable notification system that can send millions of post notifications email SMS with high delivery date and a minimal latency
Take your time reading through it. Once you're ready, what are the key requirements you'd want to clarify before starting your design?

#
okay  so before we start I just want to make sure  list of item that we will discuss in this interview  so I have added the list so it include functional requirement nonfunctional requirement estimations architecture walkthrough API design DB schema trade-offs login monitoring and results
I can see your outline on the canvas — that's a well-structured approach. Let's get started with the first item on your list.

What functional requirements would you identify for this notification system?

#
yeah so I'll start with the functional requirements  so first  to be able to send  SMS email  post notifications  to users  with using templates  okay  and then user  should  be able to  unsubscribe  notifications  on that channel  and then we also want to
I can see you've started capturing those on the canvas. Take your time — what other functional requirements are you thinking about?

#
have at least  sending at least one guarantee  and
Go ahead, what else would you add?

#
okay so two more functional requirements that I have listed so we should be able to send at least once currency and then use plug-in approach so that we can switch providers  and we should be able to send to a fallback channel in case the provider is down
Good, I can see those on your canvas. You've covered templates, unsubscribe, at-least-once delivery, pluggable providers, and fallback channels.

What about the non-functional requirements — what would be most critical for a system sending millions of notifications?

#
I would say highly available  because notifications can be a part of hot path for example and OTP sending to user for login  so I think I availability is must  and then reliability  so in case the provider is down so we should  it should not bring down the whole system  and resilient  and then tolerate  small delay  tolerable
I can see those on your canvas. Before we move to the high-level design, one thing I notice is missing from your requirements — have you thought about the scale of this system in terms of numbers?

#
cause scalable  of course scalable
Scalable is listed, but I meant more specifically — can you put some concrete numbers around the scale? For example, how many notifications per day are we designing for, and what does that translate to in terms of throughput?

#
estimations  so let's assume  daily  on notifications  daily total notification  send equals to 10 million  and  so  throughput  it's not 10 into 10 per 6  divided by 24 into 60 into 60 that is equal to
I can see you're working through the math on the canvas. That would give you roughly 115 notifications per second on average. But what about peak traffic — would you design for the average or something higher?

#
that is supposed to 100 requests per second
Okay, so about 100 requests per second on average. Now that we have our requirements and rough estimates laid out, let's start with the high-level design.

Can you sketch out the overall system architecture on the canvas showing the major components and how they connect?

#
and 200 requests per second is our Peak throughput  and then we'll in case of a  major  notification  like event for example like a marketing event where we actually need to send post notifications to everybody that the sale is like  so at that time there is actually going to be a spike  so
That's a good observation about traffic spikes from marketing events. You've captured your peak throughput as 200 requests per second, but those bulk marketing scenarios could push it much higher.

Now let's move to the architecture — can you sketch out the high-level system design on the canvas?

#
so in case of a marketing event so we can have like 5 million notifications which are being sent in 10 minutes so that is equals to 5 into 10 + 6 / 10 into 60 and that is roughly equals to 10K request per second
That's a significant spike — going from 100 RPS average to 10,000 RPS during marketing events. That's a 100x increase, which will definitely influence your architectural decisions.

Now that we have solid requirements and estimations, let's start with the high-level design. Can you sketch out the major components of this system on the canvas?

#
so let's assume that  so  traffic  handled
I see you're starting to write about traffic handling. I think we have enough on the estimation side to inform our design decisions.

Let's move forward — can you start drawing the high-level architecture showing the major components and data flow of the notification system?

#
is it close to 50 request per second  then we would actually need  around 200 workers  during the week marketing event
Good, so you've estimated needing about 200 workers to handle the spike. That gives us a sense of the scale we're designing for.

Now we have a solid foundation with requirements and estimations. Let's move to the architecture — can you start sketching out the high-level system diagram showing the major components and how notifications flow through the system?

#
Peak marketing event
Got it. Now let's move on — can you start drawing the high-level architecture on the canvas? Show me the major components and how a notification would flow from request to delivery.

#
Okay so  yeah I'll draw the architecture
Go ahead, I'll review it once you have it on the canvas.

#
I just want to talk is this notification service  going to be for a public or is it going to be used by internal services
That's a great clarifying question. Let's say it needs to support both — internal services (like your auth service sending OTPs) and potentially external clients through an API.

How would that influence your design? Go ahead and start sketching it out.

#
okay  yeah in case if it is an internal service then we can skip authorization and if it is asked for public use then we have to go for authorization also
Good point about the auth distinction. Let's go ahead and start drawing the architecture on the canvas — show me the major components and how they connect.

#
Malcolm Bella Linda  you are alive
I can see you've started drawing on the canvas — I see some components like an internal service (login service for OTP), a marketing service, an API gateway, an external user/customer, and a notification service. You've also got arrows showing connections between them.

Can you walk me through the flow you've drawn so far — how does a notification request get from the source to the notification service?

#
architecture well done  hello  I have drawn the diagram
I can see your diagram — it's quite detailed! You've got:

Sources: Internal services (login/OTP, marketing) and external users going through an API Gateway
Notification Service with different auth handling for internal vs external
Kafka topics per channel (Push, Email, SMS) with priority levels
Delivery Workers consuming from Kafka and sending to providers (FCM, APNs, SendGrid, Twilio)
Supporting stores: User Cache, User DB, Idempotency Cache, Rate Limit Cache, Notification DB, Template Cache, and a Dead Letter Queue
This is a comprehensive design. Let's dive deeper — can you walk me through what happens inside the Notification Service when it receives a request, step by step?

#
so  so whenever a notification service gets a notification request from an internal service  it does authentication plus rate limit  and so first it's check the user details from the user cache  and for example from the user ID finds the username so that it can fill that details in the template  then it checks the idepotensy key that in the cash that this key exist or not if it exists that means this is a duplicate and it rejects that request  and so similarly we have a rate limit cash so it checks the weather this user ID has been rate limited or like is above the threshold or below the threshold  so there's a little late limit check and then there is a after that we insert that request in a notification DB  so yeah so it is a no SQL database and then after that the notification request is sent to the based on the channel it is sent to the channel Kafka topic and so and also the request contain that about the priority so if it is a high or low priority it is sent to that dedicated topic so we have different topic for the same channel so for example and SMS can have a low priority SMS Kafka topic and a SMS high priority  so this is because sometimes some SMS needs to be sent instantaneously like otps whereas some SMS can wait for like a longer period of time  and then there are so after the message request has been sent in a Kafka topic it is being pulled by the delivery workers so delivery workers  pull those messages on notifications from the Kafka topic and they first they create the message using the template predefined template so templates are cash in the delivery like in the cash so from the request we fill the template using the variables that are being present in the cash in the request  so after the template has been filled we send the request to the to that provider of that channel for example in case of SMS it will be a Tulio provider or like any other provider so we will make this as a plugin architecture so we can change the provider in case we are not satisfied with the provider in case in case the provider is down so what we will use is we will use circuit breakers so we will do retries until  retries after some back of period And if we have exhausted all our returns then we will add those requests in a dlq  and we will set up alerts on the size of dlq also  so when the notification has been sent by the provider the user receives that
Excellent walkthrough — you've covered the full lifecycle from request ingestion through delivery with good attention to reliability patterns like idempotency, circuit breakers, retries with backoff, and DLQ handling.

One thing I want to probe deeper on — you mentioned checking the user's subscription status and fetching user details from the cache. What happens if a user has unsubscribed from SMS but the request is for an SMS notification?

#
so yeah in case so in case the user have unsubscribed that channel for example a user had said to not get any emails  from our so he has unsubscribed our channel so what we can do is when we fetch the user status we will get the value of a subscription like true or false in case it is false we will drop that request and we will not send that request to the Kafka topic
That makes sense — filtering out unsubscribed users early in the pipeline before they hit Kafka saves downstream processing.

Let's dive into another aspect of your design. You have Kafka topics split by channel and priority — how do your delivery workers know which topic to consume from, and how do you ensure high-priority messages don't get starved by a flood of low-priority ones?

#
so what we can do is like we  so we will have delivery workers per Channel  and priority so we have a channel into priority number of delivery of our these are the number of topics that we will have  so each topic will have its number of delivery workers so in case how we can do is like we can have set up alerts in case the number of in case there is a spike in the number of request then we can scale up  the number of instances of the delivery worker  so in case the high priority delivery workers are lesson number and high priority requests are more than if we can have autoscale in the number of delivery workers or we can have set up an alert also so that somebody can manually go up and go and scale those number of delivery workers for that channel into priority
Good, so you have dedicated worker pools per channel-priority combination, which provides isolation.

Let's shift to a different area — you mentioned using a plugin approach for providers. How would you handle a scenario where a provider like Twilio goes completely down, not just intermittent failures but a full outage?

#
so in case of intermittent failure we are using circuit breakers  and so in case  the circuit breaker is off for like a large like a threshold of the circuit breaker is open for like a configurable amount of time  then we can say that the provider we need to switch to another provider then we can have a fallback mechanism that in case that SMS are not send that we can send those request to another delivery channel for example via email so I think we should set up rules for fall back  so we will have fallback rules
Interesting — so you'd fall back to a different channel entirely (e.g., SMS to email). But what about falling back to a different provider within the same channel first, before switching channels? For example, switching from Twilio to another SMS provider before falling back to email.

#
so I think what we can do  yeah we can have like an interface kind of an approach where we have to implementations where one goes to the default provider that is to you and then if the default provider is not available for for a configurable period of time then we can change that default to another provider  so I think we can  use configurations also  so  so this is kind of an automated approach that code is intelligent so it will automatically send to another provider  so in so in our code base we will have we will have secrets of like we will have  so we will have API calls and code base for different providers so the code will be intelligent to to switch providers during the run time  or we can have a manual approach also so somebody on the admin side can also change the provider of the code that might need an restart but that would also work I guess
Good thinking about both automated and manual failover approaches. The plugin architecture with a common interface makes the providers interchangeable, which is a solid pattern.

Let's move to scaling considerations. You estimated 10,000 RPS during marketing spikes — that's 100x your average load. How would your current architecture handle that kind of sudden spike, and where do you see potential bottlenecks?

#
I think the first bottleneck would be  would be the notification service itself  and the notifications workers also  so the we will have less amount of workers and Kafka with the consumers will be login lagging in case there's a sudden spike in throughput  so  yeah so we so the consumer leg we can see the consumer lab in the dashboard also  so what we can do is we can scale out the number of delivery workers on each on that particular Channel
Good, you identified the delivery workers as a bottleneck. But what about the notification service itself — you said that's also a bottleneck. How would you handle the spike at that layer before messages even reach Kafka?

#
I think that we will increase the number of instances of notification services  we will scale it out
Okay, but during a sudden spike you might not have time to scale out. What role does Kafka play in absorbing that burst of traffic?

#
so I I Kafka act as a lake buffer  so  so that the sudden Spike doesn't reach the workers and they don't  mean they are not  they don't get crash due to the sudden Spike so Kafka is acting as a buffer  and also it the another thing that Kafka does here is like it is not waiting for the acknowledgment from the provider to be sent instead it just we just acknowledge to the user or the customer that you're notification will be sent and we have acknowledged the request  so in this way the third the customer doesn't have to wait for the whole provider to acknowledge
Exactly — Kafka decouples the ingestion from delivery, absorbing bursts and enabling asynchronous processing. That's a key design decision for handling those 100x spikes.

Let's talk about a different trade-off. You chose a NoSQL database for storing notification requests. What factors led you to that choice over a relational database?

#
so I think for in this case the notification we have used notification DB as of type no sequel  and we can use like AWS  Dynamo DB  or Cassandra  because  we don't need asset properties here and the right throughput is actually very high  that's why  it is more so  so that's why we have choose chosen no secret database  no sequel database
Good reasoning — high write throughput and relaxed consistency needs make sense for this use case.

Let's discuss another important aspect. You have a User Cache and a User DB reader instance in your diagram. What's your cache invalidation strategy when a user updates their subscription preferences?

#
so I think  so whenever there is an update in user preference  we would  remove that entry from the user cache  and we will fetch the new entry so if we will invalidate the cash and the first request that reaches will actually fetch see that there's no entry in the cash and will fetch from the user DB reader instance
So you're using a cache-aside pattern with invalidation on updates. One thing to consider — you mentioned a reader instance for the User DB. What happens between the time a user unsubscribes and the cache gets invalidated? Could a notification slip through?

#
so yeah we are using cash aside  cashing strategy
Right, but my question was about the timing gap — if a user unsubscribes, there's a window between the write to the database and the cache invalidation where stale data could still show them as subscribed. Is that an acceptable trade-off in your design?

#
just in this case this is like  within a minute  so I think we can tolerate that  and that's that is actually one of the non-functional requirement that  so I would say we will not guarantee 100% , so yeah  so it would be an eventual consistency but we are okay to take that risk
Fair enough — you've acknowledged the trade-off explicitly and tied it back to your non-functional requirements. Eventual consistency with a small window is reasonable here.

Let's talk about one more area. You mentioned logging, monitoring, and alerts in your outline. What key metrics would you track to ensure the system is healthy and meeting its delivery guarantees?

#
yeah  so one of the requirement was also  Okay so  so far logging  I would say we can use any open source solution or like we can use some managed services like data dog or Splunk or New Relic for locks or we can use grafana also  so these services will be sending logs to the to those providers  for a monitoring and alerts I think the  so what Matrix that we will keep track so in case of Kafka we will keep track of throughput the bytes in and bites out  and the consumer lag  and  in case of workers we can check the CPU utilize percentage CPU utilization percentage memory utilization so that before it feels we actually know  so we can set up alerts like when the CPU utilization is greater than 70% then we can like scale those workers up  and so on delivery workers will also like monitor the circuit breakers also the amount of time in which the circuit breaker is open  so this way we will be able to calculate the downtime of our external providers also  although we are using dlq so we will also  monitor the size of tlq  and also we will also keep track of unsubscriptions status  so that will also we will also monitor that that how many users have subscribe  so this will also provide us a view that which notification has resulted in an unsubscription  from user  or notification service side we will  we will keep track of throughput latency error rate  and along with that we will also have a cash shows we will monitor cash hit ratio cash ratio and  yeah I think  in case of we have also database so we will also monitor the database size indexing and all these
That's a thorough set of metrics covering Kafka health, worker resources, circuit breaker states, DLQ size, cache hit ratios, and service-level metrics like throughput and error rates. Good that you also thought about business metrics like unsubscription tracking.

Let me ask you about one final trade-off. You designed for at-least-once delivery guarantee. What are the implications of that choice, and how does your idempotency cache help mitigate the downsides?

#
yeah so we have an identity cash so in the user the customer will send that idempotency key to us  so in case they send the request twice so the second request will be filled or will be dropped  so that would be the identity guarantee from our system  what do you mean by what are the implications of that choice
What I mean is — at-least-once means a notification could potentially be delivered more than once to the end user. Your idempotency cache handles duplicate requests at the ingestion layer, but what about duplicates that could occur downstream — for example, if a delivery worker crashes after sending to the provider but before committing the Kafka offset?

#
so yeah that would  so in that case  so Kafka actually guarantees at least one delivery so for example a delivery worker fetched notification  and then it delivered to the provider and before acknowledging that request to the Kafka it actually it dies  so the Kafka will actually  send that to request to another delivery worker means another delivery worker will read start reading from that offset for the top partition and it will again read that message notification message and send to  that provider so there would be duplicate message sent to the same user for the same notification  so I think  that is a very rare scenario and we are able to take that risk
That's a fair assessment — you've clearly understood the trade-off. You could potentially explore provider-level deduplication or tracking delivery status, but acknowledging it as a rare and acceptable risk is a valid design decision.

Overall, you've put together a very comprehensive design. You covered requirements clearly, made solid estimation calculations, built a well-structured architecture with good separation of concerns, and thought through reliability patterns like circuit breakers, DLQ, idempotency, and fallback mechanisms. Your monitoring strategy was also thorough.

A few areas you might consider exploring further in practice:

Batch notification optimization for marketing events rather than sending individually
Delivery status tracking and callbacks from providers
Template versioning as templates evolve over time
Great job walking through this design! Do you have any questions for me?

#
yeah  I think what we can do is those delivery workers can also update the status of notification in the notification DB  so for each notification after it has been acknowledged by the provider that it is sent so we will update that status and notification DB  and so in this way we are we are reducing the chances of  resending the same notification to the same user  so the delivery worker will also update the status to send  to deliver in the notification DB  for that notification ID
That's a good addition — checking the notification status in the DB before sending would act as a second layer of deduplication beyond the idempotency cache, catching those edge cases where a worker crashes after delivery but before committing the Kafka offset.

One quick thought to probe on — would checking the DB on every delivery attempt add latency or become a bottleneck at 10,000 RPS during spikes?

#
do you want me to also draw the so I have less down  like  the points so we covered function non-function requirements estimations architecture walkthrough  I think we have discussed the DB skiba also somewhere we have done touch the trade offs we just logging monitoring and alerts I think API is schema is remaining rest I think we have covered everything
You've covered a lot of ground and your diagram is very detailed. We've touched on most of the key areas through our discussion.

To my earlier question though — if delivery workers check the notification DB status before every send, could that DB lookup become a bottleneck during those 10,000 RPS spikes?

#
yeah I think that would be a bottle neck so  because at that scale this much number of Rights will actually bring down the database
Right — so how might you address that? You've already shown a pattern in your design for handling similar high-throughput read/write scenarios.

#
we will use asynchronous rights by using Kafka
Good thinking — so you'd decouple the status updates through Kafka as well, keeping the delivery path fast. But then if the status update is asynchronous, there's still a window where a duplicate delivery could happen before the status is written. How do you feel about that trade-off?

#
I think we should be able to take that risk and that would not over engineer our work
That's a pragmatic engineering decision — knowing when to accept a small risk rather than over-engineering is important in real-world system design.

We've had a thorough discussion covering all the major areas. Your design demonstrates strong understanding of distributed systems, good use of reliability patterns, and thoughtful trade-off analysis. Well done — this was a solid interview! Is there anything else you'd like to discuss?

#
before we end the interview I want to take feedback on today's interview based on following criteria  requirement Gathering design problem solving skill and trade-offs communication overall  and so can you provide me a feedback on a scale of 0 to 10 on each of these parameters
Here's your feedback:

Requirements Gathering — 8/10 You did a strong job identifying both functional and non-functional requirements upfront. You covered templates, unsubscribe, at-least-once delivery, plugin architecture, and fallback channels. You also proactively clarified whether the system serves internal vs external clients. The estimations with average, peak, and spike throughput were well thought out. Could improve by considering edge cases like bulk notification APIs or scheduling notifications for later delivery.

Design — 8/10 Your architecture is comprehensive and well-structured. Good separation of concerns with the notification service handling validation/routing and delivery workers handling actual sending. Smart use of Kafka for decoupling and buffering, per-channel and per-priority topics, dedicated worker pools, and supporting caches. The diagram was detailed and easy to follow. Minor gap — didn't explore delivery status tracking or batch optimization until prompted.

Problem Solving Skill — 7/10 You demonstrated solid problem-solving with circuit breakers, DLQ, idempotency, fallback providers, and cache-aside strategy. You correctly identified bottlenecks at the notification service and worker layers. However, some solutions needed prompting — like provider-level failover before channel failover, and the DB bottleneck from status checks at scale. Could improve by proactively identifying failure scenarios before being asked.

Trade-offs — 8/10 You consistently acknowledged trade-offs explicitly — eventual consistency in cache invalidation, at-least-once vs exactly-once delivery, async writes creating duplicate windows, and avoiding over

#
also  what is what would be the verdict of this interview is it going to be a lean higher stronger or no higher
Continuing the trade-offs feedback:

Trade-offs — 8/10 You consistently acknowledged trade-offs explicitly — eventual consistency in cache invalidation, at-least-once vs exactly-once delivery, async writes creating duplicate windows, and pragmatically choosing not to over-engineer. You tied decisions back to requirements, which showed mature engineering judgment.

Communication — 8/10 You structured the interview well upfront with a clear outline. Your walkthrough of the full notification lifecycle was thorough and logical. The diagram was detailed and visually communicated the architecture effectively. You explained your reasoning clearly at each step. Could improve by being slightly more concise in verbal explanations.

Overall — 8/10 A strong, well-rounded performance across all areas.

Verdict: Strong Hire

You demonstrated clear systematic thinking, built a production-quality architecture from scratch, proactively considered reliability and scalability patterns, created a comprehensive visual design, and showed mature engineering judgment on trade-offs. The few areas where you needed prompting were minor and you responded well when challenged. This is the kind of design thinking expected at a senior engineer level. Well done!

#
I would based on my today's interview what would be your feedback for me for the next interview
Great question! Here are my key recommendations for your next interview:

1. Proactively Identify Failure Scenarios You handled failures well when asked, but try to proactively bring up "what could go wrong" at each component before the interviewer asks. For example, when drawing the delivery workers, immediately discuss what happens when they crash, when providers are down, or when there's a network partition.

2. Think About Edge Cases Earlier Consider scenarios like — what happens with duplicate phone numbers, what if a user receives both a fallback email AND the original SMS (provider was slow, not down), scheduled/delayed notifications, or notification batching for marketing events. Bringing these up yourself shows depth.

3. Be More Concise in Verbal Explanations Your explanations were thorough but sometimes lengthy. Practice the pattern: state the decision → give one reason → mention the trade-off. This leaves more time for covering additional topics.

4. Dive Deeper Into API Design You mentioned it in your outline but didn't get to cover it. Practice defining API contracts early — it demonstrates how clients interact with your system and often reveals requirements you might miss.

5. Quantify Your Design Decisions You did great estimations upfront but didn't always tie them back to design choices. For example, when choosing Redis for caching, mention the expected cache size and hit ratio to justify the choice.

6. Practice Leading the Interview You have strong knowledge — focus on driving the conversation so the interviewer has to ask fewer prompting questions. Treat it as if