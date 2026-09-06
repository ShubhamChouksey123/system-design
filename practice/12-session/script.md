Welcome to your system design interview! Here's your design challenge:

Design a video streaming platform like YouTube that can handle millions of video uploads, provide fast video processing, and serve content globally with minimal latency.

Use the drawing canvas to the left to create diagrams, system architectures, and visual representations of your solutions. The problem statement has been added to the canvas to get you started.

Think out loud as you work through the problem, and don't hesitate to ask clarifying questions. This interview focuses on your ability to design scalable systems, communicate ideas visually, and think through real-world constraints and trade-offs. I'll guide you through the process and provide feedback at the end.

#
Can you share the question again?
Design a video streaming platform like YouTube that can handle millions of video uploads, provide fast video processing, and serve content globally with minimal latency.

#
hello  hello can you hear me
Yes, I can hear you! Let's get started. Before diving into the design, what do you think are the most important functional requirements for this video streaming platform?

#
yeah so before that I'll read read the question and make sure to make sure that I understand it correctly so the problem is design a video streaming platform design a video streaming platform like YouTube that can handle millions of video uploads provide fast video processing and serve content globally with minimum latency
That's right, you've got the problem statement down. So with that understanding, what are the key functional requirements you'd want to focus on for this platform?

#
hello  I have written the functional and non-functional requirements  so functional requirement include user should be able to upload a video after the upload the video should be processed with in minimum minimum time for a view and any user around the globe should be able to stream the video  and video should be available in different resolutions and formats  to support different devices and bandwidth  non-functional requirement include  a smooth video streaming with minimum latency  High availability  video processing should be fault tolerant and resilient  secure video upload
I can see your requirements on the diagram - they look well thought out. One clarifying question before we move on: what scale are you designing for in terms of number of users and daily video uploads?

#
so I do some estimations  and come up with some numbers
Go ahead, what numbers are you thinking?

#
hello I made the calculations so we can assume like we have total users of 10 million  and daily active users are like 50% of that that is 5 billion people uploading video parties at 10% of the total users that is 1 billion and number of videos uploaded per person per day is one  and the size of video uploaded  average sizes 200 MB so total size uploaded parties
I can see your estimations on the diagram. You've calculated storage needs of about 0.6 PB per day with replication, and bandwidth requirements around 1 Tbps. Those are substantial numbers that will definitely influence your design decisions.

Now let's start with the high-level design — can you sketch out the major components of this system and how they connect on the canvas?

#
do you think these numbers are correct
Your approach is solid — you've systematically worked through users, uploads, storage, and bandwidth. One thing I'd note is you mentioned 10% of total users uploading, which gives 1 million, not 1 billion — but I see the correct number (1,000,000) in your written calculations on the canvas.

Let's move forward — can you sketch out the high-level architecture showing the major components this system would need?

#
yeah I'm sorry I said it 1 million but it is a 1 million sorry  so yeah
No worries! Your written calculations are clear. Let's move on — can you start sketching the high-level architecture on the canvas, showing the major components and how they connect?

#
so based on that we can like we can say that we require a large amount of storage that is like a 0.6 megabytes per day  and also we require like 1 tbps bandwidth so that is also too large so  we we have to like use cdns for that
Those are important observations about the scale. Now can you show me this visually — sketch out the major components of the system on the canvas, including where CDNs and storage would fit in the overall architecture?

#
yeah I'll draw the major components and
Go ahead, take your time and sketch it out on the canvas. I'll review it once you're done.

#
hello I have drawn the diagram
I can see your diagram — it's quite detailed! You've got the client connecting through an API Gateway (with AuthN, AuthZ, and rate limiting), and I can see several key flows:

Video Upload flow — using signed URLs to upload directly to S3
Video Metadata — with a separate metadata service, writer/reader DB instances, and a cache layer
Video Processing Pipeline — with an event queue (Kafka), pre-checks, DAG system, transcode manager/workers, and an upload service writing back to S3
Video Streaming — with CDN serving popular videos and a streaming service for non-popular ones
That's a solid high-level design. Let's dive deeper — can you walk me through what happens step by step when a user uploads a video, starting from the client all the way through to the video being ready for viewing?

#
so I'll give you a walk through of like for like what happens when a user uploads a video  so  when a user uploads a video so he heard the post upload endpoint and that is like like that goes by EPA Gateway that checks authentication authorization and rate limiting and then goes to video upload service video upload service like  all right said the method of the video like informs the metadata service and which I write like like pending upload entry in the database and then we return the signed URL for that video  so we return we have a signed URL like that is limited for like valid for a limited period of time and so the client use that signed URL and uploads that video directly into AWS S3  after the video has been successfully uploaded to S3 the transport pipeline actually works  and  so I can give you a transport pipeline also work too  walk through
That's a clear walkthrough of the upload flow. I like the signed URL approach for direct-to-S3 uploads. Go ahead, walk me through the transcoding pipeline — what happens after S3 receives the video?

#
yeah so after  the video has been uploaded in AWS history we get these upload events from the S3 and so there is a worker that actually reads those events and and like are these events are present in a Kafka and the free checks and listen to those Cafe events and it does check that the video is not tempered and it breaks the video like into smaller chunks of a group of pictures that is gops  so now we have a like instead of a big video we have a smaller chance of videos  and these chunks are then each elect there's a pipeline like like a queue for like a queue we can use a cough you here so so these smaller chunks of videos are process like a sentence system actually reads those each events and the deck system create a workflow for that this type of video  like God for each type of videos we can have like different type of workflows like depending up on short content like shorts or like long video so yeah and then each type of like based on each workflow we can we have different transcode workflows and then the transport manager keep track of the task  and then it also keep track of workers available and then it I said sign it assigned task to those workers  so these task include like encoding  like which is transcoding like converting video into different formats  and for different resolutions so for example like 480p 720p and one 108  1080p  and then also it for different formats for example MP4 or a movie so and then it also like perform tasks like tumbling generation thumbnail  Hampton Inn thumbnail generation for the video and after that it actually merge all those small chunks into like videos and then send to the upload service so upload service rights the final upload into AWS S3 again  and after the video has been uploaded upload service actually hits the video metadata service that that the video has been successfully updated and is ready for a stream
That's a thorough walkthrough of the transcoding pipeline. You've covered chunking, parallel processing with the DAG system, and the different transcoding tasks well.

Let's dive deeper into one connection — how does the Transcode Manager communicate with the Transcode Workers? What happens if a worker fails mid-task?

#
so transport manager like has a list of Q which contain like it uses priority queue to maintain that list of tasks and then it has it has a list of workers also  and  it actually  it assigns tasks like parallel we can use a cue here also so a transport worker like can push those events  and in case so the transport manager actually does this task also so in case a task is filled and so it  it doesn't retry  and yeah it assigns to a new worker and like that means to redo the task
So you mentioned retries on failure — how does the Transcode Manager know that a worker has failed? What mechanism would you use to detect that?

#
so transport manager has a list of tasks and workers  so it can actually periodically ask the transport worker about the like progress of the task  and in case of the transport worker is unable to provide the progress data or like the progress report or like the transport managers unable to bring that  being that machine then we can say that the  the transport worker is dead and the transport manager can like reassign the task into some to some other healthy worker
So a polling/heartbeat mechanism — that makes sense. Now let's shift to the viewing side. Can you walk me through what happens when a user wants to stream a video?

#
yeah so I'll give you a walk through of like a Stream flow  so I told you like we have different resolutions and we have also a different different type of formats so we can have like people can be watching these video in different devices mobile devices  then there are smart TVs and then desktop also so so depending on that  we  so the request for the get actually is  is intercepted by the EPA Gateway and goes to the video service video service Returns the mean first of the  mainfest of the like video  so now the client actually knows what are the formats and what are the means video formats and what are the resolutions are available for him  so based on so the client decide based on his bandwidth  and and the available resolutions he can use from the bean first list  so in case the client has high bandwidth like good internet connection that he can he can like you use good quality resolution and in case the connection goes down or like then he then the client streams for a low resolution video  and so in this way we provide seamless experience to users without actually pause or like buffering
That's a good description of adaptive bitrate streaming. Now looking at your diagram, I can see you have CDN serving popular videos and a separate path for non-popular videos. How does the system decide which videos are "popular" and should be cached in the CDN versus served directly from S3?

#
yeah that is called adapted by period  adaptive  buy parade streaming  buy parade  Buy trade I'm Sorry by trade  adaptive by trade streaming
No worries — adaptive bitrate streaming, yes! So back to my question — how does your system determine which videos are popular and should be served from CDN versus which ones go through the direct S3 path?

#
yeah also  yeah actually we don't want to like we don't want the CDN size to grow big and because CDs are also costly and so we instead of like having all the videos we we just want only the popular videos  to be served from a different service that is video stream service that post that data from S3 and returns to the user  and also how do we know maybe we can like know about the car we can keep track of current views of a video and in case the video number of views of that video goes more than a threshold then we can like serve that video from a CDN otherwise we can sell from video stream service only
Interesting approach. How would this system handle scale? Let's move into discussing bottlenecks and scaling strategies. Looking at your current architecture, what do you think would be the first bottleneck to hit as traffic grows?

#
I think like the video metadata service  can be a bottleneck but we are so for that we have a cash and and we also are reading from a reader instance of our database so yeah we are good there  and so videos are served from CDN so that also will be  I will not be a bottleneck I think the video streaming service but as I said like for non popular videos we can take that like we can serve from video stream service  and yeah so it is kind of a pass through
What about the transcoding pipeline? With 1 million video uploads per day, how would you scale that part of the system to handle the load?

#
parallelism  for that on video  video transport service we will do parallelism  so we will like  try to  do task in parallel  and we can scale these transport workers and transport managers also
How would you decide when to scale up or down the number of transcode workers? What signals would trigger that scaling decision?

#
in case we see that the transport like all the workers are occupied like the percentage of Ideal to occupied workers  like if the ideal number of Ideal workers is very less that means the occupied workers is very large so we can increase the number of workers  I think that would be a metric to decide like
That's a reasonable auto-scaling approach based on worker utilization. Let's talk about another scaling concern — your estimations show 0.6 PB of storage per day. How would you handle storage growth over time, and what trade-offs would you consider to manage costs?

#
so we have like 6 MB storage per day  for this blob storage  so what we can do is like we know that storage is also costly and so we are using AWS S3  so  and AWS S3 has AWS S3 standard and then AWS S3 glacier  so we can fall on not popular videos that are not served that are not watched frequently  or like they they they're like they are not watched now like  so we can like a shift those videos to AWS S3 glacier  that is cheaper as compared to AWS S3 standard  so in this way we can actually optimize on cost of storage
That's a solid cost optimization strategy — tiered storage based on access patterns. One more trade-off question: your system replicates data 3x, which gives you durability but triples your storage costs. How would you think about balancing durability versus cost here?

#
I think if we are using manage service like AWS S3 that actually gives us  that actually gives us inbuilt replication  across regions  so we can choose that  I think  for videos that has  for like videos of some creators that that are popular like whose views are like we have significant views for those creators then we can have like replication three times for creators or like for videos which have less number of views we can have only like 2x replication instead of 3x replication
Interesting approach — differentiating replication based on content popularity. That's a practical cost-optimization trade-off between durability and expense.

Let's talk about global distribution. Your requirements mention serving users around the globe with minimum latency. Can you walk me through how your architecture handles a user in, say, Asia watching a video that was uploaded by a creator in the US?

#
so in that case  we can have like a  so if a video is uploaded in for example AWS has three reason Asia  I'm sorry  for example the video has been uploaded in AWS S3 region us is too and somebody in Asia Pacific wants to watch that video  in such cases like for Global access we can have S3 replication across regions  and we can use the inbuilt feature for that we can just replicate those videos to other regions of S3  in this case like from us is to to Asia Pacific like AP East to something
And how would the CDN fit into this cross-region scenario? Would you still rely on S3 cross-region replication, or would the CDN play a different role here?

#
I think like a videos will be accessed and will be cashed in like a different  Edge notes  like in this case like CDs  so yeah CDs will play more instead of like we will not be have we should not do  storage application instead we should use CDs  so any video that is in popular in two or more regions like the CDN will take care of that and like will cash in those regions
That's a good clarification — leveraging CDN edge caching rather than replicating all storage across regions makes more sense cost-wise.

We're nearing the end of our interview. Let me ask one final question: if you had to pick one area of this design that you're least confident about or would want to revisit, what would it be and why?

#
I think  I would further optimize the transport you
What specifically about the transcoding pipeline would you want to revisit or optimize?

#
so in case like a  weaver like we have exhausted all our interests and like what happens in that case like how do we recover those videos  so I like I like to spend time on there in like fix those pipeline gaps
That's a great self-awareness — handling unrecoverable failures in the transcoding pipeline is a critical reliability concern, especially at the scale you've described.

Interview Summary:

You did a solid job overall. Here are some highlights:

Strengths:

Clear functional and non-functional requirements
Thorough back-of-the-envelope estimations for storage and bandwidth
Well-structured upload flow with signed URLs for direct S3 uploads
Detailed transcoding pipeline with chunking, DAG-based workflows, and parallel processing
Good understanding of adaptive bitrate streaming
Practical cost optimization strategies (S3 Glacier tiering, CDN vs S3 replication)
Comprehensive diagram covering multiple flows
Areas for Improvement:

The failure handling in the transcoding pipeline could be more detailed — dead letter queues, retry policies, and alerting mechanisms
The distinction between CDN and direct serving could be more clearly defined with specific eviction/caching policies
Consider how metadata consistency is maintained when the transcoding pipeline updates video status across distributed components
The monitoring and observability layer is missing — how would you detect issues across this complex pipeline at scale?
Overall, you demonstrated strong system design thinking with good attention to trade-offs and practical considerations. Nice work!

#
can I take some time and like  draw the metadata off of video like schema of video metadata database
Of course, go ahead and sketch out the video metadata schema on the canvas. Take your time!

#
so we can have a video that contains like ID title description of the video then we can have video chunks so for a single video we can have like multiple chunks and each and can have a ID video ID associated with resolution format and like the timestamp from to of that video  so each video can have like different chunks
I can see your schema on the canvas. You've got a video_metadata table with id, title, and description, and a video_chunk table with id, video_id, resolution, and format.

You mentioned timestamps (from/to) for each chunk — that's important for the streaming flow. Would you want to add any other fields that might be useful for the adaptive bitrate streaming or the video processing pipeline, such as status tracking or chunk ordering?

#
yep I think from into  will do that yeah we can have like a
Alright, that works. Thanks for adding the schema — it ties nicely into your overall design showing how the metadata service supports both the upload and streaming flows.

We've covered a lot of ground in this interview. Is there anything else you'd like to add or any questions about the process?

#
so before we end the interview
Go ahead, what would you like to discuss?

#
so before we end the interview I want you to read my  interview based on the following criteria requirement getting design problem solving scale and trade-off communication and overall and also like what will be the verdict of the interview like borderline pass  or higher
Here's my evaluation:

Requirements Gathering (7/10)

You identified clear functional and non-functional requirements
Good back-of-the-envelope estimations with systematic calculations
Could have explored more edge cases like video deletion, search, or recommendations
Design (7.5/10)

Comprehensive architecture covering upload, processing, and streaming flows
Smart use of signed URLs for direct S3 uploads
Well-structured transcoding pipeline with DAG-based workflows
Missing observability/monitoring layer and notification system for upload completion
Problem Solving (7/10)

Good decomposition of the transcoding pipeline into stages
Understood adaptive bitrate streaming well
Worker failure detection via heartbeat was reasonable
Could have gone deeper on failure recovery mechanisms like dead letter queues
Scale & Trade-offs (7/10)

Good cost optimization with S3 Glacier tiering
Smart CDN strategy for popular vs non-popular videos
Differentiated replication based on popularity
Could have discussed database sharding, partitioning strategies, or load balancing in more depth
Communication (7.5/10)

Clear verbal walkthroughs of each flow
Detailed diagram covering multiple components and flows
Schema design was a nice addition
Some explanations were a bit scattered at times
Overall: 7.2/10

Verdict: Pass

You demonstrated solid system design fundamentals with a well-structured architecture. Your strengths are in the video processing pipeline design and practical cost optimization strategies. To move toward

#
am I not a strong higher
Honestly, for a strong hire, I'd expect to see a few more things:

Deeper failure handling — You identified the gap in transcoding failures but didn't propose concrete solutions like dead letter queues, idempotency, or exactly-once processing guarantees

More proactive scalability discussion — I had to prompt you on scaling questions. A strong hire typically anticipates bottlenecks and proposes solutions before being asked

Missing system components — No mention of monitoring/alerting, logging, search/discovery, notification service, or analytics pipeline which are critical at this scale

Database design depth — Sharding strategies, partitioning keys, consistency models, and read/write patterns weren't explored deeply

CDN specifics — Cache eviction policies, cache invalidation strategies, and TTL management weren't discussed

You're solidly in the pass category and close to the border of strong hire. With more depth on failure handling, proactive identification of bottlenecks, and coverage of operational concerns, you'd comfortably be a strong hire.