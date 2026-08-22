Welcome to your system design interview! Here's your design challenge:

Design an online auction system like eBay that can handle concurrent bidding, ensure bid integrity, manage auction timers, and process payments.

Use the drawing canvas to the left to create diagrams, system architectures, and visual representations of your solutions. The problem statement has been added to the canvas to get you started.

Think out loud as you work through the problem, and don't hesitate to ask clarifying questions. This interview focuses on your ability to design scalable systems, communicate ideas visually, and think through real-world constraints and trade-offs. I'll guide you through the process and provide feedback at the end.

#
hello  hello I am Shubham
Hi Shubham, great to have you here! Let's dive right in.

Before we start designing, I'd like to understand how you'd scope this problem. What do you see as the key functional requirements for this online auction system?

#
okay so I'll read the question to make sure that I understand it correctly  so we have to design an online option system like eBay that can handle concurrent build building  ensure bed integrity manage auction timers and process payments ok
Right, those are the key areas mentioned in the problem. But before jumping into the design, let's make sure we're aligned on the scope.

What are the core features a user would need to interact with in this system — from a user's perspective, what actions should they be able to perform?

#
I just wanted to ask like what do you mean by ensure bed integrity
Great question! "Bid integrity" refers to ensuring that bids in the auction are valid and trustworthy. For example, think about what could go wrong when multiple users are trying to place bids on the same item at the same time.

What kinds of issues do you think could arise in that scenario?

#
we have to make sure that only one person with the highest like bit highest money that he is bading gets gets that bed
That's part of it, yes. Now let's step back and think about the system more broadly.

What are the core actions a user should be able to perform in this auction system?

#
I will write the functional requirement
Go ahead and add those to the canvas — I'd love to see them visually!

#
to admin should be able to like add bits
I see you've started writing functional requirements on the canvas. Keep going — think about all the different types of users and what each of them should be able to do in the system.

#
and buyers  should be able to
Take your time and complete the buyer actions on the canvas. Think about the full lifecycle of an auction from a buyer's perspective — from discovering an item to the end of the auction.

#
okay so I have written like function requirements so we can have like to do users admin users admin users should be able to add items with the base price so this is the minimum amount that it should like it should be bed and then there are buyers so each wire should be able to beat with amount greater than the current amount within a specific time  also after the time is left the buyer with the highest bit will win the bed and shud make a payment using a third party
I can see your functional requirements on the canvas — that's a solid start. You've covered the admin creating auctions with a base price, buyers placing bids above the current amount within a time window, and the winner making a payment through a third-party service.

What about non-functional requirements — what qualities should this system have in terms of scale, performance, or reliability?

#
I think we should call instead of admin we should call themselves
Sure, you can refine the terminology — go ahead and update that on the canvas. But before we spend more time on that, let's think about the non-functional side of things.

Given that this is a system handling real-time bidding with money involved, what non-functional requirements would you prioritize?

#
also one more functional requirement after the British successful  the seller should get the beating amount
Good catch — so the seller receives the payment after a successful auction.

Now, what about the non-functional requirements? Think about things like how many users might be bidding simultaneously, what happens if a component fails mid-auction, or how fast the system needs to respond to a bid.

#
non function requirements like  it should be highly available
What else beyond availability? Think about what's critical when multiple users are placing bids on the same item at the same time, and real money is involved.

#
consistent  we should make  ok  I have written on function requirement so since we are dealing with the transactions like so we should be consistent and then it should have low latency and it should be highly available and it should be resident because we are dealing with money and it should be fault  we should be able to recover from any state
I can see your non-functional requirements on the canvas — consistency, low latency, high availability, resilience, and fault tolerance. Good thinking, especially prioritizing consistency given the financial nature of the system.

One quick question before we move on — what kind of scale are you designing for? How many concurrent users or auctions are you thinking about?

#
so now will do estimations
Go ahead and add your estimations to the canvas!

#
and guessing will have like 1 million uses
I see you've added 1M users. Can you think a bit more about the scale — for example, how many concurrent auctions might be active at any given time, or how many bids per second the system might need to handle during peak times?

#
that is like okay so I have some estimations so let so we can assume like we have like 1 million total users and of the total users we have one percent of the total users I are actively looking on that particular day so which is equal to 10k and of that 10k only 10% of the active users actually bed on that day like they actually invest money on that day that is one day 1000
I can see your estimations on the canvas. So roughly 10K daily active users browsing and about 1K actually placing bids. You've also noted a read-to-write ratio of 10:1, which makes sense since more people browse than bid.

Good, we have a solid understanding of the requirements and scale. Now let's start with the high-level design — can you sketch out the major components of this system and how they connect on the canvas?

#
2 hello  hello
Hey, I'm here! Go ahead and start sketching the high-level architecture on the canvas — think about the major components your system would need and how they connect together.

#
I have done the diagram  so I tell you the main components so we have a buyer and a seller these are the two clients and then we have an API Gateway CD and bit service and create option service payment service and Reconcile job and then we have an external payment provider like strike and then we have we have storing images of the items that are in auction for example house image in S3 and then we have a discuss and we have a database
I can see your diagram on the canvas — nice work! You've got buyers and sellers connecting through an API Gateway, with separate services for creating auctions, handling bids, processing payments, and a reconciliation job. You also have a CDN, S3 for images, Redis cache, a database, and Stripe as the external payment provider.

Let's dive deeper into the connections. Walk me through what happens when a buyer places a bid — what's the complete flow from the buyer's action through your system?

#
ok  this system actually works like so we have all the buyers and buyers have wallet so they have already done the recharge and their wallet  and so after the bed is and so we will directly detect the amount from the wallet  and we will make the payment from wallet to the seller
Interesting — so you're introducing a wallet concept where buyers pre-load funds. That simplifies the payment flow, but it's a significant design decision.

Can you walk me through the actual bid flow though — when a buyer submits a bid, how does the request travel through your components from the API Gateway all the way to the database?

#
so  before The tile I give you have post option
I can see you've defined some API endpoints on the canvas — POST /auction, GET /auctions, GET /auction/{id} for the seller side, and GET /bids, GET /bid/{id}, POST /buy/{id} for the buyer side.

Now walk me through the flow — when a buyer calls POST /buy/{id} to place a bid, what happens step by step through your services?

#
hello  yeah so I'll give you a walkthrough of like all the API that are present in the seller side so we have a post post option API so using the Sapient up aseller can add an item for An auction so whenever he had an item to the option the request reaches the API Gateway and then to the create option service the create option service at item in the database along with the image of The Titan to be option in the S3 bucket  so this will we have items in our database that need to be option
Good, that's clear — the seller creates an auction, it goes through the API Gateway to the create-auction service, which stores the item details in the database and the image in S3.

Now tell me about the buyer side — when a buyer calls POST /buy/{id} to place a bid, what happens through your bid service?

#
yeah so so now we have people start like the option start  the option starts actually hello  so buyers can use the get API list API list all the items that are available for wedding and then they can click and one item you and search the information of that bit option item and then they also have a post API in which they can they can be for an option item
Got it — so buyers browse auctions, view details, and then place a bid. But I want to understand the critical part more deeply.

When two buyers place a bid on the same item at nearly the same time, how does your bid service handle that to ensure bid integrity?

#
so so for consistency we are using RDBMS  so an option item will be will be auction to only one person only means there can be a single wire of an item
Right, you're using an RDBMS for consistency. But how specifically does the bid service ensure that when two concurrent bids arrive at the same millisecond, only the valid higher bid gets accepted and the other is rejected?

#
yeah so for that  so for a two when are request reaches the API gateway for an bed API Gateway send that request to the bit service The Beat service checks do the validation that we have the item is not option and so it right it the lock from the database and it it in the database  so we have a bits that different biles actually bat so we have like we have items like the amount like each wire will have provided to that they want to spend for a single item so we will store all these values and database
So you're acquiring a lock on the database row to handle concurrent bids. That's one approach to ensure consistency.

Can you clarify what kind of lock you're using — and what happens to the second buyer's request while the first one is holding the lock?

#
no actually what we will do it we will add all the bits in our database like user one has raised in amount of like hundred and user to actually has also raised then amount of hundred then user 3 has made for an 102 then after the timer and we will decide the maximum amount that maximum so the user three is having the leg bit the amount 102 so we again auction like ask for a race that is there anyone like that you amount is 102 so people can start bidding on 102 amount  and this so people will continue to bed amount greater than 102 for definite period of time like 5 minutes

hello are you there
Yes, I'm here! So if I understand correctly, you're storing all bids in the database and then after a timer expires, you pick the highest bid. Then a new round starts with the new highest amount as the floor.

How does your system manage this auction timer — what component is responsible for knowing when the bidding window has expired and triggering the next round or closing the auction?

#
so we will have a scheduler that actually runs and it actually maintains like what are the items available for option and start the option and after like certain period of time it actually like do it takes the highest bit and it races until like a we have like no other by no other buyers willing to add more bits with a price with a price greater than the current price
So you have a scheduler managing the auction lifecycle. But I have a concern — how does the scheduler know that no other buyers are willing to bid more? In a real auction, how would you determine that the bidding is truly "done" versus a buyer just being slow to respond?

#
we can have like fixed number of rounds  like we can have  like race  of amount 5 times
Interesting — so a fixed number of rounds. That's one approach to defining when the auction ends.

Can you update your diagram to show where this scheduler component sits in your architecture and how it interacts with the other services?

#
I have added a bit schedule a service that actually pics the items in auction and like it create a periodic schedule of each items for option and it actually keep tracks of the rounds  and after each round it actually raise the amount greater than the last bit price
I can see the bid scheduler on your canvas connected to the database.

Now let's shift to another critical flow — when the final round ends and a winner is determined, walk me through how the payment process works from the bid scheduler all the way through your payment service and Stripe.

#
so whenever a payment whenever all the rounds of option item are finished  the bit scheduler service sends request to the payment service that make the payment from the wallet of the wire to the sellers account  and post request to the external payment service external payment service Returns
I see the payment service connecting to Stripe on your diagram. You mentioned a wallet system earlier — so the payment service deducts from the buyer's wallet and transfers to the seller's account via Stripe.

What happens if the Stripe call fails or times out — how does your system handle that scenario?

#
yes yes
So what's your strategy for handling a failed or timed-out payment to Stripe? I can see you have a reconcile-job on your canvas — how does that fit in?

#
so the payment service makes a payment to the external payment service like also with the payment ID and also it also it sends  the status
I can see the reconcile-job on your canvas connecting to Stripe with a GET /paymentStatus call and a POST /updateStatus back to the database.

So the reconcile job periodically checks with Stripe to verify whether payments actually went through and updates the status accordingly — is that correct? And what happens if the reconcile job finds that a payment has failed?

#
yes yes
Okay, so what happens when the reconcile job discovers a payment has failed — how does your system recover? Does the item go back up for auction, does the next highest bidder get a chance, or something else?

#
it actually retrieves  the payment service retrai for a payment from the wallet to the seller seller account
So it retries the payment. But what if the buyer's wallet doesn't have sufficient funds at that point, or the retry keeps failing — is there a fallback mechanism?

Let's move on to another aspect. I see you have SSE (Server Sent Events) on your diagram for updating payment status to the buyer. Can you explain how the real-time communication works in your system — how are buyers notified about bid updates during an active auction?

#
for anybody actually check that the person has the sufficient amount in the wallet  so before bidding people has have to have sufficient amount in the ballot like greater than the current bed amount
That makes sense — you validate the wallet balance before allowing a bid. That's a good safeguard.

Now, I notice you have SSE on your diagram for payment status updates. But what about during the active auction — how are all the buyers watching an auction notified in real-time when someone places a new higher bid?

#
so buyers can see the amount that are being raise and they actually call the bit service and bit service like what is the current amount that is running for the option
So buyers are polling the bid service to check the current highest bid? That's one approach, but think about the implications — with many buyers watching the same auction, what would the load on your bid service look like, and could there be a more efficient way to keep buyers updated?

#
Cache,  that sits between the database and the service
I can see you've added Redis cache on your diagram between the bid service and the database. That helps with read performance.

But my question was more about the communication pattern — buyers are repeatedly polling your bid service to get updates. With thousands of buyers watching a popular auction, what's the trade-off of polling versus the SSE approach you've already shown for payment updates?

#
I think the bed service can also send this server side events to the buyers
Good thinking — using SSE for real-time bid updates as well would reduce unnecessary polling and keep buyers informed instantly when a new bid comes in.

Now let's talk about scale. Looking at your current architecture, what do you see as the biggest bottleneck if the system suddenly had to handle a very popular auction with thousands of concurrent bidders?

#
so in case like there's a popular update they never back and service will have to like sand a lot of events to a lot of buyers  like this server side events has to be sent from the service to the buyer and their will be a lot of events and we can have a celebrity we can have a problem
Right, that's a valid concern — the bid service could become overwhelmed with thousands of SSE connections for a popular auction.

How would you address that bottleneck? Can you sketch out what changes you'd make to your architecture to handle this scale?

#
so sometimes we can instead of like by  the bed amount that is going on for a particular bed
It sounds like you're starting to think about a solution — can you complete that thought and show me on the diagram how you'd modify the architecture to handle the high volume of real-time updates for a popular auction?

#
hello so instead of server sending the events to the buyer s  the bit price from the server
It seems like you're considering having buyers pull the current bid price from the server instead of pushing via SSE. That's essentially going back to polling.

Think about it differently — if the bid service is the bottleneck because it's handling too many connections, what architectural change could you make to the bid service itself to handle more load?

#
instead of a service we can use a cash
So you'd have buyers read the current bid price directly from Redis cache instead of hitting the bid service. That offloads read traffic.

But what about the write side — when thousands of bids come in simultaneously for a popular auction, how would you scale the bid service to handle that write pressure?

#
we will have multiple instances of BIT service
Good — horizontal scaling of the bid service. But if you have multiple instances of the bid service all trying to update the same auction's current highest bid, how do you ensure consistency? How do you prevent two instances from accepting conflicting bids at the same time?

#
hello  we will allow  buyers to bed same amount or higher amount we will save all the data in the database and then after when the scheduler finish after a certain period it actually pics highest bit
I see — so you're accepting all bids and letting the scheduler determine the winner afterward, rather than validating in real-time that each bid is strictly higher than the current one. That simplifies the concurrency problem on the write side.

But consider this trade-off: if buyers can see an outdated bid price from the cache and submit a bid that's already lower than what someone else just submitted, what's the user experience like? And could this lead to a large volume of essentially wasted bids hitting your database?

#
we can use a max heap data structure
Interesting — a max heap to efficiently track the highest bid. Where would this data structure live in your architecture — in the bid service's memory, in Redis, or somewhere else? And what happens to it if that instance goes down?

#
yes we can use that in our memory
So if it's in the bid service's memory and that instance goes down, you lose the current bid state. And with multiple instances of the bid service, each would have its own separate heap.

How would you handle these two issues — data loss on crash and keeping bid state consistent across multiple service instances?

#
I am not sure like how we can do that
That's okay. Think about it this way — you already have Redis in your architecture. Could that play a role here? Redis has data structures that could help maintain a shared, persistent state across multiple service instances.

Let's move on to another important topic. Looking at your overall design, what would happen if your database goes down during an active auction — how does your system handle that failure?

#
so we instead of one database  we will have a cluster of database in which we have one right instance and then we have reader instances so in case one of the database actually goes down like the writer instance goes down reader reader instance is promoted as a writer instance
Good — a primary-replica setup with automatic failover. That addresses database availability.

Let's wrap up with trade-offs. Looking at your complete design, you mentioned both consistency and high availability as non-functional requirements. In a distributed system, there's often tension between these two. For your auction system, if you had to prioritize one over the other, which would you choose and why?

#
for an option system  sensitive dealing with money
You're leaning toward consistency since money is involved — that's a reasonable choice. It's better to temporarily reject a bid than to accept an invalid one.

We're coming to the end of our session. Let me give you some feedback:

Strengths:

You identified the right functional and non-functional requirements
Good separation of concerns with distinct services (bid, auction, payment, reconciliation)
Smart addition of the reconcile job for handling payment failures
Wallet pre-validation before bidding is a good safeguard
Solid thinking around database replication for fault tolerance
Areas to explore further:

Concurrency handling — the mechanism for ensuring bid integrity under concurrent writes could be more concrete (e.g., how exactly locks or atomic operations work at the database level)
Real-time updates — the approach oscillated between SSE and polling; having a clearer strategy for real-time communication at scale would strengthen the design
Shared state across service instances — when you horizontally scale the bid service, consider how distributed data structures (like those in Redis) can replace in-memory structures
Auction timer management — the scheduler's failure handling and exactly-once semantics could be explored more deeply
Edge cases — what happens with last-second bids, or if the scheduler itself goes down mid-round
Overall, you demonstrated good system thinking and covered the major components. Keep practicing deeper dives into concurrency control and distributed state management. Great effort, Shubham!

#
we will privatise consistency over over availability because we are dealing with money
Exactly — that's the right reasoning. In a system where financial transactions and bid integrity are at stake, you can't afford to accept invalid or duplicate bids just to maintain availability. Consistency is the safer choice here.

Thanks for walking through this design, Shubham! I've already shared my feedback above. Keep focusing on deepening your understanding of concurrency control mechanisms and distributed state management — those are areas that will really elevate your system design skills. Good luck!

#
rate me in the following criteria : Req.	Design	Prob-Solving	Scale & Trade-offs	Comm.	Overall
Here's your rating across each criteria (on a scale of 1-5):

Criteria	Rating	Comments
Requirements	3.5/5	Identified core functional requirements for buyers and sellers, good non-functional requirements. Could have explored edge cases like bid cancellation, auction expiry, and user authentication more thoroughly. Estimations were reasonable but could be deeper (e.g., bids per second, storage needs).
Design	3/5	Good microservice decomposition with separate services for bidding, auctions, payments, and reconciliation. CDN, cache, and S3 were appropriate additions. However, the interactions between components could have been more precisely defined, and the bid scheduler's design lacked clarity on failure handling.
Problem-Solving	2.5/5	Identified key problems like concurrent bidding and payment failures. The wallet pre-validation was a smart safeguard. However, struggled with concurrency control mechanisms, couldn't fully articulate how to handle shared state across multiple service instances, and the max-heap idea wasn't fully thought through.
Scale & Trade-offs	2.5/5	Recognized bottlenecks with SSE connections and proposed horizontal scaling. Database replication was a good call. However, the scaling strategy for the bid service lacked depth, and the consistency vs. availability trade-off discussion was brief.
Communication	3/5	Used the canvas effectively to lay out components and APIs.
#
On a scale of 1-10 , for each criteria Req.	Design	Prob-Solving	Scale & Trade-offs	Comm.	Overall
Here's your rating on a scale of 1-10:

Criteria	Rating	Key Reasoning
Requirements	6.5/10	Covered core user actions and non-functional requirements well. Missed edge cases (bid cancellation, authentication, auction expiry rules). Estimations were surface-level — no bids/second or storage calculations.
Design	6/10	Good service separation and inclusion of cache, CDN, S3, and reconciliation job. But bid service concurrency mechanism was unclear, scheduler lacked failure handling details, and the wallet system was introduced late without full integration into the diagram.
Problem-Solving	5/10	Identified key problems but struggled to solve them concretely. Couldn't articulate a clear locking/concurrency strategy, the max-heap idea was incomplete, and shared state across instances was unresolved. Payment retry logic lacked depth on failure scenarios.
Scale & Trade-offs	5/10	Recognized SSE bottleneck and proposed horizontal scaling and database replication. But didn't fully address how multiple bid service instances maintain consistency, oscillated between SSE and polling without a clear decision, and the CAP trade-off discussion was minimal.
Communication	6/10	Good use of the canvas with clear component layout and API definitions. However, explanations were sometimes fragmented, required multiple prompts to complete thoughts, and some flows were hard to follow verbally.
**
#
Oervall
Criteria	Rating
Overall	5.5/10
Summary: You demonstrated a solid foundational understanding of system design — good service decomposition, reasonable requirements gathering, and awareness of key concerns like consistency and fault tolerance. However, the design lacked depth in the most critical areas for an auction system: concurrency control, real-time updates at scale, and distributed state management. Several ideas were introduced but not fully developed (wallet system, max-heap, scheduler rounds), and you struggled when pushed on deeper technical details.

To improve to 7+:

Practice articulating concrete concurrency mechanisms (optimistic locking, pessimistic locking, atomic operations)
Understand distributed caching patterns and how tools like Redis can serve as shared state
Develop clearer real-time communication strategies (WebSockets, SSE, pub/sub) and when to use each
Work on completing thoughts fully before moving to the next topic
Practice back-of-the-envelope calculations more rigorously (throughput, storage, bandwidth)
You have the right instincts, Shubham — keep practicing and going deeper on each component. You'll get there! 💪