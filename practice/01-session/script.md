### Conversation
Welcome to your system design interview! Here's your design challenge:

Design a URL shortening service like bit.ly or TinyURL that can handle billions of URLs, provide analytics, and ensure high availability and low latency for redirects.

Use the drawing canvas to the left to create diagrams, system architectures, and visual representations of your solutions. The problem statement has been added to the canvas to get you started.

Think out loud as you work through the problem, and don't hesitate to ask clarifying questions. This interview focuses on your ability to design scalable systems, communicate ideas visually, and think through real-world constraints and trade-offs. I'll guide you through the process and provide feedback at the end.

#
hello
Let's get started! Before diving into the design, I'd like to understand how you think about the problem.

What are the key functional requirements you'd want to focus on for this URL shortening service?

#
 I'm audible hello  am I Audible
Yes, I can hear you! Let's get started with the design challenge.

What are the key functional requirements you'd focus on for this URL shortening service?

#
 okay so I can see there's a problem and the problem statements states that Designer URL shortener
Yes, that's right — the problem statement is on the canvas. Now let's work through it systematically.

To start, what do you see as the core functional requirements for this URL shortening service?

#
 and the description says a designer URL shortness service like big TV or tiny URL that can handle billions of yours provide analytics and Ensure High availability and low residency for redirects okay
Exactly. Now that you've read through the problem, let's break it down.

What specific features or capabilities should this system support from a user's perspective?

#
 okay so  what specific features or capability show the system support from a user's perspective  so I list down some features and  I think  that you are shortness should Hollow  I think the URL shortener should  should have at least two capabilities that is put URL  so put URL will have like users can pass there long URL and it will return them the short URL  and the other capability that the system should have is get the get long URL  thanks you pass them the short URL and it should return the long URL
Good, so you've identified two core operations — creating a short URL from a long one, and resolving a short URL back to the original. The problem also mentions analytics.

What non-functional requirements do you think are most critical for this system given the scale mentioned in the problem?

#
 so the analytics that this system provide I think what are the frequently used short urls  and what percentage of URLs are actually used  what percentage of short URLs are actually used  and we should also be able to clean  the stale  not used short urls  so these three analytics like  the total  total short urls  percentage of urls  dividing a URL into categories  and then cleaning the  steel URL count
Interesting thoughts on analytics. Now, the problem mentions handling billions of URLs with high availability and low latency.

What non-functional requirements would you prioritize to ensure the system meets those expectations?

#
I think  the system should have some non-functional requirement should meet some non-functional requirements  and this should be that the system should be highly available  also it should be  is the P95  it should have a good latency  means a highly performance  and  yeah it should be fault  and we are reliable
Good — you've identified availability, low latency, and fault tolerance as key non-functional requirements. Given that the system handles billions of URLs, have you thought about the expected scale in terms of read/write ratio?

#
 I assume that hello  I assume that as the problem said that the it should handle 1 billions of the urls okay hello  so the problem says that that it should handle 1 billions of urls  that means 10.9 URLs let's assume that our database has like 10.9 URLs in one year these are saved  then  these are for one year then that makes like around 300K are saved  that means 208 URLs per minute  that is around 3 URLs per second  so the right throughput will is like three words per second  so the right throughput is 3 urls  per second
You've worked through the write throughput. Now, for a URL shortening service, how do you think the read traffic would compare to the write traffic?

#
 we can assume assuming that there are like 100 times  read traffic as compared to right traffic is people will reuse the traffic URL  so assuming the read to write ratio is 100 100 so we have approx 300 read request per minute  per second sorry  so 300  read request per second for read
Good, so 3 writes/sec and 300 reads/sec with a 100:1 read-to-write ratio. That gives us a clear picture of the scale.

Now let's move to the high-level design. Can you sketch out the major components of this system on the canvas?

#
hello  hello so I have drawn the diagram  so the diagram consists of like the API Gateway  and then we have URL shortener service  and then we have a database so we have two database read write database  and a read replica of the right database  so we can have multiple instances of short URL Services running  API Gateway can connect to any of the instance  and also we can have multiple instances of API Gateway
I can see your diagram — you've got the internet connecting to API Gateways, which route to multiple URL shortener service instances, and those connect to a write database and a read database with replication between them.

Walk me through what happens when a user submits a long URL to get a shortened version — what's the flow through these components?

#
 okay so when a user user has a long URL and wants to get a short URL so it actually hits our Port end point  and the question intercepted by the API Gateway  then forwards the request to the short URL service  the short URL service has the algorithm to  to convert the long URL into a short URL  and then it saves both the short mapping between the long and the short URL in the database  it saves a means it creates a right lock and then say in our database and write into the database  it then Returns the short URL  to the user  via API Gateway
Good walkthrough of the write flow. You mentioned the short URL service has an algorithm to convert the long URL into a short URL.

How would you generate the short URL key — what approach would you take for that?

#
 I think there can be many algorithms  hashing  along URL is also one of the  algorithm that we can use means we can just hash the URL and convert that into a short URL and return to the user
If you hash the long URL, what would you do if two different long URLs produce the same hash — how would you handle collisions?

#
 yeah so in that case we have to make sure that doesn't produce the Collision doesn't have happen  and I mean the Collision rate should be as low as possible
Right, but collisions can still happen with hashing. Have you considered any alternative approaches to generating unique short URL keys that might avoid the collision problem altogether?

#
 so we are actually another approach is like we are saving that in the word database  so we can use the database key means the database unique key I thought URL  so every time we get along URL  whenever we try to insert that in our database the database Returns the ID  so we can use that ID
Interesting — using the database-generated ID as the short URL key would indeed avoid collisions. But consider this: if you're using sequential database IDs, what concerns might that raise?

#
 since  we look at the right throughput  it is three URLs per second  that is that means  we won't have this sequence this problem of  in the database  means there won't be  indeed sequence means  concern when generating IDs in the database
That's one perspective on throughput, but I was thinking more about whether sequential IDs might raise any security or predictability concerns — users could potentially guess other short URLs by incrementing the ID.

Let's move on. Can you walk me through the read flow — what happens when a user clicks on a short URL to get redirected?

#
 so whenever  so whenever a user clicks on the he has a short URL and wants to get the original URL  so what the request actually passes through the the API Gateway and reaches the short URL service the short URL service like fetches from the read DB  since we have multiple we can have multiple replicas of the GDP so it can actually  means it can  it is able to withstand that load  of like 300 URL reads per second
Good. Now looking at your diagram, I see the arrows showing reads going to the read database. Given that this is a read-heavy system with 300 reads/sec, is there anything you could add between the URL shortener service and the read database to improve latency?

#
 I know that database reads are slower  and  in case means we don't have a problem with the read latency we can actually create multiple instances of the read database  so these database are highly available and read optimized  for example AWS posted  we can use and it can actually provide us high high it's low latency  so we actually have to spin up another read instance and  we will actually get a low latency
You mentioned adding more read replicas, which addresses availability. But think about it this way — if the same popular short URLs are being requested repeatedly, is there a layer you could introduce that avoids hitting the database entirely for those frequent lookups?

#
 yes we can actually  add a cash  all cash layer also we can use a reddish cash and  we can keep the frequently  frequently Asked means URLs in our cash and so this instead of like hitting the database we can actually retrieve the URL from the database from the cash
Good thinking. Can you add that caching layer to your diagram and show how it fits into the read flow?

#
I have added a cash later  so whenever we get a read request  we checked in our cash that the cash has the key  or not if in case it doesn't have it fetches from the database read database and update the cash and return that to the URL shortener service
I can see the Cache component in your diagram with connections to the read database and the URL shortener services. That's a solid read flow with cache-aside pattern.

Let's dive deeper into the data model. What would the database schema look like for storing these URL mappings?

#
 so I have added the data model  so the  our database table will consist of ID original URL  the short URL created at  and expireset
Good, that covers the core fields. Now let's think about the connection between your components more carefully.

What HTTP status code would you return when redirecting a user from the short URL to the original URL, and why does that choice matter?

#
I think in case of our right or put request  means whenever a user tried to  get a short URL from the original URL we can provide him HTTP status code 202 indicating that the request has been request is being processed  or like it is accepted request is accepted
That covers the write side. But I was asking specifically about the redirect — when a user clicks a short URL and needs to be sent to the original long URL, what HTTP status code would you use for that redirect?

#
 we can return them HTTP status code 4 and 200  indicating that  that the short URL has  we have found the original URL from the short URL  and 404 not found in case the short URL is expired  or  it is not found in citizen invalid short URL
For redirects, you'd typically want to consider HTTP 3xx status codes, which are specifically designed for redirection — they tell the browser to go to a different URL. Something to think about: there are different 3xx codes that have different implications for caching and SEO.

Let's move on to scaling. Given your current architecture, what do you see as the potential bottlenecks as traffic grows significantly beyond your current estimates?

#
 in case we have a spike  in right requests  and I think so current rate is through what is 3 URLs per second  even though we have like a hundred times spy it will be like 300  URLs right request per second and I think the database will will be the standard load and we don't need to worry about the right requests  because  we want to make sure that our right request means we have correctly saved
You've addressed the write side. What about the read side — if traffic grows to, say, 10x or 100x of your current 300 reads/sec, where would the system start to struggle?

#
 in case we have like a spike in our read request  then we can we can have multiple instances of cash  ready cash
Okay, so you'd scale the cache layer horizontally. How would you distribute the data across multiple cache instances — what strategy would you use to decide which cache node holds which URL?

#
 I think  horizontal scale is not the best approach
Interesting — why do you think horizontal scaling isn't the best approach for the cache layer, and what alternative would you consider?

#
we can do vertical scaling  we can increase the size of the reddish cash
Vertical scaling has its limits though — there's a ceiling to how much memory you can add to a single machine. What happens when you hit that ceiling with billions of URLs?

#
 yeah so we eventually have to scale horizontally
Right. So when you do scale the cache horizontally, how would you determine which cache node a particular short URL should be stored on or looked up from?

#
 I'm not sure like what we can do now
That's okay. Think about it this way — if you have multiple cache nodes and a request comes in for a short URL, you need a consistent way to route that request to the right node. Have you come across any techniques for distributing keys across multiple nodes?

#
 so  what we can do we have to make sure that the request hits that has the data  so we already know  we have the short URL and  we have to reach the right cash
Right, exactly — you need a way to map a short URL to the correct cache node every time. One common technique involves using a hash of the key to determine which node it belongs to. Does that ring a bell in terms of how distributed systems partition data across nodes?

#
 yes
Can you explain how you'd apply that concept to your cache layer in this system?

#
 so for example we have requests then we have the short URL we can do the hash of the short URL  and also every time it the same shot URL actually reaches the same cash  so although there will be first time cash fail but the second time we will have cash hit because it will reach eventually the same cash
Good — that's the right idea. You'd hash the short URL to consistently route to the same cache node, ensuring cache hits after the first lookup.

Let's talk about trade-offs. In your current design with write and read database replicas, what trade-off are you making in terms of data consistency?

#
yeah so we have a right database and a red database so so they are  so  so there is a data replication going on from the right database to the read database  so we'll have our application lock and that replication lock can be like around 10 seconds  and it may be low also like for example less than one second but we can assume like in an average case it will be around like 5 Seconds  so that means  the  the so in so in that case  this 5 Second means we will not be able to read  just after the ride
Exactly — you've identified the replication lag issue. So there's a window where a user creates a short URL but can't immediately use it because the read replica hasn't caught up yet.

How would you handle this specific scenario to ensure a better user experience?

#
 I think we should not handle this specific scenario because 10 second is a fair amount of time  because  because people will create the URL  and they'll take some time to use it
That's a practical perspective — in many real-world cases, users won't try to use the short URL within those first few seconds.

Let's shift to another concern. You mentioned the system should be fault-tolerant. What happens if your write database goes down — how does your current design handle that?

#
 yes  so in case we have a database cluster  that means we have a one writer instance and there are many reader instances  so in case  due to any reason the right database actually the right database instance actually shut down  so the read replica  so it actually becomes a leader and it it changes it role to a writer instance and now it becomes a writer instance so all our right request will now shifts to a new writer instance  so that means we have  we were able to handle  and the database failure failure
Good — you've described leader election and failover for the database layer.

We're nearing the end of the interview. Looking at your overall design, is there anything you'd want to add or change to better support the analytics requirement mentioned in the problem statement?

#
 I think we can add a third party at third party to Analytics tool like New Relic or data dog  to be able to send them Analytics
That could work for system-level monitoring, but the problem mentions analytics like tracking how many times a short URL has been clicked, which is more of a product feature. How would you capture and store that click data within your system architecture?

#
I think during our reads  what we can do is if we can add a queue  asynchronous Q  that this this short URL has been read  and another service can actually read those events  and based on those number of events it can actually update  our Analytics
Good thinking — using an asynchronous queue to capture click events without impacting redirect latency is a solid approach. That decouples the analytics processing from the critical read path.

That brings us to the end of our interview. Let me share some feedback:

Strengths:

You systematically identified core functional requirements (create and resolve URLs)
Good back-of-the-envelope calculations for read/write throughput
Solid understanding of read replicas, caching, and database failover
Smart decision to use async processing for analytics to keep redirects fast
Practical thinking about replication lag trade-offs
Areas for Improvement:

Short URL generation strategy — Consider exploring approaches like base62 encoding, pre-generated key pools, or counter-based approaches more deeply, and think about security implications of predictable IDs
HTTP redirect semantics — Understanding 301 (permanent) vs 302 (temporary) redirects is important as it affects caching behavior and analytics accuracy
Distributed caching — Familiarize yourself with consistent hashing, as it's fundamental for scaling distributed systems
Data model — Consider adding fields for analytics (click count, user agent, referrer) and think about how the schema supports your use cases
Cache eviction strategies — Think about LRU, TTL policies, and how to handle cache invalidation for expired URLs
Overall, you demonstrated good system design fundamentals and practical reasoning. Strengthening your knowledge of distributed systems concepts and diving deeper into component-level details would take your designs to the next level. Great



### Feedback 
Here's your scorecard across the key evaluation areas:

1. Design Skills — 6/10

Good understanding of basic architecture (API Gateway, services, databases)
Identified read replicas and caching but lacked depth on distributed systems concepts like consistent hashing
URL key generation strategy needed more rigor around collision handling and security
2. Problem Solving Ability — 6.5/10

Solid back-of-the-envelope calculations for throughput
Good instinct on async processing for analytics
Could have been stronger on identifying edge cases and exploring multiple approaches before committing to a solution
3. Communication Skills — 5.5/10

Diagram was functional but could have been more organized and detailed
Verbal explanations were sometimes unclear or repetitive
Data model was a nice addition to the canvas
4. Scalability & Trade-offs — 5.5/10

Identified replication lag trade-off well
Database failover understanding was solid
Needed more depth on horizontal scaling strategies, cache distribution, and bottleneck analysis
5. Requirements Gathering — 6/10

Identified core functional requirements
Covered key non-functional requirements (availability, latency, fault tolerance)
Analytics requirements could have been explored more thoroughly upfront
Overall Score: 5.9/10

To improve, I'd recommend:

Studying distributed systems patterns (consistent hashing, partitioning, sharding)
Practicing HTTP protocol fundamentals
Working on structured


### Tips 
Here are targeted tips for your next system design interview:

1. Structure Your Thinking

Before jumping into design, spend a full 5 minutes listing ALL requirements clearly — write them on the canvas as a checklist
Separate functional, non-functional, and analytics requirements explicitly
This shows the interviewer you think systematically
2. Go Deeper on Key Decisions

When you propose a solution (like hashing for URL generation), immediately discuss its pros, cons, and alternatives
Practice the pattern: "Option A does X but has Y drawback, Option B solves Y but introduces Z trade-off, I'd choose B because..."
Interviewers value your reasoning process more than the final answer
3. Know Your Fundamentals

Study these core concepts thoroughly: consistent hashing, base62 encoding, HTTP 3xx redirects, cache eviction policies (LRU/LFU), database sharding strategies
These come up repeatedly across different system design problems
4. Improve Your Diagrams

Label every arrow with the data being passed and the protocol (HTTP, gRPC, async)
Add API signatures directly on the canvas (e.g., POST /urls {longUrl} → {shortUrl})
Clean, well-organized diagrams communicate confidence
5. Practice Articulation

Try to be concise and direct — avoid repeating the same point
Use this structure: state your decision, explain why, mention the trade-off
Record yourself practicing and listen back
**6. Anticip