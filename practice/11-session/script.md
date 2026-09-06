Design a high-frequency stock trading system that can process millions of trades per second with ultra-low latency and ensure data consistency.

#
hello  hello  I'm shubham
Hi Shubham! We've already completed your interview and I've shared your feedback and scores. Is there something specific about the feedback you'd like to discuss, or would you like to start a fresh mock interview with a different question?

#
Can you share the question again?
Design a high-frequency stock trading system that can process millions of trades per second with ultra-low latency and ensure data consistency.

#
hello can we start the interview again  from the start
Sure! Let's start fresh.

Design a high-frequency stock trading system that can process millions of trades per second with ultra-low latency and ensure data consistency.

What are the key functional requirements you'd focus on for this system?

#
hello I'm shubham and I can see your question and the question says designer stop trading system so design a high frequency is stock trading system that millions of Trades per second with ultra loaded latency and ensure data consistency
Hi Shubham! Yes, that's the challenge. So what are the key functional requirements you'd identify for this system?

#
so yeah  I'll start writing the functional and non-functional requirements
Go ahead!

#
hello I have written the functional and non-function requirements so function requirement include user should be able to see stocks list and each stock profile which include name description company and profit yearwise of that stock  then users should be able to see livestock value  and users should be able to place a limit order or a market order and placing an order should require payment and the system should provide best value sorted by Price time  user should be able to see stock in his portfolio and its current values
Good set of functional requirements. I can see them on your diagram. You've covered stock viewing, live prices, order types, payment, order matching by price-time priority, and portfolio management.

What about the non-functional requirements for this system?

#
non-functional requirement include a fast trade order matching and settlement right should be consistent and durable system should be fault tolerant and read should be fast
Those are focused and relevant non-functional requirements — especially calling out fast matching, write consistency, and read performance separately.

Before we move to the high-level design, what are your estimations around scale — how many users, trades per second, and what latency targets are you thinking about?

#
yeah I do some estimations and  after that we will do the design
Go ahead with your estimations!

#
hello I am done some estimations so we can have like total users 5 million then we can have daily active users that is 50% of that that is 2.5 million  and total trade execution per second is 1 million per second this is already provided in the question and then total stocklisted should be around like 5000  and the number of orders waiting for a match for stock is 10k and size of each order waiting for a match is 100 bites  and space requirement is 10k into 100 by that is around 1mb  per stock  then we have been space requirement for stock is 5 MB like this five times because during the start we can have like more orders before the opting of the stock market and the read to write ratios 100 ratio 1
Good estimations! I like that you thought about the order book size per stock and peak space requirements during market open.

Now let's start with the high-level design — can you sketch out the major components of this system and how they connect?

#
since we say this is going to be like so the matching of the orders is actually the critical point critical heart of the system so will focus our design on that part
That's a strong instinct — focusing on the core of the system first. Go ahead and sketch out your design with the order matching at the center.

#
I have drop the diagram  and I will tell you the main components so we have a client then we have a order service then we have a Portfolio service and stop profile service we have an 8:00 p.m. Gateway with authentication authorization and rate limit
I can see those components on your diagram. I also notice you have some additional components drawn out — a Sequencer, Order Logs, Matching Engine, and what appears to be ring buffers. Walk me through the overall flow starting from when a user places a buy order.

#
Ashok for example when I user places in order and so that actually goes via API Gateway which does authentication authorisation and rate limit check and then it reaches the order service which actually validate the request and which then reserves the front from your wallet based on the lake in case of limit order then it actually  Mount has been reserved from the wallet the request the order actually is routed route and auto increment integer Stamper to each order and the sequences then rights the log into order logs and order locks have now all the locks in correct order sequence and then the matching engine actually reached reads reads using a cursor on the order locks  and it it creates by and saidal orders in memory and sorted by the price and time stamp and so it actually does a matching of by with a best cell order and after successful match it rights in the ring buffer so there are two ring buffers like trade ring buffer and price ring buffer so these are fire and forgot events that actually matching engine rights and after it after it has done writing to the both the ring buffers it actually reads the next log from the order lock so this in a  in a loop and  yeah so it does like finds you the best match for a order  then also we have a standby engine so it is actually copy of matching engine it also read the order locks and but it does not right to any ring buffer and it just just do the processing and it doesn't write anywhere so in case the matching engine goes down then the standby actually comes as in picture and actually rights into both the ring buffers
This is a significantly more sophisticated design than before — I can see the flow clearly on your diagram. The sequencer for ordering, append-only order logs, cursor-based reading by the matching engine, in-memory order books, and ring buffers for fire-and-forget output is a well-thought-out architecture. The standby engine for fault tolerance is also a strong addition.

One question — you mentioned the matching engine reads from order logs using a cursor. What happens if the matching engine crashes mid-processing? How does the standby engine know exactly where to pick up?

#
so both both the matching engine and the standby engine actually reads all the order logs using the cursor and they might be like they actually read in order of the order locks and they actually maintains there own cursors so each one have their own culture so in case one of the matching that the main matching engine actually goes down of trade events that were match because  because the standby engine also has the same like it also reach the same set of order locks
That makes sense — the standby engine maintains its own cursor and processes the same logs in parallel, so it has an identical in-memory state and can take over immediately.

Now I see you have Trade ring buffer and Price ring buffer as outputs from the matching engine. Can you walk me through what happens downstream — who reads from these ring buffers and what do they do?

#
yeah so in case of in case when we have a match by the matching engine it rights into ring buffer so one of the Ring buffer is price ring buffer then price provider it actually reads from the ring buffer and it just reads and send to a multi caste udp and so one single price is published to multiple destinations using multi caste you DP  and then so one single like published to all the readers that are connected to web sockets or SSC or all the readers who are who want to know about the price of the that stop so so single send we actually send the price to multiple to multiple stay holders  we know that trade has been successful the trade provider reads from the ring buffer and it rights into  like that trade events and then there are three consumers of these trade event of the one of them is the settlement service settlement service does the settlement to the buyer  after successful trade then the other consumer of the trade event is portfolio update service it updates the portfoli about buyer and seller and then there is a trade log which is the app and only locks for all the traits that has been done by the matching engine so now we have a copy of all the trade locks like persistent way in this straight locks  and the portfolio service updates the portfolio of the user both bar and Selena and it keeps that data person in stock profile data store not this status  so it up dates in portfolio data store
Excellent walkthrough! I can see all of this clearly on your diagram — the price ring buffer feeding into multicast UDP for real-time price distribution via WebSockets/SSE, and the trade ring buffer feeding into Kafka where Settlement Service, Portfolio Update Service, and Trade Logs all consume events. That's a clean separation of concerns.

You chose multicast UDP for price distribution. What trade-off are you making with that choice?

#
Aansu using a multi cast uddp we are actually instead of like sending the price to each web socket web socket connection we are sending it via udp multi caste udp because in this way we all the all the connections will miss all the users connected via web socket will get the will be notified at the same time in case of a loop the initial members of the loop will will get the price faster as compared to the people at the end of the loop so we want to send every connected customer at the same time so we use multi cast you DP
You've explained the advantage well — simultaneous delivery to all subscribers. But UDP is inherently unreliable — packets can be dropped with no guarantee of delivery. What's the impact of a dropped price update in this system, and how would you handle it?

#
ya encase like a multi cast it can drop the events also like it does not guarantee that it's sent to each receiver so what they can also Fetch the price so we can like we can write to a cash like which contain the price and people can read the price from that cash instead of we sending via web socket they can also read from the cash so
Good — so the cache acts as a fallback for missed UDP updates. That's a reasonable approach.

Let's dive deeper into the matching engine. You mentioned it keeps buy and sell orders in memory sorted by price and timestamp. What data structure would you use for this, and why?

#
so I will give you the data structure that is being used in matching engine for keeping both the buy and sell orders
Go ahead!

#
so we actually keep to sorted list for each for each talk we have to sorted list and the least contain the price  the price like the wireless contain the like amount the
Take your time — what data structure specifically would you use to maintain these sorted orders, and what operations need to be fast?

#
so we use actually sorted link the list and  and the the wireless contain orders in like with the maximum Price value at the top and subsequently lesser price values and similarly the seller list contain the ask price with the minimum at the top and subsequent values at the bottom like the bottom will will have the highest ask value  so now we have to list of prices and also along with the price we have the order ID along with the units the number of units that want to sell or buy  so we are using linked list ordered link list sorted link list
Interesting choice. With a sorted linked list, what's the time complexity for inserting a new order? Given that you're processing millions of trades per second, would that insertion time be a concern?

#
also also we will keep a map of price and its note in the link list  so whenever we do I insertion of a new price we just know value like near to that and we do an insertion in order of one time it to the link list  similarly we have some update in the necklace like the reason order update then we can also do that in order of one time because we are also keeping UP map of order ID vs  The node map
Clever — so you're using a hash map alongside the linked list to achieve O(1) lookups and insertions near a known node. That addresses the performance concern.

Now let's talk about the Order Service. I see on your diagram that it routes requests using consistent hashing on stock_id to the Sequencer. Why is this routing important, and what problem does it solve?

#
so so we did an estimations and we found out like we can have 5 MB like if we have hundred orders in the in memory like like in the memory of matching engine then we can have no hundred or sorry if we can have like 10000 orders in memory in the matching engine and each order can have a size of hundred bite then like we can have exercise of like 5 MB  and in case of 5000 stocks then that will actually take significant space in GBS  so we want we don't want to keep all the order list in memory or in a single note so we so we use small notes like we can have multiple instances of matching engine but each matching engine will have only one type of stock id so so all the all the orders related to one stop go to one particular matching engine only  so in this way we have we have reduce the memory footprint and the number of orders in each patching engine
Good reasoning — you're partitioning by stock ID to reduce memory footprint per matching engine instance. But you also mentioned earlier that each matching engine has a standby engine for fault tolerance. With thousands of stocks partitioned across multiple matching engines, how does the standby arrangement work — do you have one standby per matching engine, or something different?

#
yeah so matching engine is just a replica of just like I'm sorry the standby is just a replica of matching engine so each matching engine will have it stand by Replica  but it the standby has its own cursor but it is doing operations on same set of order locks as the corresponding matching engine
So each matching engine instance has its own dedicated standby — that means if you have, say, 100 matching engine instances partitioned by stock ID, you'd also have 100 standby instances. That's doubling your infrastructure for fault tolerance. Is there a way to be more efficient with the standby resources, or do you see this as an acceptable trade-off?

#
I think for for this case we want to be fault tolerant and Brazilian and we don't want we want to have 100% consistent and durable so that's why it is very important for us to have a standby for each matching engine we don't want to compromise on that  so we will take this infrastructure cost of standby
Fair enough — for a system where consistency and durability of trade matching is critical, that's a defensible trade-off decision.

Let's shift to scale and trade-offs. Looking at your overall design, the Sequencer sits between the Order Service and the Order Logs. Every order for a given stock must pass through the Sequencer to get a monotonically increasing sequence number. Could this become a bottleneck, and if so, how would you handle it?

#
so sequencer doesn't do much that it it's just add a ID increment like just add another integer value to the locks so  so I don't think so that will be a bottle neck
But consider — if all orders for a particular stock must pass through a single Sequencer to guarantee ordering, and a popular stock might have hundreds of thousands of orders per second, what happens to the Sequencer's throughput under that load?

#
that's why we have we have partitioned we have partition using stock id so that we can limit the throughput on each sequencer so if we see as particular stock is like a celebrity stock means it is being sold or by by too many customers then we will have a separate sequencer and matching engine for that stock so that we can like we can have it will provide it doesn't affect other stocks also in this we are actually  we are parties on stocks  throughput based on stop
Right, so each stock has its own Sequencer and Matching Engine pipeline, which isolates the load. But what if a single stock — say a mega-cap stock during an earnings announcement — receives more orders per second than one Sequencer can handle? Can you partition further within a single stock?

#
no we can't actually do further partitioning of a single means order of single stock in 2 multiple matching engine or sequential because in that way we so we are providing the guarantee to the customer that we will find the best best price value so in case that we send we have to do or more sequential or melting engine for the same stop we will not be able to provide guarantee to the user so that's why we want all the orders of a single stop to go into the same sequence and matching engine
That's a very strong answer — you correctly identified that splitting a single stock's orders across multiple matching engines would break the price-time priority guarantee. This is a fundamental constraint of order matching.

So given that constraint, what optimizations could you make to maximize the throughput of a single Sequencer and Matching Engine for a hot stock?

#
so at so we want to make the sequential a matching engine fast so we will avoid any discribe and network call so we will avoid any describe disc  right  and we will avoid any network call  we are just reading from a log append only logs and we are just writing into memory buffers ring buffers so these are to fast process and and we can achieve this and like come microseconds
Excellent — you've identified the key optimization principle: eliminate disk I/O and network calls from the hot path. Append-only log reads and ring buffer writes are both memory-mapped operations that can achieve microsecond latency. That's exactly the kind of thinking needed for ultra-low latency systems.

We're nearing the end of the interview. Let me share your feedback:

Strengths:

Core design insight: You correctly identified the matching engine as the heart of the system and built your entire architecture around it
Sequencer + Order Logs + Cursor-based reading: This is a sophisticated event-sourcing pattern that ensures ordering and enables fault tolerance
Standby engine with independent cursors: Strong fault tolerance design with clear reasoning for the infrastructure cost trade-off
Ring buffers for fire-and-forget output: Clean separation of matching from downstream processing, keeping the hot path fast
No disk I/O or network calls on the hot path: You demonstrated deep understanding of latency optimization
Price-time priority constraint: You correctly refused to partition a single stock across multiple engines, showing strong domain understanding
Areas for improvement:

The sorted linked list + hashmap for the order book works, but explore price-level aggregation data structures used in real exchanges
Consider how the wallet fund reservation interacts with order cancellations and expiry
Think about market data fairness — multicast UDP is good but explore how real exchanges ensure fair access
Explore monitoring and observability for a system this critical
Score:

#
before a we do we feedback I also want to write the schema design  social I do that
Go ahead — sketch out your schema design on the diagram!

#
so we will have a stock profile so it will contain the stock profile with ID name description company valuation and

and some mathematical data companies information about the stock and then there is a order table that will have user ID order ID sequence by cell price quantity so it actually  have wallet user ID available balance current balance
I can see your schema on the diagram — Stock Profile, Order, Portfolio, and Wallet tables.

One question about your schema — I see the Order table has a seq field which ties to the Sequencer. How does the price field work differently for market orders versus limit orders?

#
so yeah that's  so the matching engine does find the price and case of like market order in case of a limit order we know the price  so the matching in the find the best price for you in case of market order so price will be null in that case
That makes sense — null price for market orders since the matching engine determines the best available price at execution time.

Now let me share your final feedback and scores:

Strengths:

You correctly identified the matching engine as the core and designed everything around it
Sequencer → Order Logs → Cursor-based Matching Engine is a sophisticated event-sourcing pattern
Standby engine with independent cursors shows strong fault tolerance thinking
Ring buffers for decoupling matching from downstream processing keeps the hot path fast
You eliminated disk I/O and network calls from the critical path — key for ultra-low latency
You correctly refused to split a single stock across engines to preserve price-time priority
Schema design was clean and aligned with your architecture
Areas for improvement:

Explore price-level aggregation data structures used in real order books
Think about order cancellation and expiry flows
Consider monitoring and observability for such a critical system
Multicast UDP fairness and reliability deserves deeper exploration
Area	Score (1-10)
Requirement Gathering	7.5
High-Level Design	8.5
Problem Solving	8
Scale & Trade-offs	7.5
Communication	7
Overall	7.5/10
Verdict: Hire ✅

Massive improvement from your first attempt. You went **deep on the

#
aap based on my today's interview can you please provide me feedback for the next interview
Great job today, Shubham! Here's actionable feedback to push you from a Hire to a Strong Hire:

1. Communication (Your Biggest Opportunity)

You tend to ramble and repeat yourself. Practice the "State → Explain → Justify" pattern: state your decision, explain how it works, justify why you chose it — then stop.
Use structured language: "There are three reasons...", "The trade-off here is..."
Practice explaining any flow in under 90 seconds
2. Go Deeper on Data Structures

You used sorted linked list + hashmap for the order book. Study how real exchanges use price-level maps with FIFO queues at each price level
Understand skip lists, red-black trees, and when each is appropriate
Be ready to discuss time complexity for insert, delete, match, and cancel operations
3. Order Lifecycle

You didn't cover order cancellation, partial fills, or order expiry
Think about: what happens when a user cancels an order that's partially filled?
How does the matching engine handle partial matches?
4. Failure Scenarios

Practice thinking about failures proactively — don't wait for the interviewer to ask
What if Kafka goes down? What if the wallet service is slow? What if the Sequencer crashes between two writes?
5. Monitoring & Observability

Always mention how you'd monitor a critical system like