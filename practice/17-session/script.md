Welcome to your system design interview! Here's your design challenge:

Design a monitoring and alerting system like Datadog that can collect metrics from thousands of servers, detect anomalies, and send intelligent alerts.

Use the drawing canvas to the left to create diagrams, system architectures, and visual representations of your solutions. The problem statement has been added to the canvas to get you started.

Think out loud as you work through the problem, and don't hesitate to ask clarifying questions. This interview focuses on your ability to design scalable systems, communicate ideas visually, and think through real-world constraints and trade-offs. I'll guide you through the process and provide feedback at the end.

#
hello  hello
Let's get started! Before diving into the design, I'd like to understand how you're thinking about the requirements for this monitoring and alerting system.

What are the key functional requirements you'd want to focus on?

#
Can you share the question again?
Design a monitoring and alerting system like Datadog that can collect metrics from thousands of servers, detect anomalies, and send intelligent alerts.

#
Can you share the question again?
Design a monitoring and alerting system like Datadog that can collect metrics from thousands of servers, detect anomalies, and send intelligent alerts.

#
hello we can start the interview
Great, let's jump in! To start, what do you see as the key functional requirements for this monitoring and alerting system?

#
so  I read the question to make sure I understand it correctly so the problems is design a modultering system design a monitoring and allotting system like datadog that Karan collect matrix from 1000 detect a normal intelligent alerts
That's right. So before we start designing, let's clarify the requirements. What are the most important features this system needs to support from a user's perspective?

#
ok before that I just want to  write down the list of items that we are going to discuss in this interview so the first will be the function requirements  and then non function requirement  and then will do estimations  and then we will draw the design  design
I can see you've outlined your approach on the canvas - that's a solid structure to follow. Let's start with the first item on your list.

What functional requirements would you define for this monitoring and alerting system?

#
hello  so we will cover function requirement non function requirement estimations design walkthrough of the design database schema trade of locks monitoring alerts and service level
Sounds like a comprehensive plan. Let's dive into the first item - what functional requirements would you identify for this system?

#
okay  so I will start with the function requirements  so
Go ahead, I'm listening.

#
should be we should be able to collect Matrix and event from different sources a different type of services and purchase the matrix and event in data store  also we should be able to query the data store
I can see you're starting to write these out on the canvas. Those are good starting points - collecting metrics/events, persisting them, and querying the data store.

What about the anomaly detection and alerting side of the system - what functional requirements would you define there?

#
and another point is we should be able to generate the dashboard based on data store
Good, dashboards are important for visualization. What about the alerting functionality - how would you define the requirements around detecting anomalies and notifying users?

#
another we should be able to see time series values of matrix and events and dashboard
You've covered data collection, persistence, querying, and dashboard visualization. But I notice the problem statement specifically mentions anomaly detection and intelligent alerting - what functional requirements would you define for those aspects?

#
ok system  events  that we should be able to
Take your time - what requirements would you define for the alerting piece of the system?

#
matrix user should be able to receive notification on slap and destination
I can see you've added alerting requirements to the canvas - in case of anomalies in metrics/events, users should receive notifications via Slack, PagerDuty, etc. Good.

Now let's move to non-functional requirements. What are the most critical non-functional requirements for a monitoring and alerting system like this?

#
so I have written all functional requirements so I include handle scalebal to handle increasing number of source sending Matrix and event it should be highly available  a real time alerts to destination in case of anomaly durable to see and compare with previous values of matrix and events and can handle a small Data loss which is less than 1% so we are okay with some data loss which is less than 1% of data
I can see your non-functional requirements on the canvas - scalability, high availability, real-time alerting, durability, and tolerance for small data loss (less than 1%). Those are well thought out.

Now let's start with the high-level design. Can you sketch out the overall system architecture on the canvas showing the major components and how data flows through the system?

#
before  design should I do the estimations of throughput
Sure, go ahead with your estimations - understanding the scale will help inform your design decisions.

#
so before that I just want to ask Clady questions so this platform hello  so this Matrix platform
Go ahead, what's your clarifying question?

#
hello
I'm here - what clarifying question did you want to ask?

#
hello  I want to ask the matrix monitoring and a lighting system that we are building so RV building it for internal use or we are going to make it for public use like a SAS product
That's a great clarifying question. Let's say we're building it as a SaaS product - similar to how Datadog operates, where multiple external customers can use the platform to monitor their own infrastructure.

How does that influence your estimations and design thinking?

#
okay  okay so I can write assumptions  that this is a product  like  and  as product like new relic  or data  and that we have retention period of 1 year  for data  and we mostly care about last 7 Day data  after that we can do sampling
Good assumptions - SaaS product, 1-year retention, with emphasis on the last 7 days and sampling for older data. Now go ahead with your estimations.

#
10000 and we can assume that each customer is sending 50 Matrix in 10 second interval
I can see your estimations on the canvas - 10K customers, each sending 50 metrics every 10 seconds. That gives you a sense of the write throughput you'll need to handle.

Can you calculate what that translates to in terms of requests per second so we can understand the scale?

#
okay hello I have done some throughput and storage cost as a storage estimation so we have let's assume we have 10k customers and it each service is actually sending 50 Matrix and 10 second and a customer has 20 different services  total through potatoes 50 into 20 into 10 into 10 power 3 / 10 second that is one million request per second  and then each Matric pay load is of side 100 byte and the Matric failure include metric name for example of that Matrix and then account Id and infra detail like coordinator spot detail that from which it is coming  and then so the total size of 100 MB into 1 into 10 power 6 that is 100 MB per second pay load is coming to our service  per second 100 MB per second  and that for 7 days to reach cost is 10 TB
I can see your estimations on the canvas - 1 million requests per second with 100 MB/s of incoming data, and about 10 TB for 7 days of storage. That's a significant write-heavy workload.

Now let's move to the high-level design. Can you sketch out the overall system architecture on the canvas showing the major components and how data flows through the system?

#
architecture  hello hello  hello I have done the architecture
I can see your architecture on the canvas! You've drawn out a comprehensive system with metric sources, a metric collector (with AuthN, validation, rate limiting), Kafka, metric enrichment, time series database, query gateway, query service, an alerting system, notification service with integrations to PagerDuty, Slack, and Email, along with dashboards.

Let's dive deeper into this design. Can you walk me through the data flow from when a metric is generated at the source to when it gets stored in the time series database?

#
hello  so I'll give you a walkthrough of like Matrix sending from the client to our database  so so clients different client will use our API and  also the matrix character is  the one that actually is the end point for those and it does authentication and does validation of the payload and does rate Limited rate limit and then after that it actually send those Matrix to the matrix enrichment service does some aggregation over the matrix those type of events and based on the drop it actually Matrix to the times time series data store  from the matrix source we generates Matrix and events in after every periodic interval for example CPU percentage utilisation and in every 10 seconds and send it also does some aggregation on its side and send the request to matrix collector
Good walkthrough. I notice you have Kafka between the metric collector and the metric enrichment service. What role does Kafka play in this flow, and why did you choose to place it there?

#
is there to make sure we are not adding too much load on Matrix and service  directly send the data to the time store data store because  writing the database actually take some time and we want don't want the request to hold that much period of time so we want to immediately acknowledge the request and between
That makes sense - Kafka acts as a buffer to decouple the ingestion from the processing and storage. Given your estimation of 1 million requests per second, how would you handle the scenario where the metric enrichment service falls behind in consuming from Kafka?

#
so what we will do is we will create multiple instances of matrix enrichment service so  so we will scale that Matrix enrichment service
How would you partition the data in Kafka to ensure those multiple instances of the enrichment service can process in parallel effectively?

#
so what we can do is we can  has a data key versus The payload so we can use user ID or the customer ID or other account Id as the key and  so all the data of a single customer is actually going to a single topic so in this way we are serialising the data of a single customer as well as we are actually parallelising for different customers  so we can have like we can have we can scale the number of partitions  to paralyse the process
Good reasoning - partitioning by customer/account ID ensures ordering per customer while enabling parallelism across customers.

Now let's look at the alerting side. Can you walk me through how the alerting system detects anomalies and triggers a notification to the end user?

#
hello  hello
I'm here - can you walk me through how the alerting system works? I can see it on your diagram with scheduled queries and notification events to Kafka.

#
yeah so I give you an example of a Matric for example CPU percentage utilisation so I user can have user can create an alert if the percentage utilisation of CPU is greater than 80% that he should be allotted  so he has created an alert and that is stored in alerts TV and the alerting system actually queries the wire service that time store data store so the alert in system value of the metric or that event is greater than the threshold then that is an anomaly and that will instantaneously create and a notification event to the Kaka of that alert so that allowed goes tough cut to the notification service so notification service  the user data users to which it has to send and the pizza duty integration key from the integration ki data store now we know what is the destination that we connect two and what are the user details so it notification service create also resolves the templates those values in the template and using the integration key for example
Good walkthrough of the alerting flow. I can see on your diagram that the alerting system runs scheduled queries based on configured rolling periods (2 mins, 5 mins, etc.).

What happens if you have thousands of customers each with dozens of alert rules - how does the alerting system handle that volume of scheduled queries without overwhelming the time series database?

#
hello  hello so I haven't finish the previous walk through like after the notification service actually create the payload it cause the upi's of a pizza DT are using the client integration key and the period duty actually send the notification to the client engineer that is in the customers team and the engineer can actually look at the show dashboard to know more information about the anomali and he can just go and fix those back or  and
Thanks for completing the walkthrough - so the notification service resolves the destination, builds the payload using templates, calls external APIs like PagerDuty using integration keys, and the engineer then uses the dashboard to investigate further.

Now back to my earlier question - with thousands of customers each having multiple alert rules, how would you ensure the alerting system can handle that query volume without becoming a bottleneck?

#
so I told you the alertting system will query the data store using the query service so we have to scale we have so there actually that are being fired every every second  so what we can do we can we will start the data store based on the customer ID so  so will have multiple instances of data store and each data store will have one data store and also we will have backups of the those data store so now we have actually we have started the data store and we have large number of data stores and we can query the request of from lettering system
So you're sharding the time series datastore by customer ID and scaling the query layer. That makes sense for distributing the read load.

Let's move to scale and trade-offs. Given your system is handling 1 million writes per second and 100 MB/s of data, what do you see as the biggest bottlenecks in this architecture?

#
it can be here  I think the bed
Take your time - what do you see as the biggest bottleneck in your system?

#
hello  I think the biggest bottle like would be that since that throughput is actually very high so we have a large data injection  so our data store will actually be filled up after every interval after every periodic interval so what we have to do is we have to  we have to  we have to compress the size of the data so for that we will use 3 technics one of the technics like we will encode the data and then we will compress the data  The Other technique is like I told you the wedding so we will start the data so each each each ad will have a portion of the of the total datas data  The Other technique that we can use is  we will use cold storage so in case like we told we people will not will will be less concerned about data that is old old data the data that is older than 7 days  so we will move that from to a cold storage  so and also another technique that we will use the sampling so so I told you the event that is CPU percentage utilisation so for older data what we will do is we will do sampling so for example we can have like
Good points - you've identified data compression, encoding, sharding, cold storage for older data, and sampling as strategies to manage the storage bottleneck.

Beyond storage, what about the ingestion path itself - with 1 million requests per second hitting your metric collector, what trade-offs are you considering there?

#
it so so Matrix collection Matrix collector matrix  collector will have a high throughput so we can also scale that service up  scale out that service so will have multiple instances of matrix collector running  so each collector will have a portion of the total load  so will have a Load Balancer in front of it
Good - horizontal scaling of the metric collector with a load balancer in front. Given that you mentioned earlier that you can tolerate less than 1% data loss, how does that trade-off influence your design decisions around the ingestion path, particularly between the metric collector and Kafka?

#
so in case The Matrix collector has too much load  and the request Q is actually field up  so we'll do scaling horizontal scaling of matrix collector but in case the request Q is filled up we can reject those request  so that  also will scale out the cuff cut and will have and will increase the number of partitions in the car  in the kafka
So you'd reject requests under extreme load as an acceptable trade-off given the less than 1% data loss tolerance. That's a reasonable approach.

What about the alerting system - you mentioned it runs scheduled queries. What happens if an alert rule triggers repeatedly for the same issue? How would you prevent alert fatigue for the on-call engineers?

#
so yeah what we can do if in case the same alert  is open  and the issue is not resolved and the query service is actually querying the same alert  then we will will have the data that this is actually alertting but we will not send that to the kafka and eventually not sending it to the notification service so that the same type of alert is not means the on call engineers don't have so many alerts after every rolling Period of the same and normally  so will check based on the open alerts and we will not send notifications based on open alerts
Good thinking - deduplicating alerts based on open/unresolved state to prevent flooding engineers with repeated notifications for the same issue.

Looking at your overall architecture, you have several databases - the time series datastore, alerts DB, user DB, and integration keys store. What factors would influence your choice of database technology for the time series datastore specifically, given the write-heavy workload?

#
so for time series data store will not use sequel database or no sequel database we will use instant we will use time  actually  provide time series  on different columns  and provide aggregation result on different values
You're suggesting a purpose-built time series database. Given your requirement of 1 million writes per second, what specific characteristics of time series databases make them suitable for this workload compared to a general-purpose database?

#
hello  so for this type of database we actually want aggregations on multiple columns  and also we actually want to do time series queries and the sequel and no sequel database are not good in that means they are not a date they are not performance high performance in terms of time series based queries  so we actually want good aggregation  and we always want to query the latest data so we want
That makes sense - optimized for time-based queries, aggregations, and recent data access patterns.

We're coming towards the end of our interview. Looking at your overall design, if you had to pick one area where you'd be most concerned about reliability, which part of the system would that be and why?

#
hello yeah I have less down on the items I told you functional non function requirement estimation walk through I have given you the work through I think we can we have database schema trade of and locks monitoring and alerts and service level are left
We've covered a lot of ground already. Let's focus on the reliability question - which part of your system are you most concerned about from a reliability standpoint, and what would you do to address it?

#
so for reliability there are two  things two components of the design that I  that I am concert about one is the time series data store that it should handle this amount of queries means large amount of high throughput queries and another component that is half cup because managing production
You've identified two critical components - the time series datastore and Kafka. Both are in the hot path of your system.

We're wrapping up the interview. Is there anything else about your design that you'd like to highlight or any trade-offs you want to call out before we finish?

#
yeah so the two critical components the kafka the second one is kaka because managing a kaf ka cluster in production environment is stuff  stuff  t o u g h
That's a valid concern - Kafka operations at scale can be complex. Would you consider any alternatives or managed solutions to address that operational burden?

#
we can use AWS SMS
Good - a managed service like that would reduce the operational overhead significantly.

Alright, let's wrap up the interview. You've covered a comprehensive design including metric ingestion with collectors, Kafka for buffering, metric enrichment, time series storage, a query layer with dashboards, and an alerting system with notification integrations. You've also addressed scaling strategies like sharding, horizontal scaling, cold storage, and sampling.

Thank you for walking through your design - you demonstrated solid thinking around the data flow, scalability concerns, and trade-offs in the system. Great job!

#
no we will use AWS SNS sqs
Got it - AWS SNS/SQS as a managed alternative to Kafka to reduce the operational complexity of managing a message queue cluster in production.

Alright, let's wrap up the interview. You've put together a comprehensive design covering:

Ingestion: Metric collectors with auth, validation, and rate limiting
Buffering: Message queue (Kafka/SNS+SQS) to decouple ingestion from processing
Processing: Metric enrichment with aggregation and drop rules
Storage: Sharded time series datastore with cold storage and sampling for older data
Querying: Query gateway and service layer powering dashboards
Alerting: Scheduled query-based anomaly detection with deduplication to prevent alert fatigue
Notifications: Notification service integrating with PagerDuty, Slack, and Email
You showed good awareness of scale challenges at 1M requests/second and practical trade-offs like tolerating small data loss under extreme load. Thank you for your time and effort!

#
one call of that I want to make before ending the interview is like we also want to rate Limited the customers because people might do a Doss attack The dawss Attack by sending a large amount of matrix and so it can actually means it can  it can take too much resource of matrix collector and kafka  also we don't want to  we don't want the genuine customers to block their matrix from sending their Matrix so we actually have to wait limit those so does a trade of between what events to allow and what Matrix to reject from the customer so red limit is a mass  must must
That's an important callout - rate limiting is critical both for protecting your system from abuse and ensuring fair resource allocation across customers. I can see you already included rate limiting in your metric collector component on the diagram, which shows good foresight.

The trade-off you mentioned between protecting the system and not blocking legitimate traffic from genuine customers is a real-world challenge that's very relevant at this scale. Great observation to end on!

Thank you for a thorough interview - you demonstrated strong system design thinking throughout. Good luck!

#
should I also draw the schema design database schema
We've covered the main areas of the design well, and we're at the end of our interview time. Your architecture diagram already captures the key data stores and their relationships effectively.

If you'd like to briefly call out the key fields for one or two of your most critical tables, go ahead - but keep it brief!

#
I would say the most critical tables are user table integration keys for different destinations alerts containing alerts alerts type service levels and time series data store that is most critical  and also secrets management API keys
Good identification of the key tables. You've called out the critical data entities:

Users - customer/user details
Integration keys - PagerDuty, Slack credentials etc.
Alerts - alert rules, thresholds, alert state
Time series datastore - the core metrics data
Secrets/API keys - authentication credentials for customers
These align well with the databases you've already drawn on your diagram.

That's a wrap! You've delivered a solid end-to-end design covering ingestion, processing, storage, querying, alerting, and notifications - with thoughtful consideration of scale, trade-offs, and operational concerns. Well done, and thanks for your time!

#
kya we can add that .  we can and the interview I also want you too rate on these on this criterias Verdict	Req.	Design	Prob-Solving	Scale & Trade-offs	Comm.	Overall	Revised
Here's my evaluation based on your interview performance:

Category	Rating	Notes
Requirements	✅ Strong	Covered functional & non-functional requirements well, good clarifying question about SaaS vs internal, solid estimations with throughput and storage calculations
Design	✅ Strong	Comprehensive architecture with clear components - ingestion, buffering, processing, storage, querying, alerting, and notifications. Good use of Kafka for decoupling
Problem-Solving	✅ Moderate-Strong	Identified key challenges like alert deduplication, rate limiting, and data volume management. Could have gone deeper into anomaly detection logic
Scale & Trade-offs	✅ Moderate-Strong	Good strategies - sharding, horizontal scaling, cold storage, sampling, managed services. Acknowledged acceptable data loss trade-off. Could have explored more bottlenecks beyond storage
Communication	⚠️ Moderate	Good visual diagram with clear data flows. Walkthroughs were comprehensive but sometimes took multiple attempts to articulate points clearly
Overall	Moderate-Strong	Solid end-to-end design with good awareness of real-world concerns. Estimations were well done. Areas for improvement: deeper dive into anomaly detection algorithms, more structured verbal communication, and exploring failure scenarios more thoroughly
Key Strengths: Thorough estimations, comprehensive architecture, practical trade-off awareness (rate limiting, data loss tolerance, managed services)

#
can you also provide me numbers on a scale of zero to 10 for each of them
Here's your updated evaluation with numerical scores:

Category	Score	Rating	Notes
Requirements	7/10	✅ Strong	Good functional/non-functional coverage, solid estimations, good clarifying question about SaaS. Could have explored more around multi-tenancy and data isolation requirements
Design	7/10	✅ Strong	Comprehensive architecture with clear components and data flows. Good use of Kafka, query gateway, and notification service. Could have detailed the anomaly detection logic more
Problem-Solving	6/10	✅ Moderate-Strong	Good alert deduplication, rate limiting awareness, and cold storage strategy. Could have explored failure scenarios, retry mechanisms, and more sophisticated anomaly detection approaches
Scale & Trade-offs	6/10	✅ Moderate-Strong	Solid strategies with sharding, horizontal scaling, sampling, and managed services. Could have discussed caching, read replicas, multi-region, and more detailed capacity planning
Communication	5/10	⚠️ Moderate	Good visual diagram with clear data flows. However, verbal explanations were sometimes fragmented and required multiple attempts to articulate points clearly
Overall	6.5/10	Moderate-Strong	Solid design with practical awareness of real-world concerns
Areas to Improve:

Deeper exploration of anomaly detection strategies
More structured and conc
#
also what is the verdict is it borderline leen higher or strong higher or higher
Based on your scores, here's the verdict:

Verdict	Assessment
Overall: Borderline Lean Hire	6.5/10
Reasoning:

You demonstrated solid foundational knowledge with a comprehensive architecture and good estimations. However, to move into Strong Hire territory, you would need:

Deeper technical depth - Anomaly detection algorithms, failure handling, retry mechanisms, exactly-once vs at-least-once delivery semantics
Broader scaling discussion - Caching layers, read replicas, multi-region deployment, tenant isolation at scale
Clearer communication - More structured and concise verbal explanations without needing multiple attempts
Proactive trade-off analysis - Discussing alternatives considered and why they were rejected, not just the chosen approach
Failure scenarios - What happens when Kafka goes down? What if the time series DB is unavailable? How do you handle partial failures in the notification pipeline?
Verdict Scale	Your Position
Strong No Hire
No Hire
Borderline Lean No Hire
→ Borderline Lean Hire	You are here
Hire
Strong Hire
Keep practicing - you have a solid foundation to build on! 💪