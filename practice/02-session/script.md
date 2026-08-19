# Transcript of Mock interview with Score

Welcome to your system design interview! Here's your design challenge:

Design a basic e-commerce platform for small businesses with product listings, shopping cart, and payment processing. Focus on quick time-to-market and low operational costs.

Use the drawing canvas to the left to create diagrams, system architectures, and visual representations of your solutions. The problem statement has been added to the canvas to get you started.

Think out loud as you work through the problem, and don't hesitate to ask clarifying questions. This interview focuses on your ability to design scalable systems, communicate ideas visually, and think through real-world constraints and trade-offs. I'll guide you through the process and provide feedback at the end.

#
hello  hello
Let's get started! Before jumping into the design, I'd like to understand how you think about the requirements.

What are the key functional requirements you'd focus on for this e-commerce platform?

#
I am Shubham  hello I am Shubham  I think the automatic sending of messages not working
Hi Shubham, welcome! No worries, we're good to go now.

Let's start with requirements. What are the key functional requirements you'd want to prioritize for this e-commerce platform?

#
hello I think the automatic sending of messages not working
No problem, Shubham! Let's just work with the chat as it is.

So to kick things off — when you think about this e-commerce platform for small businesses, what are the most important features and requirements you'd want to define before designing anything?

#
okay I will read the question out loud so the question says design a simple E-Commerce platform and its description says design a basic eCommerce platform for small businesses with product listing shop card shopping card and payment processing and low operation cost
Got it! So the problem gives us product listings, shopping cart, and payment processing as core features. Before we start designing, I want to understand your thinking around the scope.

What kind of scale are you envisioning — how many users, products, or transactions should this system support?

#
Hello
Hi Shubham! Let's keep going. What scale do you think this platform needs to handle — are we talking hundreds or thousands of small businesses, and roughly how many users would be browsing and buying?

#
focusing time to market and low operational cost  so I think we will not have like much users we will have like  5000 to 10000 Max users and we have to build the system for those users
That's a reasonable scope given the focus on quick time-to-market and low costs. Now let's start with the high-level design.

Can you sketch out the major components of this system on the canvas and show how they connect?

#
so before that I will write the functional and non functional requirements of design
Sure, go ahead and list them out on the canvas!

#
so we need API for product listing  and then we need Shopping Cart experience
I can see you've started writing the functional requirements on the canvas. Go ahead and complete your list — what other functional and non-functional requirements would you include?

#
then we also need API  for payment processing
Good — so product listing, shopping cart, and payment processing APIs. What about non-functional requirements, given the emphasis on quick time-to-market and low operational costs?

#
so non function  non functional requirement that  low operational cost  and  quick delivery  quick delivery of project
I can see you've captured those on the canvas. Those are important constraints that will shape your design decisions.

Now that we have the requirements laid out, let's move to the high-level design. Can you sketch out the major components of this system and how they connect on the canvas?

#
so  we are not focused on scalability here  we are focus mostly on quick delivery  and a working solution
That's a fair trade-off given the constraints. Now can you draw out the high-level architecture — what are the main components you'd need, and how would they interact with each other?

#
so we will have a API gateway
I can see you've started drawing a client and an API Gateway on the canvas. What other components would sit behind the API Gateway to handle the core functionality?

#
I am thinking we should have separate service for like catalogue service or like shopping card service or should be combine them because the actually want to know operation I'll call so maybe we should combine them for now
That's an interesting trade-off to consider. What factors are you weighing when deciding between a single combined service versus separate services, given your constraints?

#
so in case we actually want to quickly quickly ship the product  so we can use a joint molar music application that has all the features like it has a catalogue service it has a shopping card service and payment service  but as we scale we can like him to difference
I see you've drawn a single "Backend service" on the canvas behind the API Gateway, which aligns with your monolithic approach for quick delivery.

Can you flesh out the diagram more — what about the database layer and any external services this backend would need to interact with?

#
we can use an SQL database because our data is structured data
I can see you've added an SQL database to the diagram. Can you draw the connections between these components to show how data flows — for example, what happens when a user browses products or adds something to their cart?

#
to we can have two back and service userback and service and admin back and service
I can see you've added both a User Backend Service and an Admin Backend Service on the canvas. Can you walk me through why you decided to split the backend into these two services instead of keeping it as a single monolith?

#
I have hello
No worries! Go ahead and continue with your design. Can you show on the diagram how these two backend services connect to the other components — the API Gateway, the database, and any external services?

#
hello you can check I have drawn the diagram
I can see your diagram! You've got a good structure forming:

Client/Buyer and Seller connecting through an API Gateway
User Backend Service and Admin Backend Service behind the gateway
SQL Database for data storage
External Payment Provider connected to the backend
Various API endpoints labeled like GET /products, POST /product, GET /cart, PUT /cart, POST /buy
Let's dive deeper into this. Walk me through what happens when a buyer clicks "buy" — what's the flow from the client all the way through to the payment provider?

#
so I will give you I have sketch the diagram so  what this diagram consist  so we have to clients the one is the buyer and one is the seller so seller will actually so we have seller side API like that products and get product and then we have post product s and we can also get a single product of a cell
I can see those API endpoints on your diagram. Let me focus on one specific flow — when a buyer hits POST /buy, what happens step by step between the User Backend Service, the External Payment Provider, and the SQL Database?

#
okay so I'll explain the user flow that is the buyer flow so we already have items in our database products in our database and it will actually Fetch the get products CBI the product CBI will actually list down all the products so it will contains like product name description and cost all these title and then he can like on each product and so when he Clicks on each product he will get product API and he will get a full image of that product and  all these details so  and then so when he cause thepi get product or get products it actually goes to the user back and service read the data from the SQL database so it has the product description
Good, that covers the browsing flow. Now what happens after the buyer decides to purchase — they add items to the cart and hit POST /buy? How does the payment flow work between your User Backend Service and the External Payment Provider?

#
okay so in case of a post by so user has items in his cart so we have cart API get slash card and put cart so he can add items in the card so when he clicks the bi I that is post by Appa so that API reaches the API Gateway and API Gateway outside to the back end service back and service checks with the database that the that the product do the validations that the product we have the necessary product in our database means we have the necessary we have the quality have all the quantities of product it actually
Good — so the backend validates product availability first. Then what happens next with the External Payment Provider? I see you have arrows and labels like "payment API" and "payment status check" on your diagram — can you explain that interaction?

#
hello  hello vacant service receives by request it actually validates all the parameters are valid and we have the necessary we have all the items currently available with us from and then after the validation it actually initiate and external payment API call to the external payment provider for example anything and external payment details  and we pass them the payment details and the user external payment they do the validation on their side and the after the payment is confirmed from their side they return the success response to US after a successful response come back to our database and we update the new update the catalogue the new with the new  with the new quantity of the product now now we have updated the product and we return the response to the user that your payment has been successful
That's a clear walkthrough of the purchase flow. One thing I want to probe on — what happens if the External Payment Provider confirms the payment, but your system crashes before updating the database with the new quantity? How would you handle that scenario?

#
hello  hello so in case  when we have initiated a payment with the external payment provider and before getting the confirmation our back and back and it crashes  in that case  we have the payment status in our database is also so we can asynchronously we can do easing job that will actually update all the pending status of the payments and its checks with the external payment provider so we have this payment status check API call that we have drawn with the grey green marker so it periodically checks the payment status of the pending payments  so even after our back and service
That's a thoughtful approach — using an async job to reconcile pending payment statuses. I can see the "payment status check" arrow on your diagram going to the External Payment Provider.

Let's move on to scaling considerations. Given your current architecture with two backend services and a single SQL database, what would be the first bottleneck you'd expect as traffic grows beyond your initial 5,000-10,000 users?

#
also I have drawn like because we actually want to user to show the users images so we can like Fetch the images from the S3 S3 bucket we will read  in our get products product API
I can see the S3 component on your diagram with a "read" arrow from the backend. Good thinking for serving product images.

Now back to scaling — as your platform grows beyond the initial user base, where do you see the first bottleneck forming in this architecture?

#
as the number of users will grow  so we will so we will have more reads  the as compared to number of rights so  so our database will have  every time we are doing a select query so we actually have some replicas of the database  so we need replicas of the database and we should have to make it highly available
That's a good observation about the read-heavy nature of the workload. You mentioned database replicas — what trade-offs would you need to consider when introducing read replicas, particularly around data consistency for things like product quantities during a purchase?

#
in case if we have replicas of database then for example like we have a writer instance of the database and then we have a reader instance so so whenever there is an update it goes to the writer instance and using the right to head locks these these changes are propagated to read a instances also due to this replication lag We The Reader instance will have some still data or like  data  that just got recently updated with them seconds so yeah we will show incorrect numbers to our uses for example it may happen that the product has been sold out but we have still showing to the user that you can like by this product so that is  a negative of this having an application
Good analysis of the replication lag trade-off. You identified the stale data problem well, especially around product availability.

Beyond the database, what about the backend services themselves — if traffic increases significantly, how would you scale the User Backend Service and Admin Backend Service?

#
yeah in case yeah we actually back and service that actually serve you buyer facing API and then we have atwin bacon service that actually serves epi for the sellers so they actually need to be these two services will have load so we actually need to scale them out  and so one more bottle is the payment processing so we actually waiting for the response  so we it may happen like all of our connections are actually exhausted to the external payment
You've identified two important bottlenecks — scaling the backend services and the connection exhaustion to the external payment provider. How would you address the payment provider connection issue specifically?

#
so we every time like we have a payment request from the user  after we have done all the validations from our database that we have all the available we have stop of the product then we when we initiate a payment  so every time we are actually calling the payment API  so what we can do instead of like short polling or long pulling  we can we can have endpoint on our side and we can ask them that they can call this and point whenever the payment is done  so in this way we all of our connections are not loss immediately and update the status when we get a successful response from that we actually update the status of the payment in the other SQL database also and user will get after that so we solve the problem of like hanging connections with the external server external payment server
So you're suggesting a webhook-based approach where the payment provider calls back to your service instead of your service waiting for a response. That addresses the connection exhaustion well.

Can you update your diagram to show this webhook flow and how the user would know their payment was successful, since the response is now asynchronous?

#
ok  so  we can have
Take your time — go ahead and sketch out the webhook flow on the canvas, showing how the payment confirmation gets back to the user.

#
I am driving the API
No problem, take your time drawing it out on the canvas. Let me know when you're done and I'll take a look!

#
actually call this API with the  new status of the payment like
Got it — so the External Payment Provider would call back to your service with the payment status. Once you've finished updating the diagram, walk me through how the buyer would be notified that their payment was successful, since they're no longer getting an immediate response.

#
hello  hello
Hi Shubham! How would the buyer know their payment went through, since with the webhook approach the response isn't immediate anymore?

#
hello
Hey! Let's keep going — with the webhook approach you described, the buyer won't get an instant payment confirmation. How would you notify the buyer that their payment was successful?

#
hello Desh Ka constant issue with the chat box me  so anyway  so far whenever we our back and service user back and service will get a request of a payment like by API call then it will check do the necessary validation on the database and it will write the information of  it will write the information of purchase in that our SQL database and then it will with the status as pending and then it will go to external payment  will process the payment for example service and  it will just update the status of the of that payment to the actual status that they provide for example
Got it — so the payment record is created with a "pending" status first, then the external provider processes it and calls back with the actual status. But how does the buyer on the frontend know when the status changes from "pending" to "success"? What mechanism would you use to update the buyer's screen?

#
okay so if we immediately want to  post than notification to the user that your payment has been successful or your order has been placed we can actually post the notification from the bacon service to the buyer to the buyer via there AP Vaibhav KPI  means server push  so we can actually  we can have a two way communication or like I would say it can be a single communication
So you're thinking of a server-push mechanism to notify the buyer in real-time. That's a reasonable approach.

We've covered a lot of ground today — requirements, high-level architecture, detailed flows for browsing, cart, and payment, plus scaling considerations like database replicas, service scaling, and the webhook pattern. Your diagram shows a solid understanding of the core components and their interactions. Is there anything else you'd want to add or any concerns about the current design?

#
Server Side Event SSE for pushing notification of payment status to buyer
Good choice — SSE is a lightweight, unidirectional approach that fits well here since you only need the server to push updates to the buyer.

We've had a thorough discussion covering your design. Let me summarize what you've done well:

Clear requirements scoping — you made pragmatic trade-offs favoring quick delivery over scalability
Solid architecture — API Gateway, separated buyer/seller services, SQL database, S3 for images, external payment provider
Well-thought-out API design — clear REST endpoints for products, cart, and purchasing
Good failure handling — the async reconciliation job for pending payments
Scaling awareness — read replicas, connection exhaustion solutions, webhook pattern, and SSE for real-time notifications
A few areas to consider strengthening in future interviews:

Data modeling — discussing the actual database schema and relationships
Security — authentication/authorization for buyers vs sellers
Caching — for your read-heavy product catalog
Visual completeness — updating the diagram as the design evolves during discussion
Overall, solid design thinking with practical trade-offs aligned to the business constraints. Great job, Shubham!

#
Can you provide scores
Here's your evaluation breakdown:

🎯 Design Skills: 7/10

Good component identification and separation of concerns
Solid understanding of external service integration (payment provider, S3)
Could improve on data modeling, caching strategies, and security considerations
🧩 Problem Solving: 7/10

Strong failure handling with the async payment reconciliation job
Good identification of bottlenecks (database reads, connection exhaustion)
Practical solutions like webhooks and SSE
Could go deeper on edge cases and consistency trade-offs
🗣️ Communication: 6/10

Clear verbal explanations of flows and trade-offs
API endpoints were well-defined on the diagram
Diagram could have been more complete and updated as design evolved
Some connectivity issues impacted the flow of discussion
Overall Score: 6.5/10

Key Strengths:

Pragmatic decision-making aligned with business constraints
Good understanding of async patterns and failure recovery
Clear API design
Areas for Improvement:

Spend more time on the visual diagram — keep it updated as you discuss new components
Cover security, authentication, and data modeling proactively
Discuss caching and CDN strategies for read-heavy workloads
Practice walking through flows more concisely and structured
Keep practicing, Shubham — you have a solid foundation to build on! 💪

#
Score for each of them : Requirement gathering,	Design,	Prob-Solving,	Scale & Trade-offs,	Communication
Here's your detailed scoring:

Category	Score	Comments
Requirement Gathering	7/10	Identified core functional requirements (product listing, cart, payment APIs). Good non-functional requirements aligned with business constraints. Could have explored user roles, authentication, data volume, and SLAs more deeply.
Design	7/10	Solid component separation with API Gateway, two backend services, SQL database, S3, and external payment provider. Clear API endpoints defined. Missing security layer, caching, and CDN. Database schema was not discussed.
Problem Solving	7/10	Excellent handling of payment failure with async reconciliation job. Good webhook approach for connection exhaustion. SSE for real-time notifications was practical. Could have explored more edge cases like concurrent purchases of limited stock.
Scale & Trade-offs	6/10	Identified read-heavy workload and proposed read replicas. Recognized replication lag trade-off. Discussed service scaling. Could have gone deeper into caching, load balancing strategies, and database sharding.
Communication	6/10	Clear verbal explanations of user flows. API naming was well-structured. Diagram was a good start but wasn't updated as design evolved. Some chat connectivity issues disrupted flow. Could be more concise and structured in walkthroughs.
Overall: 6.6/10

Top Priority for Improvement: Keep your diagram as the central artifact — update



Technical Skills: Score: 2/4 Justification: Good component identification and API design, but missing caching, security, authentication, and database schema discussions.

Problem Solving Ability: Score: 3/4 Justification: Strong failure handling with async payment reconciliation and webhook pattern. Could explore more edge cases like concurrent stock purchases.

Communication Skills: Score: 2/4 Justification: Diagram was incomplete and not updated as design evolved. Chat connectivity issues disrupted flow and explanations lacked structure.

Pass/Fail Verdict: FAIL — While core components and payment flows were handled well, gaps in technical depth (security, caching, data modeling) and incomplete visual work fall below the bar.

Overall Feedback: Strengths include pragmatic trade-offs aligned with business constraints, solid async patterns (webhooks, SSE, reconciliation jobs), and clear API design. To reach a higher score, proactively cover security/authentication, discuss caching for read-heavy workloads, define database schemas, and keep diagrams updated throughout the interview as your central communication artifact. Practice concise, structured walkthroughs of user flows.