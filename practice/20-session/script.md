Design a food delivery platform like DoorDash that can handle restaurant management, order processing, delivery tracking, and real-time location updates.

Use the drawing canvas to the left to create diagrams, system architectures, and visual representations of your solutions. The problem statement has been added to the canvas to get you started.

Think out loud as you work through the problem, and don't hesitate to ask clarifying questions. This interview focuses on your ability to design scalable systems, communicate ideas visually, and think through real-world constraints and trade-offs. I'll guide you through the process and provide feedback at the end.

#
Can you share the question again?
Design a food delivery platform like DoorDash that can handle restaurant management, order processing, delivery tracking, and real-time location updates.

#
hi
Hi! Let's get started. Before jumping into the design, what do you think are the most important functional requirements for this food delivery platform?

#
hello so in this problem we have to design the food delivery platform so the problem State Design of food delivery platform like doordash that can handle restaurant management order processing delivery tracing and real-time location updates
Right, that's the problem statement. Now let's dig into the requirements before we start designing. What are the key users of this system, and what core actions would each type of user need to perform?

#
yeah before that I would like to list down items that we will discuss in this interview  so we'll cover functional requirements  non-functional requirements  and then we'll do estimations  and then we'll architecture  and then I'll give you a walk through  walkthrough of the other then we'll discard API  API design and DB schema  and then we'll talk about trade offs  and then at last we'll talk about login monitoring and alerts  and if time passes will also talk about our testing
I can see you've outlined that agenda on the canvas. That's a solid structure. Let's jump right in — what functional requirements would you identify for this food delivery platform?

#
yeah so if so  what  so let me think about the functional requirements so it says  and restaurant management or the processing delivery tracking  so I think first and foremost should be user should be  able to browse restaurant  brows and search restaurant
Good, that's a starting point. What other key actions should users be able to perform beyond browsing and searching for restaurants?

#
restaurants or food item  so search based on restaurant also is available or search based on food items should be available  and then  user should be  able to check menu  view menu  and then I create an order  from  restaurant  and then  a restaurant with payment  so are we going to I want to to ask a clarifying question so are we going to support the cash on delivery or is it going to be a front payment at the time of order creation
That's a great clarifying question. What do you think would be more practical for a platform like this, and how might that choice affect your system design?

#
I think to attract more customers we can provide cash on delivery options also
Okay, so you're supporting both online payment and cash on delivery. You've listed a few functional requirements on the canvas so far. What about the other actors in the system — what requirements would restaurants and delivery drivers have?

#
yeah okay and then  should we also support cancellation will be waste
That's worth considering — what do you think? How might cancellations impact the overall order flow and the different actors in the system?

#
hello  so I want to ask a question so should we also consider a cancellation of an order also because after the meal has been prepared if I user cancels that order  that or that meal  is waste
That's a thoughtful consideration. For the scope of this interview, what would you decide — and how would that influence the functional requirements you're listing?

#
I think  before the meal is prepared we should allow cancellation and after the meal is prepared we should not allow cancellation
That's a reasonable approach. Let's keep moving — you've covered some user-facing requirements. What functional requirements would you define for the restaurant side and the delivery driver side of the platform?

#
okay so I think I have written most of the functional requirements so users should be able to browse and search restaurants as well as food items users should be able to view the menu  and user should be able to create a order from a restaurant with payment and we should we will also support cash on delivery as a payment mode cancellations are only possible before the meal is prepared and track users should be able to track the order with real-time delivery status  and also the delivery location of the delivery boy
I can see those requirements on the canvas. You've covered the customer side well. But what about the restaurant's perspective — how do they manage their menus, receive orders, and update order status? And what about the delivery drivers — how do they get assigned and interact with the system?

#
okay  so should we also like the 3:00 p.m.  hello so should we also  in this interview should be also keep track of apis created on the admin side  or should we keep it as out of school for the interview
For this interview, let's focus on the core platform functionality. But I'd still like to understand — from a functional standpoint, how do restaurants and delivery drivers interact with the system during the order lifecycle?

#
Okay so  we can have admin side also  where
Go ahead — what would the admin/restaurant side need to do?

#
restaurant owners  can  list  add  delete  update  and item in menu
Good. Now you've covered user and restaurant requirements. What about the non-functional requirements — what qualities should this system have in terms of performance, availability, and scale?

#
should be able to  so restaurant owner should be able to register their restaurant on the platform and restaurant owner should be able to add delete or update an item on the in the menu  and so non-functional requirement include  what should be the highest Focus High availability  for the reads  and  scalable  I should handle High throughput  and resilient  I would say  so if any of the services goes down doesn't affect anything
Good, you've listed high availability for reads, scalability, and resilience. Before we move to the high-level design, what kind of scale are we designing for — how many users, orders per day, or restaurants are you envisioning?

#
what should be  okay so I'll do some estimations
Go ahead with your estimations.

#
on the restaurant side  so we have
Take your time with the estimations — what numbers are you thinking for restaurants, users, and orders?

#
let's assume we have 100K restaurants  and
Go on — what about the number of users and daily orders you'd expect?

#
let's assume each restaurant offers 50 items in their menu  and on user site we have daily active users  that is 1 million  or 10 million let's assume  and then  okay total users we can assume  10 million and daily active users is 50% of that that is 5 million  and then orders  per day  per user  we can assume like not everybody eats daily so we can assume 0.2 that is  one order  in 5 days  okay  so I went throughput  is roughly  10 million
I see you've written those estimations on the canvas. You have 100K restaurants, 50 items per restaurant, 10M total users, 5M DAU, and 0.2 orders per user per day. Can you walk me through how you arrived at that 10 million throughput number?

#
okay so I have done some estimations so we have a 100k  we have 100K total restaurants  and then we have a 50 menu items per restaurant  and total users is 10 million daily active users is 5 million orders per day per user is 0.2 that is one order in every 5 days  then every throughput is  10 into 10 past 6 into 0.2 that is 2 million orders per day  and  which is roughly equals to 20 orders per second  and Peak throughput is 40 orders per second and we can assume Marie to write ratio is 10 ratio 1  so Peak throughput is 400 reads per second  400 reads per second
Those estimations look reasonable — 20 orders/sec average, 40 at peak, and 400 reads/sec at peak. Now let's start with the high-level design. Can you sketch out the overall system architecture on the canvas showing the major components and how they connect?

#
hello  I would like to  make a  functionality that is out of scope is like Dynamic pricing we are not supporting Dynamic pricing of orders are now
Noted. Let's move forward — can you start sketching the high-level architecture on the canvas?

#
hello
Let's get into the design — can you start drawing the major components of your system architecture on the canvas?

#
hello  diagram  hello I have drawn the diagram
I can see your diagram on the canvas. You have quite a detailed architecture with clients (buyer and restaurant owner), API Gateway with AuthN/AuthZ/RateLimit, and several services including Restaurant Write Service, Order Service, Payment Service, Delivery Service, and Notification Service, along with their respective databases and caches.

Let's walk through this. Can you start by walking me through the order creation flow — what happens from when a user places an order to when it reaches the restaurant?

#
before order creation flow I would like to give you a walk through of restaurant  flow so we are at a restaurant owners are able to create update or delete their restaurant  in the platform and also they should be able to create update delete the item in a restaurant menu  so restaurant owner request reaches the API Gateway then restaurant right service restaurant right service registers meets create an entry in the restaurant DB about a new restaurant creation  and then then restaurant owners actually add items for that restaurant so it also goes by a restaurant ride service and so we have like a restaurant have multiple menu items  so in this way we have two restaurant right is a crud service on a restaurant and restaurant menu items okay  and then I would like to give you walk through of that you requested that is order placement  order creation flow  so then there are buyers  buyers should be able to create an order so so before creation actually he should be able to browse those service  and so he can use  so what we can do is like we can create a CDC pipeline over the restaurant readers instance and so  I'll draw that just give me a give me one more minute
Take your time — I can see you have a restaurant reader instance with replication from the writer. I'll wait for you to complete the diagram before we continue the walkthrough.

#
okay hello I have drawn the diagram  so we have a sub service so the cell service is built on  restaurant DB redial instance so there's a debesium connector that read wall locks from the DB and put those events into Kafka then there is a upload worker that actually uploads those events into an AWS elastic search so  AWS elasticity we are using as an index search and  so people can view like do a search based on restaurant names and dishes  and as well as ratings so then so now we have a list of items in the to be seen to the users based on such users click one of the restaurant and opens that so then it actually calls a restaurant read service so restaurant read Service reads from the restaurant cash and in case of a cash message  cash Miss  then it reads from the reader instance  okay so in this way so now restaurant now user has the information about restaurant and its menu  user add those items in the cart this is all front and we and after when he actually do a checkout and  is on the order please so that request actually goes to an order DB and Order DB creates an idea returns and I couldn't see key to the user so it actually creates a pending order in order DB  and so now using that order ID  the restaurants are the user go the payment flow actually opens and user dues by payment flow user does payment using the payment service so payment service  communicate with an external payment provider like PayPal or stripe and it actually keeps the status  in a payments TV  and so payment DB has an order ID as well as a payment status so I have not drawn that in the  diagram  but there's a payment DB with pending payment status so now the payment external payment provider informs the payment status via book endpoint also we have a async job that is also fetches the payment status from the external payment provider  so we are doubly sure that also  and after a payment is done payment service inform the order service about the payment status and Order service updates the payment status of the order and then this restaurant service  or the notification service informs the user about the order  okay so now we have an order and use the restaurant owner is also informed about in order so he start working on that order  and also the delivery service also playing row so delivery service based on the Kafka event it also search send it also so there's a delivery person location cash  so so it starts via people around those restaurant  and sends notification to those delivery workers so one of the delivery workers actually accept that request delivery request so delivery service actually creates a delivery  delivery means creates an entry in the delivery DB  so now we know that this delivery is being accepted by this person  I'll give you a walk through I will continue my work through
I can see the detailed flow on your diagram. You've covered a lot — the restaurant CRUD flow, the CDC pipeline with Debezium to Kafka to Elasticsearch for search, the order creation with pending payment status, payment processing with webhooks and async polling, and delivery assignment using location-based matching.

Let me ask about one specific connection — how does the delivery person's real-time location get updated in the system, and how does the customer track the delivery in real time?

#
so yeah so as I told you there's a delivery person location cash  so cash it is a reddish cash  Cash c a c h e  okay  and so every time when I delivery persons is changing its location so he's moving towards the restaurant to pick that order  so his location  so  I think we can have a Web book or not fair book  we can we will have websockets so so our user the delivery worker  I'm sorry it's delivery worker so our delivery worker is connected to a websocket so and every time it updates its location the websocket to fetches the location means it gets the location and updates in the delivery person cash
So the delivery worker sends location updates via WebSocket, and those get stored in the Redis cache. How does the customer on the other end receive those real-time location updates to track their delivery?

#
so  so interest cash  so we know that this order is linked to this delivery ID  and  and it also we know that this delivery ID has this user delivery boy assigned  and so  and we will get the delivery boy live location from the delivery person cash  delivery person live location class cash  so whenever the user who is the buyer of that order seize means  he can also fetch from that cash
So the customer polls the delivery person's location from the cache. Would the customer be polling periodically, or would you use a different mechanism to push those updates to the customer in real time?

#
I think if the person is online and is actually  looking at the app then we can start service and events SSE  servers and events  so which are so server can actually send the live location to the user who is the buyer in this case
Interesting — so you're using WebSockets for the delivery driver to send location updates, and SSE for pushing those updates to the customer. Let's move on to scaling and trade-offs. Looking at your architecture, what do you think would be the primary bottlenecks as the system scales, and how would you address them?

#
no so since we are using  websockets so as the as the system grows  means as it scales we actually need more websocket servers  so I think that would be the first bottleneck
What approach would you take to scale those WebSocket servers, and how would you handle the challenge of routing messages to the correct server when you have multiple instances?

#
should I draw I haven't drawn that websocket  server approach so should I draw that
Yes, please go ahead and sketch out how the WebSocket servers would work and scale in your architecture.

#
okay okay so I have drawn to websocket gateways websocket so the delivery worker is connected to a websocket a then we have a presence registry that actually knows that which user or which delivery guy is actually connected to which websocket Gateway number  so whenever you are delivery worker moves his he actually informs the server via websocket Gateway that this is his correct location the location service updates that in the location cash and also it also know the connected like what is the user ID of the person who is the buyer it fetches from the presence registry and it actually sends that location of the delivery boy to the websocket Gateway of the buyer  so in this way we have both buyer and seller both buyer and delivery guy I'm so both buyer and delivery guy not seller are connected to the websocket Gateway and so every location of that delivery guys sent to  a buyer via using those websockets
I can see the WebSocket gateway setup with the presence registry on the canvas. That's a solid approach for routing messages to the right connection. Beyond the WebSocket scaling, what other bottlenecks do you see in your system, and what trade-offs have you made in your overall design?

#
I think the other bottleneck would be databases  so that's why we have a writer instance and a reader instance so reader instance is actually a replica secondary of the primary DB  so it actually does a replication from the primary database and then also we have caches that actually reads from the reader instance so the load on the database is less now  also we can use sharding  based on restaurants or like I would say I would say we should start based on cities  so now each database has less amount of less each child have less a portion of the total restaurants that are in our platform
You've mentioned read replicas, caching, and sharding by city. That's a reasonable scaling strategy. What trade-off does the replication approach introduce, particularly around data consistency between the writer and reader instances?

#
so  so replication takes time  so that's why there's a data inconsistency between the reader and writer instance
Right, so you're accepting eventual consistency for reads. Is that acceptable for all parts of your system, or are there specific flows where you'd need stronger consistency guarantees?

#
hello  yes I would say this is acceptable because a restaurant and restaurant menus  really changes means  they're updates they don't frequently updates  and also in case order during order we actually read from the writer instance not from the reader instance
That's a good distinction — eventual consistency is fine for restaurant/menu data since it rarely changes, but you read from the writer instance for orders where accuracy is critical.

Looking at your overall design, are there any other trade-offs or potential failure scenarios you'd want to address, such as what happens if the payment service or notification service goes down during an order?

#
in case the payment service actually goes down  that's why we actually have already set the status of payments in the payment DB as pending  so in case it's good the payment service goes down so when it wake UPS it actually it can it has an async job that actually feds the payment status from the external payment provider  so so that we are sure about all the payment statuses of pending payments
That's a good resilience pattern — the async job acts as a recovery mechanism for pending payments. We're nearing the end of our time. Looking at your complete design, what would you prioritize for logging, monitoring, and alerting to ensure this system runs reliably in production?

#
yeah before logging I discussed about like a so we have completed functional requirements non-functional requirement estimation architecture I have given you walk through and we have discussed trade-offs also I think in in the diagram we have talked about the DB also like DB skiba so in database we have  restaurant menu items then we have order payment user  and then in case we have a presence registry  and a delivery boy DB that contains delivery voice name and all these details  and so we haven't discussed about API design  if we if we get time we can discuss that about logging monitoring and alert I would say  so we can for logging we can use external  log solution for example data dog or neuralic  or we can also use  Splunk for logs  for monitoring  we can create alerts we can monitor  for each service we can monitor  the percentage CPU utilization throughput error rate latency  as well as resource utilization parameters  on we have used Kafka so we can  we should monitor  number of number of replications  less than that required replication Factor we should also monitor about  bites in and bites out that is the throughput we should also monitor about consumer lag  for databases we should monitor about index size and database size cost of all this thing  for websockets I think we should also monitor about each of their health status  their resource parameters  and we should have we should set up alerts on all those  I'm on latency at a rate and throughput ency
That's a comprehensive monitoring strategy covering service-level metrics, Kafka-specific monitoring, database health, and WebSocket status. You've demonstrated solid thinking across the entire design.

To wrap up, you've built a well-structured food delivery platform with clear separation of concerns — restaurant management with CDC-based search indexing, order processing with payment resilience, real-time delivery tracking via WebSockets with a presence registry, and scaling strategies using read replicas, caching, and sharding. Your awareness of trade-offs like eventual consistency for reads versus strong consistency for orders shows good distributed systems thinking.

If we had more time, it would be worth exploring the API design you mentioned, as well as how you'd handle edge cases like delivery driver reassignment if a driver becomes unavailable mid-delivery. Great job overall!

#
before we end the interview I want you to read on these following parameters requirement Gathering design problem solving scale and trade off communication overall on a scale of 0 to 10
I'm here to conduct a system design interview. Let's focus on your design approach.

That said, our interview is now complete. Here's a summary of what you demonstrated well:

Requirements Gathering: You systematically identified functional and non-functional requirements, asked good clarifying questions (cash on delivery, cancellation policy, dynamic pricing scope), and provided reasonable estimations.

Design: You built a comprehensive architecture with well-separated services, thoughtful data flow patterns (CDC with Debezium, Kafka for event streaming), and appropriate technology choices (Redis caching, Elasticsearch for search, S3 with pre-signed URLs for image uploads).

Problem Solving: You addressed payment resilience with async polling and webhook dual mechanisms, handled real-time tracking with WebSockets and a presence registry, and designed an image processing pipeline.

Scale & Trade-offs: You identified key bottlenecks and applied read replicas, caching, and sharding. You articulated the eventual consistency trade-off well and knew when strong consistency was needed (order writes).

Communication: You structured the interview with a clear agenda, walked through flows systematically, and used the canvas extensively to communicate your ideas visually.

For areas of improvement, consider spending more time on failure scenarios, edge cases like delivery reassignment, and API contract design. Also, being more concise in verbal explanations would help manage interview time more efficiently.

Overall, this was a strong performance. Best of luck!

#
I want you to rate me on a scale of 0 to 10  on these following parameters requirement Gathering  design problem solving scale and trade-offs communication and overall performance
Here's my assessment:

Parameter	Rating
Requirements Gathering	7/10 — Good clarifying questions and structured approach, but could have explored delivery driver requirements and edge cases more thoroughly
Design	8/10 — Comprehensive architecture with well-chosen patterns (CDC, event streaming, pre-signed URLs, image processing pipeline). Strong separation of concerns across services
Problem Solving	7/10 — Solid payment resilience strategy and real-time tracking solution. Could have explored more failure scenarios and edge cases like driver reassignment or restaurant order rejection
Scale & Trade-offs	6/10 — Identified read replicas, caching, and sharding but discussion stayed relatively surface-level. Could have gone deeper into capacity planning, load balancing strategies, and consistency model trade-offs
Communication	7/10 — Great use of the canvas with detailed diagrams and a structured agenda. Verbal explanations were sometimes repetitive and could be more concise
Overall	7/10 — Strong performance demonstrating solid system design fundamentals with a well-structured approach. Deeper exploration of failure modes, edge cases, and scaling strategies would elevate this further
Best of luck with your interviews!

#
also what would be the interview verdict  is it going to be  borderline lean higher or needs Improvement  or stronger
Based on your performance, I'd place you at Lean Hire.

Reasoning: You demonstrated solid fundamentals — structured approach, comprehensive architecture, good use of visual diagrams, and awareness of key distributed systems concepts. Your design covered all major components with reasonable technology choices and data flow patterns.

What kept it from Strong Hire:

Trade-off discussions lacked depth
Missing edge cases and failure scenarios
Limited exploration of delivery driver workflows
Some verbal explanations were lengthy and repetitive
What would push you to Strong Hire:

Proactively discussing failure modes without being prompted
Deeper analysis of consistency models and their implications
More thorough API design and data model discussion
Crisper, more concise communication
Exploring edge cases like concurrent order updates, driver unavailability, or restaurant going offline mid-order
You're close — with more depth in trade-offs and edge case handling, this would comfortably be a Strong Hire. Keep practicing!

#
okay  any tips from today's interview that should I work on for my next interview
Here are my top tips based on today's interview:

1. Be Concise

You often repeated the same point multiple times. Practice explaining concepts once, clearly, and moving on. This saves valuable interview time.
2. Drive Edge Cases Proactively

Don't wait for the interviewer to ask about failures. Proactively address: "What happens if this service goes down?" or "What if two drivers accept the same order?" This signals senior-level thinking.
3. Deepen Your Trade-off Discussions

Instead of just stating "we use replication," explain the quantitative impact — what's the replication lag, how does it affect user experience, and what alternatives did you consider and reject.
4. Cover All Actors Equally

You focused heavily on the buyer and restaurant side but the delivery driver workflow was underdeveloped. Practice giving balanced coverage to all actors in the system.
5. Prepare API Contracts

Have a structured approach ready for API design. Quickly listing key endpoints with request/response schemas shows completeness.
6. Time Management

You spent significant time on requirements and walkthroughs. Practice allocating time so you can cover scaling and trade-offs more deeply — that's where interviewers differentiate candidates.
7. Practice the "What Could Go Wrong" Mindset

For every component you draw, mentally ask: what if this fails, what if this gets overloaded, what if there's a race condition? Then briefly address it.
Keep iterating — you have a strong

#
also  can you mention some of the things that I do  good at or like  should or should continue doing that
Absolutely! Here are your strengths that you should keep doing:

1. Structured Interview Approach

You laid out a clear agenda upfront (requirements → estimations → architecture → walkthrough → trade-offs → monitoring). This shows maturity and keeps the interview organized. Keep this.
2. Asking Clarifying Questions

You proactively asked about cash on delivery, cancellation policies, and scoping out dynamic pricing. This shows you think before you design. Excellent habit.
3. Strong Visual Communication

Your diagram was detailed and comprehensive with clear labels, arrows showing data flow direction, and annotations explaining interactions. Many candidates underuse the canvas — you didn't.
4. Back-of-Envelope Estimations

You methodically calculated throughput from DAU to orders per second to peak read throughput. This grounded your design in real numbers rather than guesswork.
5. Resilience Thinking

Your dual mechanism for payment verification (webhook + async polling) was a standout moment. It showed you think about reliability naturally.
6. Smart Technology Choices

CDC with Debezium, Kafka for event streaming, pre-signed URLs for image uploads, Redis for caching, Elasticsearch for search — all well-justified and appropriate choices.
7. Read/Write Separation Awareness

Knowing when to read from writer instance (orders) versus reader instance (restaurant data) showed strong consistency model understanding.
These are genuine strengths — they form a solid foundation. Keep building on them!