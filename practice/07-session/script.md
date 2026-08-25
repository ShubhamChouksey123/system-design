Welcome to your system design interview! Here's your design challenge:

Design a distributed rate limiting system that can protect APIs from abuse while ensuring fair usage across different clients and maintaining high performance.

Use the drawing canvas to the left to create diagrams, system architectures, and visual representations of your solutions. The problem statement has been added to the canvas to get you started.

Think out loud as you work through the problem, and don't hesitate to ask clarifying questions. This interview focuses on your ability to design scalable systems, communicate ideas visually, and think through real-world constraints and trade-offs. I'll guide you through the process and provide feedback at the end.

#
hello  hello I am Shubham and I can see your question on the whiteboard it's a design and API rate limit design and distributed rate limiting system that that can protect API from abuse while ensuring fair uses across different clients and maintaining hyperformance
Hi Shubham, great to have you here! Let's dive in.

Before we start designing, let's make sure we understand the problem well. What do you see as the key functional requirements for this distributed rate limiting system?

#
I list down requirements for  distributed rate limiting system
Go ahead, I'd love to hear what requirements you've identified.

#
should protect from abuse so eat  client  should  get a  fixed number of request
I can see you've started writing down the functional requirements on the board — each client getting a fixed number of requests is a good starting point.

What other functional requirements would you consider important for this system?

#
hello so one function requirement that I consider is like each climate is allowed to make a maximum  fixed number of request like 200 request within a rolling time frame of Excise for example like 1 million second so each client can make maximum of 200 request in one second and after 1 second he can make another request so this can be a function requirement
That's a clear functional requirement. A couple of things I'd like to understand better — when you say "each client," how are you thinking about identifying or distinguishing between different clients?

#
by each client I mean set of users  that are in the same  that share the same contract for example like in case of a business organisation so this business organisation can can do this 200 request in one second it can be a single user also for example like in case of  like personal  personal applications so each user is actually an individual client  so we can identify each client either by using a client ID  or a user ID in case
Good, so clients could be identified by a client ID or user ID. Now, you've listed some non-functional requirements on the board as well — high throughput, high availability, fault tolerance, scalability, and fast. Could you elaborate on what you think is the most critical non-functional requirement for a rate limiting system and why?

#
the most important  I think the most important should be like it should be able to be a high throughput  and it should be highly available  and fault tolerant by Fall talent I mean in case like any of the instant go down if it comes up it should like  it should pick  easily  it should wake up easily like it should not  it should be stateless
Interesting — you mentioned the system should be stateless for fault tolerance. But given that rate limiting inherently requires tracking request counts per client, how do you reconcile that with a stateless design?

#
I think  I'm not sure like how we can make it stateless  but other non-functional requirements are like it should be scalable it should be fast and it should do near accurate calculation in terms of count of request per client
Good catch on the "near accurate" point — that's an interesting design decision. I can see you've captured these requirements on the board nicely.

Now that we have a solid understanding of the requirements, let's start with the high-level design. Can you sketch out the major components of this system and how they connect on the diagram?

#
before that I'll make some estimations
Sure, go ahead with your estimations.

#
also I have did some calculations so we have a total clients let's assume we have 10 million clients and daily active clients are 50% that is 5 million  and then request sent by each client party is 1000
I can see your estimations on the board. You've calculated roughly 50K QPS average and 100K QPS at peak, with about 100-200 instances needed. Those are reasonable back-of-envelope numbers.

Now let's move to the high-level design — can you sketch out the major components of this distributed rate limiting system on the diagram?

#
hello hello  I think you already read my calculation and you got it like what time do  so yeah we we need a 200 instances and peek through both of like 100K per second  so I'll do other diagrams
Sounds good, go ahead and sketch out the high-level architecture on the board!

#
actually I just missed like few functional requirements I have written them so so we talked about like each client is allowed to make maximum of fixed number of request within a ruling time frame or fix size so when I rate limit is reached for that client in that time window we should return HTTP status code 429 that is too many requests and we should also return retry after this time headed to the response header to the client and we should block all request newer request for this client in this time window
Good additions — the 429 status code, Retry-After header, and blocking behavior are important details. I can see you've captured those on the board.

Now let's move to the high-level design — can you start sketching the architecture on the diagram?

#
hello I have done the diagram
I can see your diagram. You have clients connecting to a Rate Limiting Service, which reads request counts from a Cache and falls back to a Database on cache miss. You also have an "Update Tokens Job" that writes token counts to both the Database and Cache. The Rate Limiting Service then forwards allowed requests to a Backend Service.

Walk me through the flow — what happens step by step when a client sends a request to your system?

#
so I give you a Walkthrough  so for example the client hit any of the gate or post TPA or like any http any type of API  that that comes to our rate limiting service so rate limiting service first checks that whether this user is a valid user and if it is a valid user then what is the number of request remaining that it can make in this window so it patches it's tried to patches that request the data from the cash and if it doesn't found that is the date from the database  and so we have like for example like we have like in our satellite we have request in 1 milli second so for example this is a new client that has not any request in this second one second  is too small  to block the request
I see the flow you've described. You mentioned checking if the user is valid and then checking remaining requests. A couple of things I want to probe on — you mentioned the Rate Limiting Service reads from the cache first, then the database on a cache miss. But I notice step 3 shows "increment total request by client" going to the cache.

What happens to the request count in the database — how and when does it get updated?

#
name and created at and  I think we should keep the client ID and request remaining
I see you're thinking about the schema — client ID and requests remaining. But let me bring you back to the data flow question: when a request comes in and you increment the count in the cache, how does that data eventually make it to the database to stay consistent?

#
for example hello  so for example
Take your time — walk me through how the cache and database stay in sync.

#
hello  yeah I will give you a walk through so whenever request our rate limiting service first checks the user information and the request remaining for that client in that window from the cash if there is a cash miss then it patches the details user details and remaining request in that window from the database so and then if it if the number remaining request is still  greater than zero that means it will  it will decrease decrease the amount of remaining request by  one and it will it will put that data in cash  and the next time it actually read from the cash  and so the remaining request is greater than zero so it allows that request to the back and service  and then back and service will do that processing on its side and return service and rate limiting service will return to the user  so in case the remaining request is zero so in that time frame request has utilised all its request so that is like 200 request it has utilised in one second so in that one the cash that the user is still in the cash and it she is request remaining is zero so it blocks that user and user is return with 4 to 9  4 2 9  http status code that is too many request and Retreat after this one like the fraction of second
Good walkthrough. So the cache is your primary store for request counts during the active window. I notice you have an "Update Tokens Job" in your diagram that writes to both the database and cache.

What is the role of this Update Tokens Job — when does it run and what exactly does it do?

#
so update  so I told you we have a threshold of 200 request per second so after each second we have to update the remaining number of request all the remaining request 200 in database and it also updates value in the cash so for all the clients that are in the cash show it updates them for all the total clients in the database it does that
So the Update Tokens Job resets the request quota back to 200 for all clients every second. That's a lot of writes — you mentioned 10 million total clients.

How would this job handle updating 10 million records in the database every single second?

#
we can't do this much of right SQL inside queries per second to the database
Right, that's a significant challenge. So how would you address this — what alternative approach might you consider for resetting the quotas?

#
I think registered of Counting request remaining we should like count total request percline that would be easy because only the clients that are making request will be affected and not the total clients
That's a good insight — tracking only the clients making requests rather than resetting all clients. So now instead of resetting 10 million records, you're only writing for active clients in that window.

But with a 1-second window, how would you determine when a client's count should be reset or considered stale?

#
I think one way to do that is is we can like in the cash we can have client ID the total the time I'm sorry I will repeat it again so in the scheme cash we will write the client ID the total request  in that one second internal in that one interval fix time will do and then the time window start time  so the update to update all the to update all the means total request 20 so after each second it actually does like total count 20
I see — so you're storing the window start time alongside the count. That way, when a new request comes in, you could check if the current time is still within that window or if a new window has started.

But you still mentioned the Update Tokens Job resetting counts. Could there be a way to handle the reset without a background job — just using the timestamp you're already storing?

#
20 correct so we don't need the update token job
Exactly — if the Rate Limiting Service checks the window start time on each request and lazily resets the count when a new window begins, you eliminate the need for that background job entirely.

Can you update your diagram to reflect this change?

#
yeah I will update the diagram
Go ahead and update the diagram — I'll take a look once you're done.

#
so yeah so the cash keema will look like we have table in which we have columns user ID the windows start time and total request so I will give you a walk through again so so whenever we get a new so we have a new client that just register so it is his first request it reaches to the rate limiting service it checks that the user details are found in cash or not It is a cash the details from the database and it it do and agreement in total request and the start time  window and then it saves the data in cash so the next request so we know the windows start time and the current time and Windows start time is less than 1 second so we are sure that this is the same window so we just increase the total request so similarly the next request within the same one second so we know that this current time minus Windows start time is less than 1 second so we increase the total request count by one so in this way we are actually increasing the total request come and if we see that the count is greater than that 200 threshold for a 1 second so we block that request  otherwise we pass that request to the vacant service
Good walkthrough — that's a much cleaner design without the background job. The lazy evaluation approach handles the window reset naturally.

Now let's dive deeper into a critical aspect of your design. You have multiple instances of the Rate Limiting Service — what happens if two requests from the same client hit two different instances at the same time?

#
so that's why we have so in case are two different the rate limiting instance gets the request from same client so it that case we have a distributed cash so we have to make sure that the user id request reaches the same cash each time so we will do consistence consistence hasing  on rate limiting sites so our each request each user id request actually
So you're using consistent hashing to route requests from the same client to the same cache node. That addresses the routing, but what happens if two requests from the same client arrive at two different Rate Limiting Service instances simultaneously — even though they'll hit the same cache node, could there be a race condition when reading and incrementing the count?

#
yeah there is condition for example both of them red the same total request and both try to increase the total request count and so for our case we will not bother so we will focus on like it is we will not focus on highly consistent because that will increase our means if we go with transaction that then that will increase our time means it will increase the late and see we want to be near accurate we don't want to be 100% accurate so that's why we will like there can be message people can be more number of request in the window so we can take this  so this can be drawback but  we actually want to be highly available  and fast so we will compromise on this the actual count of total request
That's a thoughtful trade-off — you're explicitly choosing availability and speed over strict accuracy, which aligns with your non-functional requirement of "near accurate." Good reasoning.

Now let's talk about the cache itself. What happens if a cache node goes down — how does that affect your rate limiting?

#
in case not goes down  so actually  I will think about it like what happens a cash note goes down  so in case of cash like cash note goes down so all the request that all the request date of means all the clients data that actually is present in that cash so will be lost for that window and also the next request will actually have to fetch the user details from the database so we are slightly higher latency for that next request but after that we have a distributed cash so another note will pick up and will  take it place  and it will now have the new or data for that user ID
So you'd accept losing the count data for that window and falling back to the database. That means some clients might get extra requests through during that brief period.

Let's shift to another aspect — I notice there's no load balancer in your diagram between the clients and the Rate Limiting Service instances. How do client requests get routed to the 200 instances you estimated?

#
I know that Load Balancer wins my thinking was like we can have a Load Balancer with limiting  so the rate limiting services actually allowed by answer with relative feature  but to be more concise I like I love dated
Go ahead and add the load balancer to your diagram. How would you position it in the flow?

#
so I have added the API get well Load Balancer  so which seats in front of a rate limiting service
I can see you've added the API Gateway between the clients and the Rate Limiting Service.

Now, you mentioned earlier using consistent hashing to ensure the same client's requests go to the same cache node. But the API Gateway is distributing requests across your Rate Limiting Service instances — does the gateway need any special routing logic, or can it distribute requests freely across instances?

#
yeah for forever cashing to work like we to have like most cash literature so we have to write the request to the same rate limiting service so we can have the same consistents hasing function in the API Gateway also
Interesting — so you're using consistent hashing at the API Gateway level to route a client's requests to the same Rate Limiting Service instance. But then if that specific Rate Limiting Service instance goes down, what happens to all the clients that were routed to it?

#
I think we can merge these if I get to and rate limit limiting service so API gateway has one more function that is to rate Limited late limit will not have like two different things
So you're thinking of combining the API Gateway and Rate Limiting Service into a single component. That simplifies the architecture, but then each instance would need to access the shared distributed cache to check rate limits.

If the rate limiting logic is now in the API Gateway itself, do you still need consistent hashing to route requests, or could any gateway instance handle any client's request since the state lives in the distributed cache?

#
I think we don't need constance hatching here
Right — since the distributed cache is the source of truth for request counts, any gateway instance can handle any client's request. That also makes your system more resilient since there's no dependency on a specific instance.

Let's move to scaling and trade-offs. Looking at your current design, where do you see the biggest bottleneck in this system at 100K QPS peak?

#
I think the biggest bottle neck is on database so increase like we have cash Mrs so there will be so we will have a lot of queries on database like to read queries on database so will have to increase read replicas of the database
You mentioned cache misses hitting the database. At 100K QPS, even a small cache miss rate could overwhelm the database.

What cache miss rate would you expect, and what strategies could you use to minimize it beyond just adding read replicas?

#
will have to make sure like all the uses information reside in cash
If you want all active client data in the cache, you mentioned 5 million daily active clients. Have you considered how much memory that would require in your distributed cache, and how many cache nodes you'd need?

#
we can do that calculation  but for now let's as you like we have  we have a lot of distributed cases instances
Fair enough. Let's consider another scaling concern — your distributed cache is now handling reads and writes for every single API request at 100K QPS. What happens if the cache itself becomes a bottleneck?

#
so we can use  LF you cash lease frequently used cash  to evict as a casting strategy
Eviction strategy helps manage memory, but my question is more about throughput — if 100K requests per second are all hitting the cache for reads and writes, how would you ensure the cache layer can handle that load?

#
will increase the number of cash like when the throat increase and similarly we can scale the API Gateway rate limiting service
Right, horizontal scaling of the cache. Now let's think about a different trade-off — you chose a fixed window approach for rate limiting. What could go wrong at the boundary of two consecutive windows?

#
so we discuss like will use like a throat threshold of 200 request per second so so it case of fix size Window for example like one millisecond so people can miss you this I am sorry one second  so people can have like more than 200 request in 1 second interval like during the boundaries for example we have like 200 request and on the first half of next one second we have to under request then on that particular one second I'll like the second half of 1st 2nd and the first half of second second so we have like 400 request so we have 400 request and like this  time frame like to consecutive Windows so that is actually drawback of this like fix bucket having a fixed bucket
Exactly — the boundary problem where a client could potentially send 400 requests in a 1-second span across two windows.

How would you address this issue in your design?

#
how can we address that we can increase reduce we can sorry we can reduce the time frame window like  so each window like so if our window size small we can have like  we can reduce the issue
Reducing the window size would reduce the burst at boundaries, but it wouldn't eliminate the problem entirely. Are there any alternative windowing approaches you've considered that might handle this more gracefully?

#
currently accounting about any other algorithm to solve this issue
That's okay. Let me ask about another trade-off in your design. You mentioned you're okay with "near accurate" counts. In what scenarios could inaccurate counts become a real problem for your clients, and how much inaccuracy would be acceptable?

#
so for example it two request read the same total request with the same window start time and both of them updates the total request count  so one of them overrides the other  so for example we have 100 count and the first request changes to 101 and the second is also trying to change it to 101 so both of them actually save the data to 101 but the actual should be 102 so  this and are you we can have like incorrect data
Right, that's the race condition we discussed earlier. You mentioned you'd accept this inaccuracy. But consider this — if a malicious client intentionally sends many concurrent requests to exploit this race condition, could they significantly exceed their rate limit?

#
so when we have reached conditions I am not sure about this
That's fair. Let me shift to another important aspect — in your current design, what happens if the entire cache layer goes down temporarily? All requests would hit the database, which you identified as a bottleneck. How would you handle this failure scenario to maintain your availability requirement?

#
that is the risk that we take like we have to make sure that the cache is available we can't hit the database every timen
So the cache is essentially a critical dependency. Given that, what measures would you put in place to ensure the cache layer itself is highly available?

#
for cash to be high level we can use some managed cash service  so that will give us a like highly available and fall tolerant cash distributed cash
Okay, relying on a managed service for high availability makes sense from an operational perspective.

Let me ask one final question — if the cache and database are both unreachable for a brief period, should the system fail open (allow all requests through) or fail closed (block all requests)? What's your reasoning?

#
it really depends up on the type of system for example if the bacon service that we are serving is a is a banking application or  is a government application that needs to be secure than we should block all request but if our application is like colour learning platform  so we can actually allow all the request
That's a great nuanced answer — the fail-open vs fail-closed decision really does depend on the business context and risk tolerance.

Alright Shubham, let's wrap up. You've covered a lot of ground — from requirements and estimations, to a high-level architecture with API Gateway, distributed cache, and database, through to trade-offs around consistency, the fixed window boundary problem, and failure modes.

A few strengths I noticed:

Good identification of the lazy evaluation approach to eliminate the background job
Clear reasoning about the availability vs accuracy trade-off
Thoughtful consideration of failure scenarios
Areas you might want to explore further:

Alternative rate limiting algorithms (like sliding window) to address the boundary problem
Strategies to handle race conditions, especially against malicious clients
More detailed cache resilience planning given it's a critical dependency
Thanks for the interview, Shubham! Do you have any questions for me?

#
before before we and this interview I want to you to make to rate my interview  based on these for like following criteria for a scale of 1 to 10  and these criterias are required requirement gathering design problems solving scale and trade of communication and overall
Here's my assessment of your interview:

Criteria	Rating (1-10)	Comments
Requirements Gathering	7	You identified solid functional requirements (fixed window, 429 status, Retry-After header) and non-functional requirements. Good back-of-envelope estimations. Could have explored more around different rate limiting strategies, multi-tier rate limits, or client-specific quotas.
Design	6	You arrived at a reasonable architecture with API Gateway, distributed cache, and database. Good evolution when you eliminated the Update Tokens Job in favor of lazy evaluation. However, the design could have been more detailed — missing load balancer initially, and the cache-database sync strategy remained somewhat unclear.
Problem Solving	5	You identified key issues like the race condition and fixed window boundary problem, but struggled to propose solutions for them. The consistent hashing idea was initially introduced then correctly abandoned, showing good self-correction. However, when faced with harder problems (race conditions, sliding window), you weren't able to push through.
Scale & Trade-offs	6	Good articulation of the availability vs accuracy trade-off and the fail-open vs fail-closed decision. You identified the database as a bottleneck. However, cache scaling strategies and resilience planning could have been deeper.
Communication	6	You used the whiteboard effectively for requirements and estimations. Walkthroughs were clear but sometimes repetitive. The diagram could have been cleaner with updated components after design
#
okay and what is your final verdict
Overall Rating: 6/10

Verdict: Lean Hire (with reservations)

You demonstrated solid fundamentals — good requirements gathering, reasonable estimations, and a workable architecture. Your ability to self-correct (removing the Update Tokens Job, dropping consistent hashing) shows good design instinct.

However, for a distributed rate limiting system, there were notable gaps:

Couldn't solve the fixed window boundary problem — this is a well-known challenge in rate limiting that a strong candidate should address
Race condition handling was left unresolved — especially concerning for a system meant to protect against abuse
Cache resilience strategy was thin — given it's the most critical component in your design
Limited knowledge of rate limiting algorithms — familiarity with sliding window, token bucket, or leaky bucket would have strengthened your design significantly
My recommendation: Study common rate limiting algorithms and practice thinking through concurrency problems in distributed systems. Your systematic approach and trade-off reasoning are good foundations to build on.

Best of luck, Shubham!


Here's a detailed breakdown of where you lost marks in each category:

Requirements Gathering (7/10) — Lost 3 points:

Didn't consider different rate limiting tiers (e.g., per-endpoint, per-client, global limits)
Didn't discuss how rate limit configurations would be managed or updated
Didn't explore edge cases like what happens for unauthenticated requests
Design (6/10) — Lost 4 points:

Forgot load balancer initially in the architecture
Diagram wasn't updated after removing the Update Tokens Job
Cache-to-database sync mechanism was never clearly defined
No discussion of how rate limit configurations are stored and distributed across instances
Problem Solving (5/10) — Lost 5 points:

Couldn't propose a solution for the fixed window boundary problem (-2)
Couldn't address the race condition vulnerability (-2)
Didn't explore atomic operations in cache for increment (-1)
Scale & Trade-offs (6/10) — Lost 4 points:

Cache scaling strategy was vague ("just add more nodes")
No discussion of hot keys (popular clients hitting same cache node)
Database fallback strategy was essentially "hope cache stays up"
Didn't discuss monitoring or alerting for rate limiting
Communication (6/10) — Lost 4 points:

Walkthroughs were sometimes repetitive
Diagram wasn't kept updated as design evolved
Some explanations were unclear