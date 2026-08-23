Welcome to your system design interview! Here's your design challenge:

Design an online learning platform for skill development. Include course creation, student progress tracking, and community features with emphasis on user experience.

Use the drawing canvas to the left to create diagrams, system architectures, and visual representations of your solutions. The problem statement has been added to the canvas to get you started.

Think out loud as you work through the problem, and don't hesitate to ask clarifying questions. This interview focuses on your ability to design scalable systems, communicate ideas visually, and think through real-world constraints and trade-offs. I'll guide you through the process and provide feedback at the end.

#
hello good evening  hello good evening this is Shubham
Hi Shubham, welcome! Let's get started.

Before we dive into designing the system, I'd like to understand how you think about the requirements. What are the key functional requirements you'd focus on for this online learning platform?

#
hello  I'll read the question and mixture to make sure that I understand it correctly so the problems is designer learning platform so designer online learning platform for skill development include code creation student progress tracking and community features with emphasis on User experience ok
That's right, you've read through the problem statement. Now let's make sure we're clear on the scope before designing anything.

What types of users do you envision using this platform, and what would each type of user need to be able to do?

#
hello  MI audible  hello The Automatic sending of messages is not working
No worries, I can hear you! Let's continue.

You were about to discuss the types of users for this platform. What different user roles would you expect in this learning platform?

#
what do you mean by include course creation and community feature with emphasis on User experience
Great question for clarification. The problem is asking you to design a platform where courses can be created and consumed, students can track their learning progress, and there are social/community elements like discussions or forums — all while keeping the user experience smooth.

With that understanding, what types of users would interact with this system and what key actions would each perform?

#
and so do we have like so cold creation is by like the teachers and student progress tracking should this be given to students as well as to  two teachers
That's a good clarifying question — you're already thinking about the different perspectives. For the purposes of this interview, I'd like you to make that design decision yourself.

What would you propose, and what's your reasoning?

#
so do we have two types of clients like the students and teachers where teachers can create a course and students can enroll on the course and both students and teachers can like see their progress and like the community features are for like for all for all students as well as teachers
That sounds like a reasonable starting point for the user roles. Now let's think about scale — roughly how many users would you design this platform for, and what non-functional requirements would be most important for a learning platform like this?

#
list down the functional requirements before like the  so there are teachers  so teachers can create a course  which  also  add video content
I can see you've started writing down the functional requirements on the canvas. Go ahead and continue listing them out — what other functional requirements would you include for teachers, students, and the community features?

#
dhantera students  that can enroll  for a course
Good, I can see you're building out the requirements on the canvas — teachers creating courses with video content, and students enrolling for courses. Keep going — what other key actions would students need, and what about the community features and progress tracking?

#
so there is a community forum in which people can add post and the post can include blocks as well as  and video content  and  users and teachers  can comment  on the post
I can see you've laid out a solid set of functional requirements on the canvas covering teachers, students, and the community forum. Now before we move to design, what about non-functional requirements — what qualities would be most critical for this learning platform in terms of performance, scale, and reliability?

#
so I'll just give you like tell you what are the function requirements for teachers can create a course at blogs and video content in a course and track progress of each student androlled in the course then they are students who can enroll for a course like his progress and then there is a community forum that is open to all and in that forum like we can search community post related to any topic or course so will have a catalogue for post and then  we can add post which include like blogs and video content
That's a comprehensive set of functional requirements. Now what about the non-functional side — for example, how many concurrent users would you design for, and what would be the most critical system qualities like availability, latency, or consistency?

#
and then users and teachers can add comments on the post
Got it, comments on posts as well. Now let's think about the non-functional requirements — what scale are we designing for and what system qualities matter most for a learning platform like this?

#
yeah  so I will jump next to  what are the non function requirements
Go ahead, what non-functional requirements would you prioritize for this platform?

#
should be highly available  and
I see you've noted high availability on the canvas. What other non-functional requirements would you consider important — think about what would matter most to users consuming video content and interacting with the community?

#
it should have a low Lite and see
Good — high availability and low latency. Those are important. Now that we have a solid understanding of the requirements, let's move to the high-level design. Can you sketch out the major components of this system and how they connect on the canvas?

#
also now we have good to have features  like during enrollment  payment of payment for a course
Good, payment as a nice-to-have is noted. Now let's start with the high-level design — can you sketch out the major system components and how they interact on the canvas?

#
so for now we can assume like all these courses of free to all like to all users
Sure, that simplifies things. Let's move forward — can you start drawing the high-level architecture on the canvas? Think about what major components you'd need and how users would interact with the system.

#
I'll jump into the next action that is like will I draw diagrams what all components that we will need
Go ahead and start sketching it out on the canvas!

#
hello I have I have drawn the diagram  so I will tell you the components that we have use so we have to clients student client and her teacher client then we have a API gateway in which we have authentication authorisation as well as later meeting facilities  that we have four services what is create or enroll for service  that will like user will create and enroll enrollment of students will be done in this why this service then there is video processing service so whenever a teacher uploads a video related to US student so this service service actually break that video into small chance and keeps the address of each small files into the database
I can see your diagram taking shape with the two clients, API gateway with auth and rate limiting, the course creation/enrollment service, and the video processing service. I also notice you have a Read Course Service, some database components with reader replicas, and what looks like a Kafka message broker with an analytics service.

Can you walk me through the complete data flow — what happens when a student enrolls in a course and starts watching content?

#
yeah so I'll tell you like first I will tell you the teacher flow so a teacher actually create a course and via some API like post course API and so it goes to the create code service and that service actually reads the course matter data into the database write database  and then also it after that  the teacher client actually upload the video content for that course and it is sent by AP I gateway to the video processing service so video processing service into the database
I can see the teacher flow on your diagram — course creation goes through the API gateway to the Create/Enrol Course Service which writes to the primary database, and video uploads go to the Video Processing Service. I also notice you have an S3 bucket and a CDN in your diagram.

How does the video processing service interact with S3 and the CDN — can you walk me through that connection?

#
small each small chunk of video is uploaded to A W S S 3 and the path  of each small address of each video in S3  this is done by video processing service
Got it, so the video processing service breaks videos into chunks, stores them in S3, and saves the S3 paths back to the database. I see you also have a CDN in your diagram.

What role does the CDN play in serving this video content to students?

#
hello  I will tell you other read path so student troll student like wants to wants to read the content of a course so he hit the get course with the idapi and then that that goes to the read course AP service via API Gateway the read course service patches the course matter data from the read replica of the database also it such is the course small video files from the S3  that this user has having this progress on
I see the read path on your diagram — student requests go through the API gateway to the Read Course Service, which fetches from the reader replicas and S3. You also mentioned the CDN earlier in your diagram — where does that fit into this read flow for serving content to students?

#
yes  so the whenever there is a read  quotes by student it actually fire events and these events are published broker and are red by the analytic service analytic service like do some analytics track of leg student progress as well
Interesting — so you're using Kafka to capture read events and feed them to the analytics service for tracking student progress. That's a good event-driven approach.

I notice you haven't mentioned the CDN's role yet — it's in your diagram but doesn't seem connected to any flow. Also, we haven't discussed the community forum component. Can you walk me through how you'd handle the community forum features?

#
hello hello hello  the role of cdn is instead of fetching each request going to the bacon we actually can cash those request in the cdn so that these request are closed to the user in the as location and a served faster and cheaper
That makes sense — CDN caching video content closer to users for lower latency and reduced load on your backend. Now let's dive deeper into some of the component interactions.

Can you walk me through how the community forum would fit into this architecture — would it be a separate service, and how would it connect to your existing components?

#
I have not actually API for commodity for the forum I'll I am currently adding it just give me some time
Sure, take your time and sketch it out on the canvas!

#
okay hello I have done API so we can have two Services community forum right service and community forum read service and both can use a separate database separate from the separate from course database so this forum database is different
I can see the Community Forum Read and Write services on your diagram with their own separate database that has a primary writer instance and reader replicas — similar to your course database setup.

What made you decide to use a separate database for the community forum rather than sharing the course database?

#
since we can like create small services like community forum service can have its own database it will never interact with the course database because these two are different and we can like have separation of concerns between services and data bases
That's a clear rationale — separation of concerns and independent scaling. Now let's dive deeper into the detailed design.

Walk me through what happens when a student searches for community posts based on a topic or course — how does that flow work through your current architecture?

#
Aansu currently whenever a student hit the apx are post content so this if I will let you let the user create a block post  and  and then the get API get content CBI list all the contents like order by the latest and then there is a get content with id so it will return you the content the post with the ID  so
I can see those APIs on your diagram. You mentioned earlier that users should be able to search community posts based on topic or course. How would you handle that search functionality — would the read service query the database directly, or would you consider a different approach for search?

#
for initial hello for initial we can like use search via content heading  but for later point of time we can use a w s elastic search and we can do a processing over the post and so this will make search more faster and like a deep search rather than searching on the content heading only
That's a reasonable evolution — starting simple and adding Elasticsearch later for richer search. Let's shift to how the system handles scale.

Looking at your architecture, where do you see the biggest bottleneck as the number of users grows significantly?

#
as the number of users will grow so we will have more reads  so read core service will have a high throughput  and that's why we have cash in  CD and cash also we can have cash on the database also so I will add a cash layer  this cash is for course database  and then we can have a cash separate cash for forum database also  so  in case of a cash from the data data from the database and warm up the cash during the return
I can see you've added a cache layer near your course database. That's a good approach for handling read-heavy traffic. You mentioned warming up the cache — what caching strategy would you use, and what data would you prioritize caching versus fetching directly from the database?

#
45 so the cashing strategy that we can use is  we will so whenever there is a read request and we don't have the data in the cash means a cash miss so we set the data from the database  and we add the data at to the cash and return the response to the user
So you're describing a cache-aside (lazy loading) pattern. That works well for read-heavy workloads.

What happens when a teacher updates course content — how do you ensure the cache doesn't serve stale data to students?

#
so in case a course is updated  by the teacher  so we will invalid the cash  and so there will the next will be a cash mess but after that all the request will be from the cash
Good — cache invalidation on writes to maintain consistency. Now looking at your overall architecture, you have separate API gateways shown on the diagram.

Is that intentional — having multiple API gateway instances — and if so, what's the reasoning behind that?

#
we will invalid the cash in validate  the cash
I see you noted cache invalidation. Going back to my question — I notice on your diagram you have what appears to be multiple API gateway rectangles. Is that intentional, and what's the reasoning behind that structure?

#
yeah actually these all the services like the community forum read service community forum right service read core service analytic service create course service and video processing service so these are stateless  we can independently scale them scale out them  so we can do horizontal scaling on the services on API Gateway also it is also stateless  we can independently scale out  horizontally
Good thinking — stateless services enabling horizontal scaling is a solid approach.

Let's talk about a trade-off in your design. You're using Kafka to track student progress through read events — what happens if the analytics service goes down or falls behind processing events? How would that impact the student's ability to see their progress?

#
we can make this kafka brokers  fall tolerant we can have replication in Kaka and in case analytic service goes down  so we will also make the service fault tolerant resignant it will it will read the same data if it hasn't acknowledge the data  so this way we all over events are not missed
That's a good point about Kafka's durability and consumer offset management ensuring no events are lost. But there could still be a delay — if the analytics service is catching up on a backlog of events, a student checking their progress might see outdated information.

How would you handle that potential lag in progress visibility from the user experience perspective?

#
I think we can also handle this on front and site  and  that they can also like increase the percentage if they feel like other this page has been read
Interesting — so client-side optimistic updates for progress while the backend catches up. That's a pragmatic UX approach.

Let's wrap up with trade-offs. Looking at your overall design, you've chosen to separate the read and write services for both courses and the community forum. What are the trade-offs of this approach compared to having a single service handling both reads and writes?

#
a single trade of  the advantages of the separate read and write services is we can scale out both services independently so if we have like a course there are more students in a single course then we just want to score scale the read services not the right services  and  the drawback is we have to like we will have different  we have to reply each service independently so it is burden on our side and we have to manage both services read and write so more work there
That's a well-articulated trade-off — independent scaling versus increased operational complexity.

One final question: you have reader replicas for both your course and forum databases. What consistency model are you accepting here, and are there any scenarios where eventual consistency could cause problems for your users?

#
I think  there won't be any problem with application lab
What about a scenario where a teacher publishes a new course or updates course content, and a student immediately tries to access it — could replication lag between the primary writer and reader replicas cause the student to not see the latest content?

#
replication lag
Right — with reader replicas, there's typically a small delay before data written to the primary is available on the replicas. So if a teacher just published a course and a student tries to access it immediately, the student might not see it yet.

How would you handle this edge case in your design?

#
so we can use a pattern write your reads  so whenever a teacher create a course and he immediately tries to read he will be able to read it by this pattern I think other application like won't be much it is like for AWS it is around 1 second or so that is we should not over engineer this and students will be able to see the course after few minutes that is acceptable like within 34 minutes if they are able to see this is acceptable for our for our system
That's a pragmatic and well-reasoned answer — read-your-own-writes for the teacher who just created the content, and accepting eventual consistency for other users since a short delay is tolerable for this use case. Good judgment on not over-engineering.

We've covered a lot of ground today, Shubham. You've designed a system with clear separation of concerns, event-driven progress tracking, caching strategies, and thoughtful scaling approaches. Let me summarize the key strengths and areas for further consideration:

Strengths:

Clear requirement decomposition with well-defined user roles
Good use of CQRS pattern separating read/write services
Event-driven architecture with Kafka for progress tracking
Practical caching and CDN strategy for read-heavy workloads
Pragmatic trade-off decisions around consistency
Areas to explore further:

The CDN could be more explicitly connected in your data flow for video serving
Search functionality could be fleshed out more in the diagram
Consider how the community forum connects to courses (e.g., course-specific discussions)
Think about how video streaming would work at scale (adaptive bitrate, etc.)
Overall, solid design thinking and good visual communication. Nice job!

#
hi hello I have forgot to add a database schema so should I do that now
We've already wrapped up the interview, but if you'd like to add the database schema to your diagram for your own reference, feel free to do so! It would have been a good addition during the detailed design stage to show how your data is structured across the course and forum databases. Thanks for the interview, Shubham — great effort overall!

#
before closing the interview,  hello before closing the interview I want you to read  rate my performance  on a scale of 1 to 10  on these parameters, Req.	Design	Prob-Solving	Scale & Trade-offs	Comm.	Overall
Here's your performance rating, Shubham:

Parameter	Score (1-10)	Comments
Requirements	7	Good identification of user roles, functional requirements, and community features. Could have explored scale numbers and more non-functional requirements in depth.
Design	7	Solid CQRS pattern, event-driven progress tracking, separate databases for concerns. Missing database schema, search architecture details, and CDN integration in the flow.
Problem Solving	6	Reasonable decisions throughout but some areas lacked depth — video streaming strategy, search implementation, and community-course linkage were surface-level.
Scale & Trade-offs	7	Good understanding of horizontal scaling, caching strategies, read replicas, and consistency trade-offs. Pragmatic reasoning on eventual consistency. Could have discussed more bottleneck scenarios.
Communication	6	Decent visual diagram with clear components and APIs. However, some flows weren't fully connected visually (CDN, search), and verbal explanations sometimes needed prompting to get complete answers.
Overall	6.5	A solid foundation with good architectural instincts. To improve: go deeper into component interactions, be more proactive in identifying edge cases, and ensure your diagram fully reflects all data flows you discuss.
Great effort, Shubham! Keep practicing — you have strong fundamentals to build on. 💪

#
parameters are requirement gathering are design problem solving scale trade of and communication skill and overall feedback overall performance feedback
Here's your updated performance rating, Shubham:

Parameter	Score (1-10)	Comments
Requirement Gathering	7	Good job identifying user roles (teachers/students), functional requirements, and community features. Asked clarifying questions about the problem. Could improve by defining scale numbers (DAU, concurrent users), data volume estimates, and exploring more non-functional requirements like security and data durability.
Design	7	Strong architectural choices — CQRS pattern, event-driven progress tracking with Kafka, separate databases for course and forum, CDN and caching layers, video processing with S3. Missing areas: database schema, search architecture, CDN not fully connected in flows, and no mention of how video streaming works end-to-end.
Problem Solving	6	Made reasonable design decisions and justified them. However, needed prompting to address edge cases like replication lag and stale cache data. Search functionality and community-course linkage were left shallow. Be more proactive in identifying potential issues.
Scale & Trade-offs	7	Good understanding of horizontal scaling for stateless services, caching strategies (cache-aside with invalidation), read replicas, and Kafka durability. Pragmatic consistency trade-off reasoning. Could improve by discussing specific bottleneck numbers and more failure scenarios.
Communication Skill	6	Diagram covered most components with clear API definitions. Some flows were incomplete visually (CDN, search).
#
will you pass what is your update will you pass me or like is it a strong hair leen higher or border line or need some improvement
Based on your overall performance, I'd place you at Lean Hire / Borderline.

Here's why:

What worked in your favor:

You demonstrated solid fundamentals in distributed system design
Good architectural patterns (CQRS, event-driven, caching)
Reasonable trade-off reasoning and pragmatic decisions
What held you back from a Strong Hire:

Required prompting to go deeper — a strong candidate proactively identifies edge cases and bottlenecks
Some components in your diagram weren't fully connected or explained (CDN, search)
Missing capacity estimation and scale numbers
Database schema was not covered
Communication could be more structured and self-driven
To move toward a Strong Hire, focus on:

Capacity estimation — always calculate DAU, QPS, storage, and bandwidth
Be proactive — identify failure scenarios and edge cases before being asked
Complete your diagrams — every component should have clear connections and data flows
Go deeper — pick 1-2 components and show expert-level depth (e.g., video streaming pipeline, search indexing)
Structured communication — lead the interviewer through your design confidently without needing prompts
You're close, Shubham — with more practice on depth and proactive thinking, you can definitely get to a strong hire level. Keep going! 🚀