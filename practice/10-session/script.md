Welcome to your system design interview! Here's your design challenge:

Design a high-frequency stock trading system that can process millions of trades per second with ultra-low latency and ensure data consistency.

Use the drawing canvas to the left to create diagrams, system architectures, and visual representations of your solutions. The problem statement has been added to the canvas to get you started.

Think out loud as you work through the problem, and don't hesitate to ask clarifying questions. This interview focuses on your ability to design scalable systems, communicate ideas visually, and think through real-world constraints and trade-offs. I'll guide you through the process and provide feedback at the end.

#
Can you share the question again?
Design a high-frequency stock trading system that can process millions of trades per second with ultra-low latency and ensure data consistency.

#
hello  hello hello
Let's get started! Before diving into the design, what are the key functional requirements you'd focus on for this high-frequency trading system?

#
hello I am shubham
Hi Shubham! Let's jump right in. What do you see as the key functional requirements for this high-frequency trading system?

#
before that I'll read the question so the question says designer stock trading system  design a high frequency stock trading system that can process millions of Traders per second with ultra low latency and ensure data consistency
That's right. So now that you've understood the problem statement, what are the key functional requirements you would identify for this system?

#
just wanted to ask like we wanted to make a stock trading stock system like which keep tracks of each stocks and people can sell and buy  stocks  is that the system that we are going to build
Yes, at its core it's a system where users can buy and sell stocks — but the emphasis here is on high-frequency trading, meaning millions of trades per second with ultra-low latency. With that context, what specific functional requirements would you prioritize?

#
so we are actually focusing on millions of concurrent Traders trying to buy or sell the same stocks
That's one important aspect to consider. But let's step back — what are all the key functional requirements you'd want this system to support? Think about what the system needs to do from a user's perspective.

#
okay so I list down the functional requirements
Go ahead!

#
hello to you I have let down the function requirements  so these are the functional requirements  so it says you just should be able to see list of stocks  and each stop should have the current value previous value daily monthly and yearly change and the company name description annual and quarterly profits and quarterly turnover  until that's a stock profile basically  and then the other requirement is user should be able to send a trade  by or send request  and then trade should shuttle in a market order or a limit order means user should be able to get the value that is coming he can like has two choices like either he should want a specific to want to sell some at a certain amount for example like hundred rupee per stock then he should like it should be settled and he can also choose to on a market value also like for example he can choose to like whatever the current price he's willing to pay for that month of  quantity of stocks  so at whatever value that stock is stating his willing to pay for that for that much amount of quantity of stocks and then the other functionality is user should be able to see stocks in his portfolio like current value of all these stocks and his or her previous orders
I can see you've listed those out on your diagram — good start. You've covered stock viewing, trade execution with market and limit orders, and portfolio management.

Now, given that this is a high-frequency system processing millions of trades per second, what non-functional requirements would you consider critical?

#
we want to build a high high frequency stock trading so the system should be scalable
Scalability is important. But what other non-functional requirements would be critical for a system that needs to process millions of trades per second with ultra-low latency and ensure data consistency?

#
so I've written down some of the non-functional requirement a scalable  and consistent  reliable fault tolerant resilient and available means our gate if you guys should be available highly available
I can see those on your diagram. You've listed scalable, consistent, reliable, fault tolerant, resilient, and available. Given that this system requires both ultra-low latency and data consistency, do you see any tension or trade-offs between some of these non-functional requirements?

#
icr trade off so we want to be consistent when we are doing a right operation  and for read operations we want to be highly available  and and low latency for read operations  and for right operations we want  we want data consistency
That's a reasonable distinction between read and write operations. Now let's move to the high-level design — can you sketch out the major components of this system and how they connect on the diagram?

#
before that before the design I want to make some estimations
Go ahead with your estimations!

#
also so we can assume that we have total users of 1 million and out of which 50% are at daily active users that is  that is 500K
I can see those on your diagram. What other estimations would be important for a high-frequency trading system — particularly around trade volume, data size, or latency targets?

#
should we consider hello should we consider that the stock exchange actually opens for unlimited period of time and day like from 9:00 to 3:00
That's a great question to consider. For this interview, you can assume the trading window is limited like a real stock exchange. How would that affect your throughput calculations?

#
yeah  so like  so we have a ride through part that is high for certain period of time when there is a trading period but our read throughput is like constant throughout the day for example
That's a good observation — reads happen 24/7 while writes are concentrated during trading hours. I see you've started some throughput calculations on the diagram. You've estimated around 500 operations/second with a peak of 1k operations/second. Given that the problem states millions of trades per second, how does that reconcile with your current estimates?

#
I think that Activity Part user per day  that the assumption that we are taking is slightly incorrect  I will change it to like we have
Take your time — go ahead and revise your estimations.

#
like ride throughput hello I have done the calculations  so total users let's suppose we have one million uses and daily activities are 50% of that that is 500k and we can assume that the rate to write throughput is 100 ratio 1 and the problem says that the right throughput is 1 million per second  so and let's assume we have a total assist stocks in the stock exchanges 5000  and read throughput is 100 times of right throughput that is 100 million per second read request and we can assume that the capacity that  the load that eats instance can take up to is hundred request per second so the total instances that we can need is  100k  do you think these calculations are correct
I can see your estimations on the diagram. Those are interesting numbers. One thing I'd note — you mentioned each instance handles 1000 req/second but then calculated based on 100 req/second. But more importantly, with 100 million reads per second, that's a very high read load. Now let's move to the high-level design — can you sketch out the major components and their connections on the diagram?

#
how do you think I can calculation is incorrect
I'm not here to validate or correct your calculations — I want to understand your reasoning. Can you walk me through how you arrived at the total number of instances needed given your throughput and per-instance capacity numbers?

#
hello  I think I have drawn the diagram  so I'll tell you what all services that we have so we have a client and then we have a API Gateway in which we have a load balancer authentication authorization plus rate limiting  then we have read stock profile service  that will help you read will know you about tell you about the stock for example the stock information the company name stock performance  and like the profit of the stock I like the company that has made in in previous quarter or previous years so so read stock profile service then we have other trade service  then we have trade settlement worker then we have a message queue  that had trade settlement events then we have user portfolio right service then user portfolio read Service then seller pay out service  and also we have a payment service  so I'll also add in the functional requirement that payment of stock is also a requirement
I can see your diagram with all those components laid out. That's quite a comprehensive set of services. Let's dive deeper into the connections — can you walk me through the flow of what happens when a user places a buy order (market order), starting from the client all the way through to settlement?

#
yep so so before I buy order I wanted to tell like a people people actually write their sell orders so in case of a cell people the request goes via gateway to the trade service trade service at your cell order in your order in user orders and also in a Cell order book  so we have a database that has all the cell orders  and  yeah then I'll give you a walk through of what happens during a buy
I can see the sell order flow on your diagram — the trade service writes to both the User Orders datastore and the Sell Orders datastore. Now walk me through the buy order flow.

#
okay in case of a buy the request isn't intercepted by the API Gateway it does authentication and authorization plus a rate limit check and then it sends the request to the trade service trade service adds that order in your user order database and provides you the payment link the payment so you do  fill all your car details of the payment details and the next request reaches the payment service and the payment service calls and external payment provider like people  and so during it call it it gives you the payment ID and the Web book URL that external provider can use to update the status of the payment  so external payment provider like do the payment like they can also choose to do asynchronous payment so after the payment is complete the external prevent provider like use our Web book endpoint to update the status of the payment corresponding to the payment ID after the payment like we got a successful or like any status update we update the payment service call to the notification service about the new status of the payment the notification service center service and event to the client about the latest payment status  so after successful payment has been successful  and so after that the that order actually goes a trade order goes into a buy order book by orders on database so now we have a buy order in buy order database  and we already had cell order and sell orders database  so then actually the worker jobs comes so it actually does a settlement of all these payments so the trade settlement worker actually so for our case it does  buy at a market rate so whatever is the current rate that stock is trading at so it picks a sale order and fix your buy order and do a settlement  and after the settlement is successful it sends a event to the Kafka message queue and that that trade is successful  I'll give you a walk through like what happens after like after that event is red  from the Kafka
I can see this flow on your diagram — the buy order goes through the API Gateway, Trade Service writes to User Orders, then Payment Service interacts with the external provider via webhooks, Notification Service sends SSE updates to the client, and after successful payment the order goes into the Buy Orders datastore. Then the Trade Settlement Worker matches buy and sell orders and publishes successful settlement events to Kafka.

Before you continue with the post-settlement flow, I have a question about the trade settlement process itself. In a high-frequency system processing millions of trades per second, how does the Trade Settlement Worker match buy and sell orders — what's the matching logic and how do you ensure consistency when multiple workers might be trying to match the same orders?

#
so in case of  so we the trade settlement worker has actually assorted list of like in case of cell we have we have sorted list of sell orders of a particular stock similarly for buy orders we have a sorted list of sorted list based on the amount  for the buy orders  so it it matches like  it matches for a cell value  and I look for for a  so what it does so it actually picks  the buy order  so the person who has who has for example in case like a different persons are actually like for example our stock is trading at 100 and there are buy orders at 9897 and 93 and then there are sell orders at 10110210  105  so whenever are new buy order comes of 101 it actually matches with the sell order of 101 so that's how we do a settlement  so we keep both the silent trade sale and buy orders in assorted list
I see — so you're matching orders based on price using sorted lists. But what about the consistency concern I raised? When you have millions of trades per second, what happens if two Trade Settlement Workers try to match the same sell order with different buy orders simultaneously?

#
in that case that would be a first come first serve  in case like both the buyers are bidding at the same price then it would be a first come first serve
That's the desired behavior, but how would you enforce first-come-first-serve at a technical level when multiple workers are processing concurrently? What mechanism prevents two workers from both reading and claiming the same sell order?

#
okay so we want to make sure that our  cell order is actually set it doesn't have a dirty read and it sold to only one buyer
Exactly — so how would you technically ensure that at the system level?

#
one way to do that is like we can have a trade settlement worker East Street settlement worker is actually working on only  means  no to trade settlement workers are  I actually working on the same stock
Interesting — so you're partitioning the work by stock so that only one worker handles orders for a given stock at a time. Can you walk me through how that partitioning would work in practice?

#
so we can assign each worker should pick  so we can do consistent hashing in this case so we have to make sure that each stock is being picked by a single worker only  and  so we can use consistent hashing and on stock ID
That makes sense — consistent hashing on stock ID to ensure each stock's orders are processed by a single worker, avoiding the concurrent matching problem.

Now let's continue — you mentioned Kafka events after successful settlement. Can you walk me through what happens after that event is consumed?

#
yeah so so now we have a successful trade settlement  then  then the message is actually present in after queue that this is a trade settlement event so there are two consumers one is the seller payout service  so it does a payment to the seller  the seller service again  hello  yeah so seller payout service calls the payment service and does a synchronous payment to the to the seller  and then we have a user another another consumer of the trade settlement event is a user profile portfolio right service so it actually updates the user portfolio so it has to update both the seller and the  Empire portfolio that for in case of a buyer it adds the new stock and the stock units that he has brought in his portfolio  so we have a user portfolio data store that actually contains like users list of stock that a user has bought and how many units it has
I can see those flows on your diagram — the Kafka event triggers both the Seller Payout Service and the User Portfolio Write Service, which updates the portfolio datastore with stock holdings.

Now let's talk about the read side. I see you have a User Portfolio Read Service and a Read Stock Profile Service, both with caches and read replicas. Walk me through how the stock price gets updated — I see you have a Stock Price Datastore that the Trade Settlement Worker writes to. How does a user see real-time stock prices?

#
so whenever a user hello  hello  so whenever a user actually opens a application he should see a list of stocks  and  so that actually request goes to the read stock profile service  so I told you like  stock stock information like the stock belong to which company the company's information companies like annual annual  report of Lake economic report companies so all these data is in the stock profile database and it also has a red replica read replica and then all of our users are actually reading from the cash most of this stock profile actually doesn't change like it changes like it doesn't change like every second so we can use the cashier  also also I'll tell you about the user portfolio read Service in a minute
I see the stock profile flow with the cache and read replicas. But I notice the stock price is different from the stock profile — prices change with every trade. I see you have a separate Stock Price Datastore that the Trade Settlement Worker writes to, also with a cache and read replica. Given that prices change with every trade settlement and you're processing millions of trades per second, how do you ensure users see near real-time stock prices?

#
so  yes so whenever I use it sees his portfolio  so he should seize what all the stocks that we have and what is the quantity of he he has so that data actually comes from user Portfolio Service but the current value of the stock means and the actual stock value in his portfolio comes from like the units and the stock price so stock price come from a user stock cash  and so the trade settlement workers actually update the stock price data store like each after a successful trade it it actually updates the stock price and the stock price has a read database has already replica and a cash so the Portfolio Service reads the current price of stocks from the stock price cash
I see that flow on your diagram. Now let's shift to how this system would handle scale. You mentioned 1 million trades per second and 100 million reads per second — what do you see as the biggest bottlenecks in your current design, and how would you address them?

#
so we have  like we have one million rides are like 1 million trades per second so we can these trade service are actually  means we can scale them out they are they don't contain any like persistent data  these are stateless services  so we can scale them horizontally  they they actually need to just write and sell orders and buy orders database and user orders database so yeah we can actually scale them out  and these buy and buy order sell orders and the user orders are actually append only  the other I think the bottleneck can be the trade settlement workers  because they they actually need to settle these trades of very frequently  so we can have like so in case we have a like a high like high number of Trades then what we can do is like we can like  so each settlement worker can have like minimum number of stocks that it has to like work on  so that way we can actually scale these workers also  under yeah I think these are the two bottle Max and for others like like cash we have cash for the stock profile and forecast also and then user portfolio cash so I don't think so that would be a problem
You've identified the Trade Settlement Worker as a key bottleneck. You mentioned each worker handles a minimum number of stocks via consistent hashing. But what happens if one particular stock — say a very popular one — has significantly more trades than others? How does your partitioning strategy handle that hot partition problem?

#
so in case of stock is actually bought very frequently  yeah then we have a large number of trades on that particular stock and the single trade settlement worker actually has to do a lot of  operations
Right — so what would you do about it? How would you handle that hot stock scenario where a single worker becomes overwhelmed?

#
what is  so it actually needs to write in the new stock price to the stock database  so maybe we can  I'm not sure like how we can optimize this settlement worker can you give me a hint like  how we can like  make this process optimize or like  prevent this from a single point of video
Think about what the settlement worker is actually doing — it's matching buy and sell orders for a single stock. If one stock has a massive volume, is there a way to break down the work for that single stock further, or handle the matching differently?

#
also in instead of like keeping  we can do batch processing I guess
Batch processing is one approach. What would be the trade-off of batching in a system that requires ultra-low latency?

#
we actually  we are providing a guarantee to the user that like we will provide you the best  best order value  to the bar  so  we also have to like make sure that
Right — so batching introduces latency, which conflicts with the ultra-low latency requirement. Let me ask you a different question about your overall design. Looking at your buy order flow, a user has to go through payment with an external provider like PayPal before the trade is placed in the buy order book. In a high-frequency trading system where speed is critical, what concerns do you have about that design choice?

#
we can we can use wallets so each user can have a ball wallet and we just don't have to like the amount will be deducted from his wallet instead of like going him through a payment flow
That's a good insight — a wallet-based approach would significantly reduce the latency of the buy flow by eliminating the external payment call during trade execution. How would that change the flow in your diagram, and where would the payment with the external provider happen instead?

#
instead like people can preload the wallet like before like at any time and we can use the payment like you can deduct the amount from the wallet
Right — so the external payment flow shifts to a wallet top-up step that happens independently of trading. That way, during a trade, you just deduct from the wallet balance which is much faster.

Let's talk about another trade-off in your design. You're using Kafka for post-settlement events, and the User Portfolio Write Service and Seller Payout Service are consumers. What happens if the Seller Payout Service fails after the trade has already been settled and the portfolio has been updated?

#
so the payment service has two options in case it is a valid payment it will deduct from the wallet and in case of a like any other payout source so it will like call the people  people external payment provider
That's the payment mechanism, but my question was about failure handling — if the trade settles successfully and the portfolio gets updated, but the Seller Payout Service fails to pay the seller, how does your system handle that inconsistency?

#
so seller seller pay out service is actually connected to read reads events from the Kafka topic  so it does a retry  and  it retires and in case like like even after the retire the payment actually fails then we can add that message to our  that letter q and  and we can like  we can take a credit we can  we can inform the customer that  that  either we directly pay him and you into his wallet  like we do credit that amount in wallet and in case or we do a  payout to his bank
Good — so you'd use Kafka's retry mechanism and a dead letter queue for failed payouts, with a fallback to wallet credit. That handles the failure scenario.

Let's wrap up with one final consideration. Looking at your overall design, you have multiple datastores — Stock Profiles, Stock Price, User Orders, Buy Orders, Sell Orders, User Portfolio — each with write instances, read replicas, and caches. What data consistency model are you using for the replication between write instances and read replicas, and what's the impact on the user experience?

#
for example for reads for for eats of stock profile and the user portfolio so here we can have like a  weekend  we can tolerate some delays  of like 122 seconds so that would not be like that is considerable  but and for other other databases like stock price also like we can we can look for for a user he can see the value in his portfolio like a few seconds ago so that will also be correct considerable but on other data store like user order sell orders and buy orders these are right only like a band only so that won't be much problem  so here on sale orders and buy orders we can  we can Like A Shard the database  and we can have a multiple writer instances and we can have a caram based consensus
Interesting — so you're differentiating consistency requirements by datastore: eventual consistency for read-heavy stores like stock profiles and portfolios, and stronger consistency with quorum-based consensus for the order books. That's a thoughtful distinction.

That brings us to the end of our interview. Let me share some feedback:

Strengths:

You identified clear functional and non-functional requirements upfront
Good separation of read and write paths with appropriate consistency models
The wallet optimization to eliminate external payment calls during trading was a strong insight
Solid use of consistent hashing for worker partitioning and Kafka for event-driven post-settlement flows
Comprehensive diagram with clear data flows between components
Areas for improvement:

The hot partition problem for popular stocks wasn't fully resolved — this is critical for a high-frequency system
The initial design had external payment in the critical trading path, which contradicts ultra-low latency requirements
Consider how real-time price updates reach users (push vs pull) — SSE/WebSockets for live price feeds wasn't fully explored
The estimation of 100 million reads/second deserved more thought on how your caching and read replica strategy actually handles that volume
Think more about the order matching engine — it's the heart of a trading system and deserved deeper exploration of data structures and algorithms
Overall, you demonstrated good system thinking and were able to iterate on your design when challenged. Keep practicing deeper dives into the most critical components of a system. Great effort, Shubham!

#
based on my today's interview I want you to read on following topics on a scale of 1 to 10 like requirement Gathering design problem solving scale and trade-off  a communication skills and overall overall  overall verdict and overall like
Here's your scorecard:

Area	Score (1-10)	Comments
Requirement Gathering	6	You covered core functional requirements well, but missed some critical aspects specific to high-frequency trading like real-time price feeds, order matching engine details, and latency targets. Non-functional requirements were listed but not deeply reasoned about initially.
High-Level Design	7	Comprehensive set of services with clear separation of concerns. Good use of caches, read replicas, and event-driven architecture. The diagram was detailed and well-structured.
Problem Solving	5	You identified consistent hashing for worker partitioning which was good, but struggled with the hot partition problem and needed hints. The initial payment flow in the critical path was a significant design flaw, though you corrected it with the wallet approach when challenged.
Scale & Trade-offs	5	You identified stateless services can scale horizontally and differentiated consistency models per datastore. However, you didn't deeply address how to handle 100M reads/second, the hot stock problem remained unresolved, and batching vs latency trade-off wasn't fully explored.
Communication Skills	6	Your diagram was detailed and you could explain flows clearly. However, explanations were sometimes verbose and unfocused. Could be more structured and concise when walking through flows.
Overall Verdict	5.5/10	You demonstrated solid foundational knowledge and built
#
so will you  so value like what is the verdict needs work borderline or higher or a stronger
Based on your overall score of 5.5/10, the verdict would be:

Borderline / Lean No Hire

Here's why:

What worked: You can build a reasonably complete system with multiple services, datastores, and event-driven flows. Your diagram was comprehensive and you showed ability to iterate when challenged (e.g., wallet optimization).

What held you back:

The core of the system — the order matching engine — wasn't deeply explored. In a trading system interview, this is the most critical component.
You struggled with concurrency and consistency problems without hints.
Latency awareness was weak — placing external payment in the critical trading path is a fundamental design issue for a low-latency system.
Scale strategies remained surface-level.
To move to a "Hire" level, focus on:

Deeply understanding order matching engines and order book data structures
Concurrency control mechanisms (locking, optimistic concurrency, CAS operations)
Thinking about latency at every step of a critical path
Practicing articulating trade-offs more concisely and decisively
Going deeper on fewer components rather than broad but shallow coverage
You're not far off — with focused preparation on these areas, you could cross the threshold. Keep practicing!