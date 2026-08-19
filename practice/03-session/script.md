Welcome to your system design interview! Here's your design challenge:

Design a basic e-commerce platform for small businesses with product listings, shopping cart, and payment processing. Focus on quick time-to-market and low operational costs.

Use the drawing canvas to the left to create diagrams, system architectures, and visual representations of your solutions. The problem statement has been added to the canvas to get you started.

Think out loud as you work through the problem, and don't hesitate to ask clarifying questions. This interview focuses on your ability to design scalable systems, communicate ideas visually, and think through real-world constraints and trade-offs. I'll guide you through the process and provide feedback at the end.

#
hello  hello I am Shubham
Hi Shubham, welcome! Let's get started.

Before jumping into the design, let's make sure we understand the problem well. What do you see as the key functional requirements for this e-commerce platform?

#
and we can start the interview  I'll read the question and make sure I understand it correctly so in the question we have to design a simple E-Commerce platform and the description says design a basic e commerce platform for small businesses with product listing product listing Shopping Cart and payment processing focus on quick time to market and low operation
You've captured the core features well - product listings, shopping cart, and payment processing.

Before we move forward, what kind of scale are you thinking about for this platform? For example, how many users or small businesses would this need to support?

#
I'll rest down the functional and non functional requirements for this system
Sounds good! I can see you've started noting functional requirements on the canvas. Go ahead and list them out — I'll review what you have once you're done.

#
so the functional requirements are like we have to design API for a product listing API Shopping Cart and prevent processing API so we have to designed Three Types of API and also we have to they are some not functional requirement like it should be it should have less time to ship  and its should have less operational cost means we have to use less number of components
I can see your requirements on the canvas. You've identified the three core API groups and the non-functional constraints around quick time-to-market and low operational cost.

Before we move on, what scale are you designing for — roughly how many concurrent users or transactions per day would you expect for a small business e-commerce platform?

#
I will do some calculations like so as we we want to like this seems like we have we have creating a small MVP  and for the sea commerce platform so I guess we have like  so users we have Ruffle like around I think 5000 users
5000 users works as a starting point for an MVP. Now let's start with the high-level design — can you sketch out the major components of this system and how they connect on the canvas?

#
and I think since it is a shopping E-commerce website so mostly there are less number of orders but people do visit
I see you've noted a 100:1 read-to-write ratio on the canvas, which makes sense for an e-commerce platform where browsing far exceeds purchasing.

Now that we have the requirements and scale clarified, let's move to the high-level design. Can you sketch out the major components and their connections on the canvas?

#
hello  so I have written estimations so we can we able have like around 5000 users and read to write ratio is 100 ratio 1 and at any given point of time we can have like maximum like 1000 users are actively using the app  so we can have a throat of like 1000 request per second
Got it — 5000 users, 100:1 read-to-write ratio, and around 1000 RPS at peak. That gives us a good baseline for the MVP.

Now let's move to the high-level design — can you draw out the major system components and how they interact on the canvas?

#
so now we have some rough estimations like of our system I'll proceed to drawing the components  that we will use
Go ahead and sketch it out on the canvas! I'll review your architecture once you have the components drawn.

#
okay I have done the diagram
I can see your diagram. You've laid out a solid structure with:

Client-side: Buyer and Seller
API Gateway as the entry point
Backend services: User Backend, Admin Backend, and Auth Module
Storage: PostgreSQL database and AWS S3 for images
External Payment Gateway (Stripe)
You've also shown some API routes and data flows between components.

Let's dive deeper — can you walk me through what happens when a buyer wants to purchase a product? What's the complete flow from the client through to payment completion?

#
I give you quick brief you are brief about what all the components that we have will be using
Sure, go ahead and walk me through the components and their roles.

#
yeah so what happens when a wire wants to purchase a product so before Actually by actually purchase a product he has to see the catalogue like the product listing so when client by actually it's the get products API so it is a list API so it reaches and it done3  gets to the back and service22  and which have like modules  are backend and service
I can see the flow on your diagram — the buyer hits the API Gateway, which routes to the backend services. I notice you have both a "User Backend Service" and an "Admin Backend Service" inside what appears to be a single service boundary.

What's the reasoning behind separating these two backend services, especially given your non-functional requirement of keeping operational costs low?

#
hello  so we have a single package but we have different modules  so we can like we can have like different on different ports we can have different endpoints running  so the user bacon service will like will run on the port so whenever a request like getting product request reaches API Gate checks the Earth coming the authentication it does the authentication it is a user and based on the user it actually send the request and it checks the user has the permissions or not it can like it can just read the list of products only it can't update the product so
I see — so it's a single deployed service with separate modules for user and admin functionality, which aligns with your low operational cost goal.

You mentioned the API Gateway handles authentication. I also see a separate "Auth Module" in your diagram. Can you clarify how authentication actually works in your system — where does it happen and what's the flow?

#
yeah hello  so it API Gateway will not handle the authentication in our main back and service we will have a authentication module that will do authentication of request and based on the type like  the request which the user belongs to like is the user back means I user buyer or a seller based on that it actually
Got it — so the Auth Module lives inside the main backend service and handles authentication and authorization, determining whether the request comes from a buyer or seller and routing accordingly.

Now let's walk through the payment flow. I see you have a "POST /buy" endpoint and an arrow going to Stripe. Can you walk me through what exactly happens when a buyer clicks "buy" — step by step through your components?

#
hello  I'll give you above by so now we have like request has read we have get a get request of products we request reach to back and gateway we had like authentication then we had the authorisation like based on the and then we the user vacant actually reads the database data like patches the product catalogue and also it reads the images from the S3 and IT returns to the user  so this is the listing flow like similarly is the product instead of listening the products
Got it — I can see that read flow on your diagram. Now let's focus on the payment flow. I see you have "POST /buy" and arrows connecting to Stripe with "POST /transaction" and "POST /txnStatus". I also notice you've added SSE (Server Sent Events) for transaction status updates.

Can you walk me through the complete purchase flow — what happens after the buyer hits "POST /buy" all the way through to the payment being confirmed?

#
hello I give you a walkthrough of like adding an item to the Shopping Cart so we have to AP get card SBI input cart API so it patches the get a like what items it has in the card by get API so bacon service it goes to the back and services it does the authentication authorisation that like vacant services that data from the database and return to the user so similarly like the pot some item in the card and goes via API to the back and service and like it updates the state in the database your card state in the database
Clear — the cart flow is straightforward with reads and writes to PostgreSQL through the backend service.

Now I'd really like to hear about the payment flow — that "POST /buy" path. I can see on your diagram you have connections to Stripe and SSE for status updates. Walk me through what happens when a buyer decides to actually purchase the items in their cart.

#
flow is like we have the state in our list of items we use the post by method it reaches checks that we have the required quantity of items like again before like proceeding to the payment and whenever it does validations we have the proper invent we have all the items
Good — so the backend validates inventory and item availability first. Then what happens next? How does the interaction with Stripe work, and how does the buyer know if the payment succeeded or failed?

#
so after the validation it actually initiate a transaction request to the external payment gateway and so we have handed we have provided all the payment details like the card information and external payment gateway actually handles the payment and it returns along with the payment like we also return our Vaibhav that this is the URL on which the external payment gateway will return the status of the payment like the transaction status of that Transaction ID so we have a webbook and find that has been created and vacant service and the external payment gateway like after some few seconds it actually
Got it — so the flow is: backend initiates a transaction with Stripe, Stripe processes the payment, and then Stripe calls back to your webhook with the transaction status. I also see you have SSE on the diagram for notifying the client.

How does the buyer on the frontend know the payment is complete — what's the connection between the webhook receiving the status and the buyer seeing the confirmation?

#
so external payment Gate the status of transaction so we update the transaction status in database and also we actually
Go ahead, continue — how does the buyer get notified about the payment status?

#
back and service actually  so after the back and service has got the status it updates the status in database and also it sends a server sent event to the to the client  so the bacon push is the events to the client
Good — so the webhook updates the database and pushes the status to the buyer via SSE. That completes the payment flow nicely.

I notice on your diagram you also have a "CDC" component at the bottom with an arrow from the buyer. What is that component's role in your system?

#
instead of client calling fetching the event
Understood — so SSE allows the server to push updates to the client instead of the client polling for status. That's a clean approach for real-time notifications.

Now, what about the CDC component I see at the bottom of your diagram — what role does it play in your system?

#
it is not CDC actually it is CD and it is CD and  cdn
Ah, CDN! I see it now. Can you explain what role the CDN plays in your system and what content it serves?

#
so  so that so our API like product listing and  so we actually want to show the images to the to the end user so every time we can't search from the back and can't fat from the data S3 because we can cash those images
Makes sense — the CDN caches product images so you're not hitting S3 for every request, which also helps with your low operational cost goal since reads heavily outweigh writes.

Now let's move into how this system would handle scale. Given your 1000 RPS and the 100:1 read-to-write ratio, where do you see the first bottleneck appearing in your current architecture?

#
yeah so before that I want to like make some like what how will the database table actually look  so I quickly draw like what is our scheme are look
Go ahead and sketch out your database schema on the canvas!

#
so we can have a tables for a for product  and  then we will have table for card  user stable
I can see you've started noting the database tables — Product and User so far. Go ahead and add the remaining tables and their key fields on the canvas.

#
okay so we will we will have like so these are the required tables product table user table cards table payments table so in products we can have like  we can have follow like product name  description  and we can have like the quantity we have  like we can have like 10 10 different quantity of the same product then user we can have name  name email  and  we will have  will have list of
I can see your schema taking shape with Products (id, name, description, quantity), Users (name, email, id), and Carts. You mentioned the Carts table has a user-id — how would you model the relationship between a cart and the products in it?

#
so inkart we can have user ID product ID and the quantity that the user is buying
That makes sense — the cart essentially maps a user to products with quantities. I also see you have a Payments table listed but haven't detailed its fields yet. What key fields would that table need given your payment flow with Stripe?

#
then in case of like payment we can have like the user ID payment ID  external payment ID then we can have the status status we can have like pending like we have send the request to the external server  and then we can have cancelled that external Sarvar help cancel the transaction then we can have successful transaction
Good — your Payments table captures the key states of a transaction. I notice you have an external payment ID alongside your internal payment ID, which is important for reconciliation with Stripe.

Now let's move into scaling. Looking at your current architecture with a single backend service and a single PostgreSQL database, where do you see the first bottleneck appearing as traffic grows beyond your initial 1000 RPS?

#
the single bottle like that I can see is like our large we prepare large application
What specifically about the application concerns you as a bottleneck, and how would you address it?

#
hello so we have a large Monolithic application so  we have to like we actually have to split it to divisible components so I can scale those individual components like we can separate out the authentication module and we can like have different bacon service for the user facing and for the admin epi
Interesting — you're suggesting breaking the monolith into separate services. But earlier you chose a single service with modules specifically to keep operational costs low and ship quickly.

How would you balance that trade-off between scalability and your original non-functional requirements of low cost and quick time-to-market?

#
another like I think we should not solve this like problem initially  the problem that we can hit we have a large amount of database reads  so we have like database
Good instinct — given your 100:1 read-to-write ratio, the database is likely the more pressing bottleneck. How would you handle that heavy read load on PostgreSQL?

#
hello as we have a large amount large number of reads  we can like have read replicas of our database so we can have a writer instance and then reader instance  so in this way all rights reads will go to another like database
Read replicas make sense for your read-heavy workload. That keeps your write path clean while distributing read load.

Beyond the database, what other scaling strategy could help reduce the load on your system, especially for frequently accessed data like popular product listings?

#
yeah we can add a cash layer so before the before like read we can have a cash  so we can use the reddish cash  so I have drawn the rediscash component  and
I can see the Redis cache component on your diagram. How would you decide what data to cache and how would you handle cache invalidation — for example, when a seller updates a product's quantity?

#
so we will like come since we have large number of read queries so we will like cash frequently fest products in our cash  so we can use all are you cash or I love you cash  LFU cache
LFU makes sense for caching popular products. And what about when a seller updates product details or quantity — how do you ensure the cached data stays consistent with the database?

#
in order to like so whenever we have I update the admin API also updates the cash data so I will draw another
So you're updating the cache directly on writes — that's a write-through approach. What happens if the cache update succeeds but the database write fails, or vice versa? How would you handle that inconsistency?

#
no no hello  so we will not use right through cash approach  we will use we will first update in our database if the database update was successful than we will update the cash
Got it — so you write to the database first, and only update the cache if the DB write succeeds. But what happens if the database write succeeds and then the cache update fails? The cache would still serve stale data.

#
then that would be a cash mesh and when the next person will fetch from the  we can have like reprise we will make the like update and cash resident we will have retrics and yeah with an exponent back of period
So you'd retry the cache update with exponential backoff. That's a reasonable approach for eventual consistency, especially for an MVP.

Looking at your overall design, you've covered the core components, data flows, caching, and database scaling. One last area — I notice you have a CDN for images and S3 for storage. How would you handle the scenario where a seller uploads a new product image but the CDN is still serving the old cached version?

#
yeah so in that case like an images updated means our CD and has like the data insidian has been updated and so what we will do whenever like we have a update request like the images updated so we will update the S3 means will update the image and s3 along with that we will update the CD and also we will like we will invalid that cash key ID and this will so the next will be but the subsequent images
Good — so you invalidate the CDN cache on image updates, forcing it to fetch the fresh version from S3 on the next request.

We've covered a lot of ground today. You've designed a system with a clear architecture — API Gateway, modular backend service, PostgreSQL with read replicas, Redis caching, Stripe integration with webhooks and SSE, CDN for images, and S3 for storage. You've also thought through cache invalidation, payment flows, and scaling strategies while keeping your MVP constraints in mind.

Is there anything else about the design you'd like to add or any trade-offs you'd want to revisit?

#
so I think we have covered everything we have covered I will give you like a quick recap so we have like different components that we have made like we have a buyer and a seller clients then we have API Gateway then we have a vacant service which is the Monolithic application then we have a database and we have a cash layer and we have a w s s 3 for storing images
Great recap, Shubham. You've covered the key components and their interactions well throughout this interview.

Let me share some feedback:

Strengths:

You clearly identified requirements and kept the MVP constraints in focus throughout
Your payment flow with webhooks and SSE was well thought out
Good instinct on prioritizing database scaling over splitting the monolith, staying true to your non-functional requirements
Solid understanding of caching strategies and read-heavy optimization
Areas to consider further:

Your database schema could benefit from thinking about order management — right now you have a Payments table but no Orders table to track what was actually purchased after checkout
Think about what happens to inventory during the payment processing window — between when a buyer clicks "buy" and when Stripe confirms the payment, could another buyer purchase the same last item?
Security considerations around payment data flowing through your system could be explored more
Overall, you demonstrated a systematic approach to the problem and made reasonable trade-offs aligned with the constraints. Well done!

#
also also be have a cdn and we are using external payment
Right — the CDN for caching product images and Stripe as the external payment gateway. Those are important pieces, especially the decision to use an external payment provider which keeps your operational costs low and avoids the complexity of handling payment processing yourself.

That wraps up our interview, Shubham. You built a practical, well-reasoned design that stays aligned with the MVP goals. The areas I mentioned — particularly around inventory locking during payment and order tracking — would be great next steps to think about as the system evolves beyond the MVP stage.

Thanks for your time and good luck!

#
hello  hello before the interview can you provide me feedback for these individual Verdict	Req.	Design	Prob-Solving	Scale & Trade-offs	Comm.	Overall
Sure! Here's my evaluation across each area:

Category	Rating	Comments
Requirements	✅ Strong	Clearly identified functional (3 API groups) and non-functional requirements (low cost, quick shipping). Good estimation of scale — 5000 users, 100:1 read-write ratio, 1000 RPS.
Design	✅ Solid	Well-structured architecture with appropriate components — API Gateway, modular monolith, PostgreSQL, S3, CDN, Redis, Stripe. Database schema covered core tables but missed an Orders table.
Problem Solving	⚠️ Good with gaps	Strong payment flow with webhooks and SSE. Good cache invalidation thinking. However, didn't address inventory race conditions during payment processing or error handling scenarios in depth.
Scale & Trade-offs	✅ Solid	Good instinct to prioritize database read replicas over microservices split. Redis caching with LFU was appropriate. CDN for images reduces S3 load. Could have explored horizontal scaling of the backend service more.
Communication	⚠️ Adequate	Walked through flows clearly verbally. Diagram was comprehensive but got visually cluttered with overlapping arrows. Schema was documented well on canvas.
Overall Verdict	Lean Hire	You demonstrated solid fundamentals and practical decision-making aligned with constraints. To move to a strong hire, focus on edge cases (race conditions,
#
can you also can you also provide me numbers in like 10  from 0 to 10 like for each category requirement design problem solving scale trade of a communication overall verdict
Sure! Here are the numerical scores:

Category	Score (0-10)	Comments
Requirements	7/10	Clear functional and non-functional requirements with reasonable estimations. Could have explored more edge cases like multi-tenancy for small businesses, search/filtering needs.
Design	7/10	Solid component selection and architecture. Good use of modular monolith for MVP. Missing Orders table and didn't address data consistency patterns deeply.
Problem Solving	6/10	Good payment flow design with webhooks and SSE. However, missed inventory locking during checkout, error recovery scenarios, and didn't address concurrent purchase conflicts.
Scale & Trade-offs	6/10	Correct prioritization of read replicas and caching over microservices. Could have discussed horizontal scaling of backend, database sharding strategies, or rate limiting at the API Gateway.
Communication	6/10	Explained flows clearly but diagram became cluttered with many overlapping arrows. Could improve visual organization by grouping related flows and keeping the diagram cleaner.
Overall Verdict	6.5/10 — Lean Hire	You have solid fundamentals and good architectural instincts. To improve, focus on: (1) edge cases and failure scenarios, (2) concurrency issues, (3) cleaner visual diagrams, and (4) deeper exploration of scaling strategies beyond the first bottleneck.
Keep practicing — you're on the right

#
based on my today's interview can you provide me feedback for the next interview
Absolutely! Here's actionable feedback to improve for your next interview:

🔴 Immediate Improvements
1. Address Edge Cases & Failure Scenarios

Always ask yourself: "What happens if this step fails?"
For example: What if Stripe webhook never arrives? What if the database write succeeds but cache update fails permanently? Have timeout and fallback strategies ready.
2. Concurrency & Race Conditions

In e-commerce, inventory locking is critical. Think about: two buyers purchasing the last item simultaneously. Explore pessimistic vs optimistic locking approaches.
3. Cleaner Diagrams

Separate read flows and write flows visually
Use color coding for different user journeys
Avoid overlapping arrows — organize components with more spacing
Label every arrow clearly with data format and direction
🟡 Medium-Term Improvements
4. Deeper Schema Design

Think beyond basic tables — consider an Orders table, order line items, inventory tracking, and audit trails
Discuss indexing strategies for your read-heavy queries
5. Security Considerations

Payment data handling (PCI compliance)
API authentication mechanisms (JWT, OAuth)
Rate limiting at the API Gateway
6. Explore Scaling More Thoroughly

Don't stop at the first bottleneck — identify second and third bottlenecks
Discuss horizontal scaling of application servers
Consider database connection pooling
🟢 **Long



