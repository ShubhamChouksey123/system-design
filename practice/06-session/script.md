Welcome to your system design interview! Here's your design challenge:

Design a minimum viable product for a social networking app for a startup with limited resources. Focus on core features like user profiles, posts, and basic interactions while keeping infrastructure costs low.

Use the drawing canvas to the left to create diagrams, system architectures, and visual representations of your solutions. The problem statement has been added to the canvas to get you started.

Think out loud as you work through the problem, and don't hesitate to ask clarifying questions. This interview focuses on your ability to design scalable systems, communicate ideas visually, and think through real-world constraints and trade-offs. I'll guide you through the process and provide feedback at the end.

#
hello I am Shubham and I see your question on the whiteboard
Hi Shubham, great to have you here! Let's dive in.

Before we start designing, let's make sure we understand the problem well. What do you see as the core functional requirements for this MVP social networking app?

#
first I'll read the question to make sure I understand it correctly so the problem says design and MVP social app and design a minimum viable product for a social networking app for a Startup with Limited resource focus on Core features like user profile post and basic interactions while keeping infrastructure cost low
Got it, Shubham. Now that you've read through the problem, what questions do you have about the scope? For example, what kind of scale are you thinking about in terms of users for this MVP?

#
so iless down the functional requirement
Sounds good, go ahead and list them out.

#
so I user should be able to create his or her profile I user should be able to create a post  and
I can see you've started listing the functional requirements on the canvas. Take your time and complete the list — what other basic interactions would you consider essential for this MVP?

#
user can see  view other users  profile  okay and basic interactions while keeping
I see you have three requirements so far — profile creation, post creation, and viewing other users' profiles. What about the "basic interactions" mentioned in the problem — what would those look like for you in an MVP context?

#
okay so these are the function requirement user should be able to create his or her profile he should be able to create a post he should view others profile he should view others post
Those are reasonable starting points. Before we move on, what about the non-functional requirements — given that this is a startup with limited resources, what constraints or quality attributes would you prioritize?

#
and so we can have good to have features  so which are out of scope for now
Sure, what are those good-to-have features you'd consider out of scope for now?

#
we can like  like and comment on post
Okay, so likes and comments are out of scope for the MVP. Now what about the non-functional requirements — I see you've started that section on the canvas but it's empty. What would you consider the most important non-functional requirements given the startup's limited resources?

#
also non function requirement include less time to ship and it should use less resources and its not use existing sdks or EJ D existing libraries so that we can ship and use existing resources to like it in less time
I can see your requirements listed on the canvas now. One thing I'd like to understand — when you say "less resources," are you thinking about the number of users this system needs to support initially? Having a rough scale in mind would help inform your design decisions.

#
no let's resources means less number of services and using means we can use the Monolithic instead of individual micro services  so this way we have we will have we will like we will save on infrastructure  and also on deployments and they are easy Terminus quick to ship
That's a clear rationale for your infrastructure approach. Now let's start with the high-level design — can you sketch out the overall system architecture on the canvas, showing the major components and how they connect?

#
before that I will do some estimation  so sences it is an MVP we can like
Sure, go ahead with your estimations.

#
we can have a total users of  10k  and active users daily active users  which is like 100k1k means one percent of total users  which is 1K
I can see your estimations on the canvas — 10k total users and 1k daily active users. That's a reasonable starting point for an MVP. Now let's move to the high-level design — can you sketch out the overall system architecture showing the major components and how data flows between them?

#
and also daily post per user per day should be  like one or maybe to
Got it — so roughly 2k posts per day. Those are manageable numbers for an MVP. Now let's move on to the high-level design — can you start sketching the system architecture on the canvas showing the major components and how they connect?

#
yes so I'll jumping to drawing the architecture
Great, go ahead and sketch it out on the canvas!

#
hello  I have done the diagram so we should show the requirements it we have to give the infrastructure cost low so I have tried to use less number of components so we have user which is the client and then we have API gateway in which we have authentication we don't have rate limiting now  in MVP then we have a bacon service that is used for user creation profile creation and that returns the feed  and then we have a database that store all these items and also the images of the profile and post is stored in aws3  and then we have a cash so quickly served the feed and to quickly serve the read request we have a cash  and we also have a CD and images fast  and in a cheap way
I can see your diagram — nice work keeping it lean for an MVP. I see the User connecting to the API Gateway with authentication, then to a single Backend Service handling user, profile, and feed, with a Database, Cache, CDN, and S3 for image storage.

Let's dive deeper into the connections. I notice you have several API endpoints listed between the User and API Gateway — can you walk me through what happens when a user creates a post with an image?

#
so when are user period supposed so he hit the opposed / post API the request reaches the API getway and the it does the authentication and it reaches the bacon service  so bacon service rights the post detail the post description and title in the database and also post images into the edblues 3 and image URL is kept in database
That makes sense. I notice on your diagram there's an arrow from the Backend Service to the Cache, and also a separate Read Database. Can you explain the relationship between your Database, Read Database, and Cache — how do these three components work together when a user requests their feed?

#
there's no read database  because we wanted to keep the infrastructure low means at the infrastructure cost low so we are only keeping a single database and in case there is a cash miss then we actually do I select query from the database  and warm up the cash during the return of the request
Got it, thanks for clarifying — so it's just one database with a cache in front of it. I see there's a database-like shape on the right side of your diagram labeled "Read Database" — you might want to clean that up to avoid confusion.

Now, walk me through the flow when a user opens their feed — how does the Backend Service decide what posts to show them, and how does the cache fit into that?

#
I went made any read database  there's no read database there is a single right single database that is used for both read and write but there is a cash to serve faster request read request
Understood, my mistake — one database for both reads and writes, with a cache layer for faster reads.

When a user requests their feed via GET /posts, how does your backend determine which posts to return — is it all posts from all users, or is there some filtering logic involved?

#
so when I user wants to see the post he had the get post API so it reaches via API gateway to back and service it it returns the all the post in  it's sorted order of from latest  and such as the images and return the images URL to the user user actually fats time is URL from a image from the Cds cash  CD and  cdn
That makes sense — so the feed is simply all posts sorted by latest, and image URLs are resolved through the CDN. That's a reasonable approach for an MVP.

How would this system handle scale if your startup grows beyond the initial 10k users — what would be the first bottleneck you'd anticipate?

#
so the first bottle neck is we have a lot of in case the number of users will increase so the read queries on the database will increase  and so we need replica read replica of the database so that we have less number of queries on the database read queries
That's a good observation. What factors would influence your decision on when to introduce that read replica versus just scaling up your existing single database?

#
I think when the throat on database is  large like on a single table then we should have a replicas and if we have less through port is constant or tables and we have less a throat on each table and we can like increase the size of the database we can do a verticular scaling and when we know that there is  there high report on a single table Den vi shud Haveli class  replica
That's a reasonable approach — vertical scaling first, then read replicas when throughput on specific tables becomes a bottleneck.

Beyond the database, what other component in your architecture could become a bottleneck as traffic grows, and how would you address it?

#
so the bacon service will also be a bottle lack and will be a single point of failure so we need to split the bacon service so we can have services different service for feet and then we can have different service for profile creation and profile update
Interesting — so you'd decompose the monolith into separate services as you scale. That's a shift from your initial MVP approach of keeping everything in one service. What trade-offs are you considering when making that transition from monolith to microservices?

#
so when we are transactioning from Monolithic application to a micro service then we actually have to so we  so one thing is like we have to do multiple deployments of each services so we have more operational cost  and then we have there will be more service to Service communication  and  so there is a network latency also  in in monolith we have like local calls or like inter process calls but in micro services we have like call over the network so that are that is also costly  and also as we are creating each services we will have to like beer additional infrastructure cost and maintenance cost
Those are solid trade-offs to consider. Let me ask you one final question — looking at your current design, you have authentication handled at the API Gateway level. If a user's session or token is compromised, how does your system handle that scenario?

#
so so in case we got a request that one of the users session token is  compromised  so what we can do is we can update the entry of the session token as null and user has to again use the username and password to do a login again
That makes sense as a basic approach. Where would that session token be stored in your current architecture — in the database, the cache, or somewhere else?

#
we will we will store the session to comes in database  but we can keep the session to comes in cash for faster reads  so a database have a permanent copy and then we have for persistence then we in the cash we can have read copy read only copy
Good thinking — database for persistence and cache for fast lookups on every request. That wraps up our design discussion nicely.

Summary of your design:

You've designed a lean MVP architecture with a clear rationale for keeping costs low — a single monolithic backend, one database, a cache layer, CDN, and S3 for media storage. You identified sensible API endpoints and understood the data flow well.

Strengths:

Clear alignment between MVP constraints and architectural decisions (monolith over microservices)
Good understanding of caching strategy and when to use it
Practical scaling path identified — vertical scaling first, then read replicas, then service decomposition
Solid awareness of trade-offs when transitioning from monolith to microservices
Areas to explore further:

Feed design could benefit from thinking about pagination and how it scales as post volume grows
Consider how you'd handle user-to-user relationships (following/connections) if that becomes a feature
Think about what data your cache invalidation strategy looks like when posts are created or updated
Security considerations beyond session tokens — input validation, authorization (e.g., can a user edit someone else's post?)
Overall, solid work keeping the design pragmatic and cost-conscious for a startup MVP. Great job, Shubham!

#
hello based on my today's performance I want you to rate on a scale of 1 to 10 on my performance IT these different criterias	Req.	Design	Prob-Solving	Scale & Trade-offs	Comm.	Overall
Here's your rating based on today's performance:

Criteria	Rating (1-10)	Comments
Requirements	7/10	Good functional requirements identification. Estimations were reasonable. Could have explored more edge cases and clarified "basic interactions" more deeply.
Design	6/10	Clean, lean MVP architecture with appropriate component choices. However, the diagram had some confusing elements (the read database ambiguity). API design was decent but lacked detail on request/response payloads and data models.
Problem Solving	6/10	Solid reasoning for choosing monolith over microservices. Session compromise handling was basic but functional. Could have proactively identified more edge cases and failure scenarios.
Scale & Trade-offs	7/10	Strong understanding of scaling path (vertical → read replicas → service decomposition). Articulated monolith-to-microservices trade-offs well including network latency, operational cost, and deployment complexity. Could have discussed cache invalidation and feed pagination.
Communication	6/10	Explained ideas clearly verbally. Diagram was functional but could have been cleaner and more organized. Some visual elements caused confusion.
Overall	6.5/10	A solid MVP-focused design with good cost-consciousness and practical thinking. To improve: spend more time on detailed data flows, clean up diagrams for clarity, proactively address failure scenarios, and think deeper about data modeling and API
#
provide a verdict  for the interview
Interview Verdict: LEAN HIRE ✅
Shubham, here's the overall assessment:

What Went Well:
MVP Mindset: You consistently aligned your design decisions with the startup constraint — choosing monolith, single database, and minimal components showed practical thinking
Scaling Awareness: You demonstrated a clear mental model of how to evolve the system — from vertical scaling to read replicas to microservices
Trade-off Articulation: Your explanation of monolith vs microservices trade-offs (deployment cost, network latency, operational overhead) was well-reasoned
Areas for Improvement:
Diagram Clarity: Your visual work had ambiguous elements that caused confusion — in a real interview, a clean diagram speaks louder than words
Depth of Design: You stayed mostly at the surface level — missing details like data models, cache invalidation strategy, pagination, and authorization logic
Proactive Thinking: You mostly responded to questions rather than proactively identifying challenges, failure modes, or edge cases
Communication: Some explanations were scattered — practice structuring your thoughts before speaking (e.g., "There are 3 things here: first... second... third...")
Recommendation to Improve:
Practice drawing clean, well-labeled diagrams quickly
For every component you add, ask yourself "what happens when this fails?"
Go deeper into data modeling and API contracts
Practice structured verbal communication
You're