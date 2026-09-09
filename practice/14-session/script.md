Welcome to your system design interview! Here's your design challenge:

Design a scalable notification system that can send millions of push notifications, emails, and SMS messages with high delivery rates and minimal latency.

Use the drawing canvas to the left to create diagrams, system architectures, and visual representations of your solutions. The problem statement has been added to the canvas to get you started.

Think out loud as you work through the problem, and don't hesitate to ask clarifying questions. This interview focuses on your ability to design scalable systems, communicate ideas visually, and think through real-world constraints and trade-offs. I'll guide you through the process and provide feedback at the end.

#
hello  hi I am Shubham
Hi Shubham, welcome! Let's get started.

Before jumping into the design, let's make sure we're aligned on the requirements. What do you see as the key functional requirements for this notification system?

#
Can you share the question again?
Design a scalable notification system that can send millions of push notifications, emails, and SMS messages with high delivery rates and minimal latency.

#
hello hello I am Shubham
Hi Shubham! Let's dive right in.

To kick things off, what do you think are the most important functional requirements for this notification system?

#
so before that I would like to read the question to make sure that I understand it fully so designer notification system so designers notification system that can send medians of post notifications email and SMS messages with delivery rates with high delivery dates and minimal latency  ok
Take your time! Once you've fully absorbed the problem, what are the key requirements you'd want to clarify or focus on for this system?

#
hello  so I have written the function in non functional requirements  so the function requirement include notification service support sending emails push notifications and SMS  should use predefined set of template for SMS email notification should read limit notifications and to customer should not send notifications to a customer that has unsubscribed us and we should have logging monitoring and alert setup non function requirement include  minimum daily in acceptance minimum delay is acceptable and then system should be resident  resident resilient
I can see your requirements on the canvas - nice work laying those out. A couple of things I'd like to probe on.

You mentioned the system should handle "millions" of notifications. Can you clarify what scale you're designing for — for example, how many notifications per day, and are there any peak traffic patterns you'd want to account for?

#
I do some estimations and then we will come back with some numbers
Sounds good, go ahead with your estimations!

#
so let's assume we have like 10 million post notifications are sent to send then throughput per second will be 10 into 10 pass 6 / 24 hours 60 second and 60 minutes so that is equals to 100 request per second like 100 notifications per second
I see your estimations on the canvas — 10 million notifications per day coming out to roughly 100 requests/second as an average. That's a good baseline, but what about peak traffic scenarios — would you expect the load to be evenly distributed throughout the day?

#
okay so we can as you like at p  through code will be twice of that  that is 200 request per second
Good, I see you've noted the peak throughput at 200 requests/second. That gives us a solid baseline to work with.

Now that we have our requirements and estimations laid out, let's move to the high-level design. Can you sketch out the overall system architecture on the canvas — the major components and how they connect?

#
okay I will all the architecture of our system
Go ahead, take your time and sketch it out on the canvas!

#
before that I just wanted to ask one clarifying question so is this service going to be available for outside like public user or is it going to be for internal clients  Services within the same organisation it's our organisation
That's a great clarifying question. What's your instinct on this — how would the design differ depending on which direction you go?

#
yeah I think for like  it doesn't matter much
Fair enough. For the purpose of this interview, let's assume it's an internal service used by other services within your organization — like a billing service triggering a notification. Go ahead and sketch out the high-level architecture on the canvas!

#
hello  hello I am done the diagram  and I tell you the main components that I have drawn we have a notification service that has authentication rate limit then we have a user cash which features user details and then we have message you for like this notification events that we have delivery workers and then we have notification provider API so these are external provider API that we our delivery worker calls  and we have a rate limit cash and we have a memory cache with contain templates we also have notification logs the and we have a dlq that letter Q
I can see your diagram — it's quite detailed! You've got client services like Billing and Promotion calling the Notification Service, which then routes through Kafka queues to delivery workers, which call external providers like APNS, FCM, SendGrid, and Twilio. Nice inclusion of the User Cache, Rate Limit Cache, template cache, Notification Log, and Dead Letter Queue.

Let's dive deeper into the flow. Walk me through what happens step-by-step when the Billing Service sends a POST /notify request — what does the Notification Service do with that request before it reaches Kafka?

#
hello hello I will give you a Walkthrough  so yeah when one of our client like billing service calls our API post API notified then we just check from the user cash the user details like the name and  whether the user has unsubscribe as or not and so after that we check the rate limit on that request for that particular client and for that user also so we are not like sending to many notifications to a single user  and then after checking these authentication and rate limit and getting the user details we send that you went to a message you and then they are these these message  we have a single cube for SMS  SMS for exam we have a single cube for SMS provider like to live and then we have another q for another topic another topic for another provider like email providers and grid so we have per notification that means only that that means only that notifications will be stopped and and other notification will still continue to go
Good walkthrough. I notice you mentioned having separate Kafka topics per provider. What happens at the point where the Notification Service decides which Kafka topic to route a notification event to — how does it determine whether a notification should go to the SMS queue versus the email queue?

#
just after that I confuse the walk through like I haven't finish that yaar so after that the delivery worker like patches those events from the topic and it purchase it has the template in its memory it fills the tablet for example it has a name feels and IT field it fails with the correct name of the user and then it cause the notification provider API and and in case of success the notification is send by the provide and in case of like three event it just using the like so it doesn't Technology  locks the notification  in our notification lock  log hello ji
Got it, thanks for completing the walkthrough! So the delivery worker consumes from Kafka, fills in the template with user details, calls the provider API, and logs the result. And if all retries are exhausted, the event goes to the Dead Letter Queue — that's a solid flow.

Going back to my earlier question — how does the Notification Service decide which Kafka topic to route a particular notification to?

#
so it depends upon the client providers tells us like whether to send a sms notification or what type of notification to send and encase like we didn't we don't get sent to all types of notifications
So the client specifies the notification type in the request. That makes sense. What does the payload of that POST /notify request look like — what fields would the client need to include?

#
upi schema  specifications  so we will use http method post and then we have can have  in request body we will have
I see you've started writing out the API specification on the canvas. Go ahead and complete the request body — what fields would you include?

#
hello so in EPF we can have we will use http method post and then in request header we can use user will fill the idapotency key that is optional and then in request what do we will ask the user ID of the user to send to notification then notification time for example email SMS and template to use for example like a user login template or like us live sale notification template or we can also they can send values of custom fields like OTP
I can see your API spec on the canvas — that looks well thought out. The idempotency key in the header is a nice touch.

Let's dive deeper into the delivery worker side. You mentioned the delivery worker retries on failure and eventually sends to the DLQ. How does the retry mechanism work — what strategy would you use, and how many attempts before moving to the DLQ?

#
so in this case we are using notification we are unable to send a notification  provider is down  for example that to you services down then it will do a retract  and for example we have Max retrieve 3 times and in with an exponential back of then after after the field it will not do any further calls and it will send that you went in use the build in retrie mechanism  so we will not acknowledge the message received and it will do the retreat
Interesting — so you're leveraging Kafka's built-in retry mechanism by not acknowledging the message. What happens if the provider is down for an extended period — say 30 minutes? How would that affect the other messages waiting in the same Kafka topic?

#
so we can use switches  to make the delivery worker more resilient we can use suggest switch  so in case like we feel that we that there are more number of failures then the threshold then we can we can open the switch and we will not do any further  call to the notification provider and we will check after 13 time and try to attempt again and so we will like have all the state like open and check and then we have closed date also
Good thinking with the circuit breaker pattern. That would help prevent overwhelming a struggling provider.

Now let's shift to how this system handles scale. Looking at your current architecture, where do you see the potential bottlenecks as traffic grows beyond your estimated 200 requests/second peak?

#
so I think the notification service so we have made it stateless  so we can horizontal is scale that service  and kafka Kaka cues are like we know that cough card distributed and and can like a regulate and can like a beer heavy load so we can so we are good with that  and then we have delivery workers which are also stateless so we can scale them up also  so  so delivery workers which consume from the same topic so we can like at them in a same consumer group
Good points about horizontal scaling of stateless components and Kafka's distributed nature. You mentioned consumer groups for delivery workers — what happens if one notification provider (say Twilio for SMS) is significantly slower than others? How would that affect your system given your current queue-per-provider design?

#
yeah so in case one of the provider like to leave his down then it doesn't affect the other other delivery workers and a notifications to those channels will be sent in real time  so what we can do is like we can have like instead of Reliance on one provider we can send the notification using other providers also so we can use like we can in case of an OTP to user we can send them SMS and via email also  so it doesn't affect our means it will like so we have this circle breaker so that circuit will be open for that delivery worker it will not affect other delivery worker or other system
That's a good point about having fallback providers and channel redundancy.

Let me ask about a different aspect of scale — you have a User Cache and a Rate Limit Cache in your design. What happens if the User Cache goes down? How would that impact the overall system, and how would you handle that scenario?

#
so user cash is actually we need that because we we want to send personalized messages to user for example we want to say hi Shubham into the messages  so we can have user cash as a distributed cash and  with multiple notes of that cash and but in like a very rare scenario like hole of our cash is down all the distributed notes of that cash is down  then  we can only those type of notification which we can send which doesn't require the user  for example  I think  if we have this policy that we don't want to send notification  so I think the user cash is like mandatory in our design and it needs to be up all the time
That's an honest assessment. You mentioned it being a distributed cache with multiple nodes — that does improve availability. But you also have a User DB reader instance as a fallback for cache misses, which I can see in your diagram.

Let's talk about a different trade-off. You have notification logs in your design. What's the purpose of those logs, and how would you use them operationally?

#
ya so  we also want to keep track of a locks of our system logs l o g s of our system so that we don't that  we'll know will have a history to track like what all notifications have been sent to you sir
So it's essentially an audit trail for all notifications. How would you handle a scenario where a client service accidentally sends the same notification request twice — for example, the Billing Service sends a duplicate payment confirmation? You mentioned the idempotency key earlier — how would that work in practice through your system?

#
so we will check and our cash that we have that I Dam potential ki or not in case we have it  that means we will a block that notification  and so it has already been processed is the earlier one has been already been process so we don't have to duplicate send message to the user so this is how we use the potency key to know  avoid duplication of request
Good — so you'd store the idempotency key in a cache and check it before processing. That makes sense for deduplication.

Let's wrap up with some broader trade-offs. Looking at your overall design, if you had to choose between optimizing for higher delivery rates versus lower latency, which would you prioritize for this system and why?

#
I think I would optimise for higher delivery rate then for lower latency because I think most of the notifications are not that urgent we can have like few millisecond or like 1 5 seconds of Delhi and that is acceptable  delay  so I would privateise optimising for high delivery date over let and see  let and see
That's a well-reasoned trade-off — prioritizing delivery rate makes sense since most notifications can tolerate a few seconds of delay, and a missed notification is generally worse than a slightly delayed one.

One final question — you have an Analytics Service in your diagram. What kind of metrics would you track there, and how would that data be useful for the system's operations?

#
Aansu we want to We want to analyse some Matrix for example like the delivery rate and also we want to analyse user Behaviour for example what type of notifications are red and what time what type of notifications are ignored  and we can have a click event also like which notifications event which type of notifications user preparing and is actually giving as means it is so they are clicking on that link and they are watching that product and what percentage of product are converted to buy  so all this type of analytics that we want to analyse and also we want to analyse that what notification has we send that user has unsubscribe dust unsubscribe dust
Great thinking — tracking delivery rates, user engagement metrics like open rates and click-through rates, and unsubscribe patterns would all be valuable for optimizing the notification system over time.

Alright Shubham, that brings us to the end of our session. Here's a summary of your design:

Strengths:

Solid requirements gathering with clear functional and non-functional requirements
Well-structured API design with idempotency support
Good use of Kafka for decoupling with per-provider topics, enabling fault isolation
Smart inclusion of circuit breaker pattern for resilience against provider failures
Thoughtful caching strategy with User Cache, Rate Limit Cache, and template cache
DLQ for handling exhausted retries
Clear prioritization of delivery rate over latency with good reasoning
Areas to explore further:

Consider how you'd handle notification priority (e.g., OTP vs marketing) — would they share the same queues?
Think about how the system handles ordering guarantees — does it matter if notifications arrive out of order?
The monitoring and alerting side could be fleshed out more — what alerts would trigger operational action?
Overall, you demonstrated a solid understanding of distributed systems, fault tolerance, and scalability. Nice work!

#
hello before we end the interview I want you to read my interview on following criterias requirement gathering design problem solving scale and trade of communication and overall  on a scale of 1 to 10 1 to 10
Here's my evaluation of your performance:

Criteria	Score	Comments
Requirements Gathering	7/10	Good functional/non-functional requirements, estimations, and API spec. Could have explored more edge cases like notification priority levels and ordering guarantees.
Design	7/10	Solid architecture with well-chosen components — Kafka, caches, DLQ, separate topics per provider. The template-based approach was a nice touch. Could have explored the data model and schema design more deeply.
Problem Solving	7/10	Good instincts with circuit breaker, idempotency, and fallback providers. Handled failure scenarios reasonably well. The cache failure scenario could have been addressed more concretely.
Scale & Trade-offs	6/10	Identified horizontal scaling of stateless components and Kafka's distributed nature. Good trade-off reasoning on delivery rate vs latency. Could have gone deeper into partitioning strategies, consumer group scaling, and database scaling.
Communication	6/10	Diagram was comprehensive and covered the full flow. Walkthroughs were understandable but sometimes jumped between topics. Could be more structured and concise in verbal explanations.
Overall	7/10	A solid design with good fundamentals. You covered the core components well and showed awareness of resilience patterns. To improve, focus on deeper dives into scaling strategies and more structured communication of your thought process.
You

#
mis strong higher or higher or needs more improvement
Here's a breakdown:

Strong Areas (Your Best):

✅ Requirements Gathering — Clear, organized, covered both functional & non-functional
✅ System Design — Well-structured architecture with good component choices
✅ Problem Solving — Good resilience patterns (circuit breaker, DLQ, idempotency, retries)
Average (Solid but could be deeper):

⚡ Trade-offs — Good reasoning but surface-level on scaling specifics
Needs Improvement:

⚠️ Communication — Your verbal explanations were sometimes scattered and repetitive. Practice walking through flows in a more structured, step-by-step manner.
⚠️ Deep Dives on Scale — When asked about scaling, you stayed at a high level. Practice going deeper into topics like Kafka partitioning strategies, database sharding, cache eviction policies, and consumer scaling math.
Top 3 Tips to Improve:

Structure your walkthroughs — Use a clear "Step 1, Step 2, Step 3" format when explaining flows
Go deeper on scaling — Practice calculating partition counts, replica needs, and throughput per node
Anticipate failure scenarios proactively — Don't wait to be asked; bring up "what if X fails?" yourself during the design
You have strong design instincts, Shubham. Tightening up communication and depth on scaling would push you to an 8-9

#
what is the verdict of the interview
Based on your overall score of 7/10, here's my verdict:

🟡 Lean Hire / Borderline Pass

You demonstrated solid system design fundamentals — the architecture was sound, you made good technology choices, and you showed awareness of resilience and fault tolerance patterns. These are strong positives.

What held you back from a strong hire:

Communication clarity — interviewers need to follow your thinking easily
Lack of depth when probed on scaling specifics
Didn't proactively surface edge cases or failure scenarios
What would make this a clear hire:

Crisper, more structured verbal communication
Deeper scaling analysis with concrete numbers
Proactively discussing trade-offs without being prompted
You're close, Shubham. With focused practice on communication and scaling depth, you'd comfortably clear this bar. Keep at it! 💪