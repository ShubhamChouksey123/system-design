Welcome to your system design interview! Here's your design challenge:

Design a hotel booking system like Booking.com that can handle inventory management, real-time availability, pricing, and concurrent bookings across thousands of properties.

Use the drawing canvas to the left to create diagrams, system architectures, and visual representations of your solutions. The problem statement has been added to the canvas to get you started.

Think out loud as you work through the problem, and don't hesitate to ask clarifying questions. This interview focuses on your ability to design scalable systems, communicate ideas visually, and think through real-world constraints and trade-offs. I'll guide you through the process and provide feedback at the end.

#
Can you share the question again?
Design a hotel booking system like Booking.com that can handle inventory management, real-time availability, pricing, and concurrent bookings across thousands of properties.

#
hello
Let's get started! Before diving into the design, what are the key functional requirements you'd want to focus on for this hotel booking system?

#
before that I would like to read the question to make sure that I understand it correctly so the problem states are design a hotel booking system designer hotel booking system like booking.com that can help inventory management real time availability pricing and concurrent book in across 1000 of properties okay
Great, take your time understanding the problem. Once you're ready, what are the key functional requirements you'd identify for this system?

#
so  so before that I would like to list all the things that we are going to discuss in this interview so it include functional requirements  non functional requirement  and then estimations  and then architecture  and then walk through  and
Sounds like you have a structured approach in mind. Let's start with the first item on your list — what functional requirements would you identify for this hotel booking system?

#
then hello  so will cover function non function requirement estimation architecture walk through API and DB schema trade of login monitoring and alerts
I can see you've outlined that structure on the canvas as well. Let's dive right in — what are the key functional requirements you'd identify for this hotel booking system?

#
okay so I will start with function requirements  so  user should be  able to  browse  browse hotels  and homes  and different  room types in a hotel  and then user should be  should get the availability  of room in a hotel  and then user should be able to reserve  reserve a room  or room
I can see you've started listing those on the canvas. Those are good starting points. Are there any other functional requirements you'd consider important for a system like Booking.com, or are these the core ones you'd want to scope this design around?

#
I want to ask clarifying questions so
Go ahead, what clarifying questions do you have?

#
so during so the user should be able to reserve a book a room with a front payment or we can we will allow payment at the  payment during the second  check in
That's a good clarifying question. For this design, let's assume payment is collected at the time of booking to confirm the reservation. What other clarifying questions do you have?

#
okay so only bookings that have that I have paid will be considered as reservations
Yes, that's correct — a booking is only confirmed once payment is completed. Any other clarifying questions before we finalize the functional requirements?

#
also  requirement that you hello any other function requirement that you considered as important
What about the hotel/property side of things — how do properties and their inventory get into the system?

#
okay so you want  adventure should be able to  do add  update  delete  hotel  or room
I can see you've added that to your canvas. Now, what about the non-functional requirements — what would be most critical for a system like this?

#
so I would like to list the function requirements of the function require users should be able to browse search hotels and different room types in a hotel you just should be able to get a availability of a room user should be able to reserve our room or rooms for a Desire date and uses should be able to cancel a booking and admin users should be able to add update delete a hotel or room and a hotel
Those are solid functional requirements. Now let's move to non-functional requirements — I can see you've started with "Reliable" on the canvas. What non-functional requirements do you think are most critical for this type of system?

#
okay so non function requirements are we should be able to handle concurrent bookings reliable so there should be no data loss of for any reservation that system should be highly available and reach should be fast
Those are relevant non-functional requirements. Before we move on, can you give me a sense of the scale we're designing for — how many users, properties, and bookings per day would you estimate?

#
yes  total hotels 1 million hotels  or
Go ahead, continue with your estimations.

#
hello so I have done some estimation so we can assume that we have total hotels 100K  and average room in per Hotel is 50 and average reservation period per user is 3 days and average acquency of a hotel Occupancy of a hotel is 70% so right throughput is 100K * 50 * 07 / 3 into 24 into 16 to 60 that is around 10 bookings per second so this is the right throughput  which is equals to 10 booking per second and read throughput is let us read to write ratios hundred  request per second  read throughput is 1000 request per second
Good, I can see those estimations on your canvas. The write throughput seems manageable at 10 bookings/second. Now that we have requirements and scale defined, let's start with the high-level design — can you sketch out the overall system architecture on the canvas?

#
one more clarifying question that I want to ask is the question states that it can handle inventory management real time availability and pricing so does that mean that the pricing will be dynamic or is it going to be a constant
Good question. Let's assume pricing can be dynamic — it may vary based on factors like demand, season, or property owner decisions. Go ahead and factor that into your high-level design. Can you start sketching the architecture on the canvas?

#
also one more question we will be also supporting payments correct
Yes, assume the system needs to handle payments as part of the booking flow. Now let's move to the high-level design — can you start sketching out the major components and how they connect on the canvas?

#
yeah so I will update these
I can see you've started adding components to the canvas — I see a User, Admin, API Gateway, Hotel Service, Booking Service, and Rate Service. Can you draw the connections between these components to show how data flows through the system?

#
so I have updated the function requirements now we I have added dynamic pricing as well as payment using external payment provider like stripe
Got it. Now let's focus on the architecture — I can see you've placed some components on the canvas like the API Gateway, Hotel Service, Booking Service, and Rate Service. Can you connect these components and show how a request flows from the user through the system?

#
hello  hello
Let's move forward with the design. I can see you have several components on the canvas — User, Admin, API Gateways, Search Service, Booking Service, Rate Service, and Payment Service. Can you walk me through how these components connect and how a typical user flow works?

#
kya so I will tell you the first brows slow  so there's a guest user or user that actually is looking for a booking so that request Goes by user API Gateway so where it does authentication authorisation plus rate limit check and then the request is served by service service the data from the AWS elastic search and so this is built over a CDC pipeline over the hotels so we have a hotels DB writer instance and their division connector that is reading over the TV right hand locks and those division lock and then upload workers actually search  so this was the search flow now that the user has got some 20 different hotels now he Bros and select any one of the hotel read service  and Hotel read service
I can see this flow on your canvas — the search goes through the API Gateway to the Search Service backed by Elasticsearch, with a CDC pipeline using Debezium to sync data from the Hotel DB. And then for viewing a specific hotel, it goes to the Hotel Read Service.

Walk me through what happens when a user decides to book a room — how does the booking flow work between the Booking Service, Inventory, and Payment Service?

#
yeah so now that Hotel user is satisfied with the hotel then he actually go with the payment flow  or like the booking flow so the booking so the request reaches via user API Gateway and then the booking booking service the request reaches the booking service booking service does an inventory check so there is an inventory db so it checks whether the we have the required capacity for those and so the inventory DB  so that  so it creates so the booking service actually provides reservation ID to the user and so user gets reservation ID and user again click on click on the payment button and the request is routed to the payment service so the payment service actually what it does it the payment detail  and  so the payment is done by using path so the payment service actually calls the external API providers for example Strike  and Strike  or PayPal  and so it also inform stuff external payment so the payment service payment pending payment status and once the external payment provider confirm the payment status then we mark the payment status has done and we add the booking as confirm
I can see this flow on your canvas with the connections between Booking Service, Inventory DB, Payment Service, and the External Payment Provider. I notice you have a note about the Payment Service having an async job that fetches pending status at scheduled intervals.

What happens if the payment fails or times out — how does the system handle releasing that inventory back?

#
that's why the payment service we have an asynchronous job that actually such as the pending payment status  and updates the DB and it also informs the booking service so booking service actually updates the TV with the correct payment status
So the async job handles stale pending payments. But let's think about the time between when inventory is reserved and payment is confirmed — how are you preventing another user from booking the same room during that window?

#
so abhi we actually want to handle concurrent request on the same room room type actually so for example there a single room that is left and there are multiple concurrent user trying to book that same room so what happened so in this case what we can do is the we can do use optimistic login  so what we can do is like if the number of the total number of rooms available rooms should be less than or equals to the total Inventory of the those rooms in a hotel so if it is greater than reject that request  so we can add this DB constraint  and also yeah so we can use optimistic login as well as we can use DB DB constraints also we can use versions versions value so we will have like to check on the DB side also we have a check and then also on the service layer application check
You mentioned both optimistic locking and DB constraints. Let's dive deeper into one aspect — when you say you'd use a version value for optimistic locking, can you walk me through exactly what happens at the database level when two users try to book the last available room simultaneously?

#
yes um that the version value so I will let some details so if we check the room inventory table  room type inventory so it has two columns  total rooms  and other is Reserve rooms  so how many rooms are result and then also we have a version colum  so if two concurrent using that for example the total rooms are 20 and the reserved room are 90 and the version values for 100 so there's only one room left and there are two concurrent users that are trying to book the same room so both have read the version values 100 the first request goes and updates the version value as 101 and the DB commit the request and then the other user also try to update that request to reserve room equals to 20 and version is equals to 101 since the version is already 101 so it has to be greater than the previous value  so this request will be rejected  and this is how the second user will get a room not available exception
That's a clear explanation of optimistic locking with versioning. Now let's look at another part of your design — I can see you have a separate Admin flow with a Hotel Writer Service, and a media pipeline with S3, transcoding, and CDN. Can you walk me through the admin flow for adding a new hotel with images?

#
yeah I would love to explain that flow so there's an Admin user so admin can actually list has Hotel as well as room types in a hotel for example hotel has three kind of room A category b category and C category rooms so and each have different capacity like a has hundred rooms and be category has 50 room so the admin user actually locks in and the request goes via admin API and so he right the new hotel name and hotel address all these details in and that goes into writer instance of the hotel DB  and also he uploads the some images of rooms so the hotel hotel writer service actually provides a pre sign S3 url to the to the admin and so instead of so the admin so the admin will be directly uploading it to AWS S3 using the pre sign  and so after the image of the media is uploaded successfully reads tho successful events and so there is a transport pipeline so that the first step is like to break that media and to smaller chance of group of pictures and then there are transport manager so they actually control the Heartbeat of those transport workers and also it has a list of transport workers as well ask of all those transport workers and so also it has dead letter Q in case like we are not able to  process that media so the transport workers actually convert of media into different resolutions and formats so multiple so that for different devices we have multiple rentritions and so we can have better streaming on all type of adaptive so we will support adaptive vibrate streaming of those media and after the media has been successfully uploaded the transport pipeline is successful for a particular media the transport worker also informs the hotel writer service that this media has been successfully uploaded and these are the S3 URL for different retreats
That's a thorough explanation of the media pipeline. I can see all of this well laid out on your canvas.

Now let's shift to scaling and trade-offs. Looking at your architecture, what do you see as the primary bottleneck in this system under high load?

#
so if we look at the estimations so we can see the read throughput is 100000 request per second  so I think DB would be the first bottle like  and specially  especially the hotel db so people will be searching and  meets setting information of the hotels and rooms  so what we can do is like we can increase the number of reader instances and also we can we already have a hotel cash so we can also increase the we can also start those DB
You mentioned adding reader replicas and caching for the Hotel DB. I can see you already have a Hotel Cache and separate reader/writer instances on your canvas. What consistency trade-offs are you making with this caching layer — for example, what happens when an admin updates room availability but the cache still has stale data?

#
so it that case so we will have to purchase  purse that  purge p u r g  punch that cash so we will invalid that Hotel data in case the admin actually updates that  and we can use for cash weekend use case a side policy  side and we can use TTL based  expiry  and we can purse any data that has been modified by the admin
So you're using a cache-aside pattern with TTL and explicit invalidation on admin updates. That makes sense.

Looking at your Inventory DB — you have a writer instance and reader instance with replication. For the booking flow where you're doing optimistic locking, what happens if there's replication lag and a user reads stale inventory data from the reader instance?

#
yes yes so a people will actually be reading incorrect data  that is present in the cash so that's why in case there's a new booking for that hotel room type so we will invalid that cash in the inventory cash  and we will use similar cache side is with TTL based expiry and we will invalid I will do cash when the room type there is a new booking for that particular room type
That addresses the cache, but I'm asking specifically about the database replication lag — when the Booking Service needs to check available inventory before making a reservation, should it read from the reader instance or the writer instance, given that you're using optimistic locking?

#
so in case of a booking so always for rights for a right request we will be reading from the we will be updating in the writer instance  and during booking also we will read from the writer instance not from the cash
Exactly — reading from the writer instance for booking operations ensures you're working with the most current data, which is critical for your optimistic locking to work correctly. That's an important consistency decision.

Now, looking at your overall architecture, what would you consider the key trade-offs you've made in this design, and is there anything you'd change if you had more time?

#
the miss mean trade of that is so in case of optimistic locking so people some in case of concurrent request people will get room already booked exception so I think we will be able we should we should be able to take that risk and so people will so during P covers when people are booking for the same room so they will get too many exceptions  so there are other ways also like we can use Pessimistic locking but that actually increase DB load so we will follow this optimistic locking because it reduce comparatively the DB has less load and also it is fast  so this is one of the trade of you what type of locking that we want to follow and
That's a good trade-off analysis between optimistic and pessimistic locking. You've weighed the user experience impact against database performance.

What about the trade-off between availability and consistency in your overall system — where have you prioritized one over the other?

#
yeah for for reads so we are giving priority on availability over consistency so that's why we are reading from the cash so which can have a slide still data but we are ok we are following we are preparing availability over consistency for reads so and for rights we will be always writing and reading from the writer instance of the DB  so on rights we are we prefer and consistency over availability because we don't want double booking otherwise or double charge that's why we are we are preparing consistency over availability in case of rights or bookings or reservation
That's a well-articulated distinction — eventual consistency for reads where stale data is acceptable, and strong consistency for writes where correctness is critical. This aligns well with the CAP theorem trade-offs for a booking system.

Looking at your diagram, I notice you have logging, monitoring, and alerts listed in your outline. What observability concerns would you prioritize for this system?

#
yes  so before  so I think we have discussed about I have provided you the architecture and we have gone through the Walkthrough so I'll we have discussed the trade of also so I would like to touch about login monitoring and alerts so we have and transport pipeline so we can have we have use cough there and also we have in the CDC pipeline also so what we can do is we can have set up alert over that is the bites in and bites out and we can have alerts over consumer lag  and cute app also and what all alerts that we can we will also monitor cash hit ratio as well as much ratio as well as for all the services we will report as well as latency and we will set up alerts over all these property for example it is greater than 1% then people should be paid and so similarly for 10 Lite and see also  and so what on all the services we will also be monitoring the means service health status like percentage CPU utilisation percentage memory utilisation as well as what is the gvm status a garbage collection and all these and for payment also we will we will monitor the payment field payment ratio versus the passing payment the ratio of field versus completed payments
That's a comprehensive observability strategy covering infrastructure metrics, application-level metrics, and business metrics like payment failure ratios. The consumer lag monitoring on your CDC and transcoding pipelines is particularly important for catching data sync issues early.

We're wrapping up the interview. You've covered a lot of ground — from requirements and estimations through a detailed architecture with search, booking, payment, media processing, and CDC pipelines, along with thoughtful trade-offs around locking strategies and consistency models.

Is there anything else you'd like to add or any aspect of the design you feel we haven't covered?

#
one more thing that I would that we haven touch is API design and DB schema  should we do that
Sure, go ahead — what are the key APIs and DB schemas you'd define for this system?

#
so before I will go with DB schema  so we have a hotel stable  Hotel table and so we have a hotel ID  address with itself is a complex object and name  okay so hotel has a room type
I can see you've started listing the Hotel table on the canvas. Go ahead and continue with the Room Type table and how it relates to the Hotel table, as well as the other key tables in your schema.

#
hello  I have written some of the epi and DB schema so in DB scheme of your hotel hotel table room type table room type inventory reservation user as well as admin table so in hotel we have ID name address and room type so a hotel can have different type of rooms for example deluxe room Platinum or Diamond type of rooms so each room type house ID Hotel ID based price list of features like Wi-Fi AC etc and then room type inventory is that ID Hotel ID room type ID totally and reserve count and date so room type and particular Hotel can have Platinum type of room and so it can have an Inventory of 20 and 18 are reserved for a particular date example are 20th September  and then there is a reservation so each reservation ID user id and start date and date and number of rooms  number of rooms versus and Hotel ID and room ID  and user table user ID email and name and then there is admintable admin ID name email
I can see all of that on your canvas. One question about your schema — in the reservation table, you have number_of_rooms as a field. How would you handle the case where a user wants to book multiple different room types in a single reservation?

#
I think that we have to make different entries  in the reservation table and this will also provide a facility to user to to cancel some part of the reservation like for example he has made a reservation of 3 type of rooms in a single payment so he can cancel one type of room for example at deluxe room and he can keep to other type of rooms for still have the booking for two type of rooms
That makes sense — separate reservation entries per room type gives you flexibility for partial cancellations. I can see you've also outlined the API design on the canvas with admin APIs for hotel and room CRUD operations, and user-facing APIs for search, hotel details, availability, and booking.

We've covered a comprehensive design today. You've addressed requirements, estimations, architecture with multiple services, DB schema, APIs, concurrency handling with optimistic locking, consistency trade-offs, media processing, CDC pipelines, and observability. This has been a thorough walkthrough. Great job!

#
so before we and the interview can you read my interview on this following criteria is requirement design problem solving scale and trade of communication and overall on a rate of 0 to 10
Here's my evaluation of your interview performance:

Requirements (8/10) You identified comprehensive functional and non-functional requirements, asked good clarifying questions about payment timing and dynamic pricing, and scoped the problem well with reasonable estimations. You could have explored edge cases like overbooking policies or multi-currency support.

Design (8/10) Strong architecture with well-separated services — Search, Booking, Payment, Hotel Read/Write, and Rate Service. The CDC pipeline with Debezium for search indexing, the media transcoding pipeline, and the caching layers showed depth. The separation of reader/writer DB instances was well thought out.

Problem Solving (7/10) Good explanation of optimistic locking with versioning for concurrent bookings. The async job for handling pending payments was practical. However, you could have explored more around what happens during partial failures — for example, if inventory is reserved but payment service is down.

Scale & Trade-offs (8/10) Excellent articulation of consistency vs availability trade-offs for reads vs writes. Good understanding of caching strategies with cache-aside and TTL. The locking trade-off analysis was solid. Could have discussed sharding strategies for the inventory DB at higher scale.

Communication (7/10) You followed a structured approach and your diagram was detailed and comprehensive. At times, explanations could have been more concise and focused. The visual work was strong and well-organized.

Overall: 7.5/10

Strong performance with good architectural thinking, solid trade-off analysis, and a well-structured approach.

#
can you also provide me a verdict of the today's interview like borderline lean higher strong higher
Based on your overall performance, I'd give you a Lean Hire.

Rationale: You demonstrated solid system design fundamentals — well-structured approach, comprehensive architecture with meaningful component separation, strong understanding of consistency trade-offs, and practical concurrency handling. Your diagram was detailed and showed real-world awareness with features like CDC pipelines, media transcoding, and observability.

What kept it from Strong Hire:

Some areas lacked depth on failure scenarios and edge cases
Explanations were occasionally verbose and could have been more crisp
Could have probed deeper into sharding, rate limiting strategies, and system resilience under partial failures
The payment-to-booking coordination could have been explored more rigorously
What would push you to Strong Hire:

Deeper exploration of failure modes and recovery mechanisms
More discussion around data partitioning and horizontal scaling strategies
Tighter, more structured verbal communication
Proactively identifying and addressing system weaknesses before being asked
Overall, a solid interview showing good design instincts and practical knowledge. With more depth on edge cases and resilience, this would move into strong hire territory.

#
or no higher can you also like point me what all the things that I am doing good or great and should keep doing that that you like today
Here are the things you did well that you should keep doing:

Structured Approach ✅ You laid out your interview roadmap upfront — requirements, estimations, architecture, walkthrough, APIs, DB schema, trade-offs, and observability. This showed organization and made the interview easy to follow. Keep doing this.

Clarifying Questions ✅ You asked about payment timing, dynamic pricing, and scope before jumping into design. This shows maturity and real-world awareness. Always do this.

Back-of-the-Envelope Estimations ✅ Your math was clean — deriving 10 writes/sec and 1000 reads/sec from hotel count, room count, occupancy, and reservation duration. This grounded your design decisions in real numbers.

Read vs Write Path Separation ✅ You consistently distinguished between read and write paths — separate DB instances, different consistency guarantees, and appropriate caching strategies for each. This is a strong design instinct.

Concurrency Handling ✅ Your optimistic locking explanation with version columns was clear and practical. You walked through the exact scenario of two users competing for the last room step by step.

CDC Pipeline for Search ✅ Using Debezium to sync Hotel DB changes to Elasticsearch via CDC was a sophisticated and production-ready approach rather than naive dual writes.

Media Pipeline ✅ The pre-signed URL upload, transcoding pipeline with workers and manager, adaptive bitrate streaming, and dead letter queues showed real-world production experience.

**

#
yeah I also feel that I also so spend time on concurrency and double booking  sometimes it is hard for me like  it is hard to explain concepts and also it's not that I don't know them it's just that  I have too many information to provide to the interview
That's a great self-awareness point. Here's my advice on that:

Your Knowledge is Strong — the depth you showed on CDC, optimistic locking, media pipelines, and caching proves you know the material well. That's not the issue.

The Challenge is Prioritization — when you have too much to say, the key is to lead with the core idea first in 1-2 sentences, then add layers of detail only if asked. Think of it as a pyramid structure:

State the approach — "I'd use optimistic locking with versioning"
Explain the why — "Because it reduces DB load compared to pessimistic locking"
Walk through the how — Only go into the step-by-step scenario if the interviewer asks for it
Practice Tip: Before explaining any concept, pause for one second and ask yourself — "What is the one sentence summary of what I'm about to say?" Lead with that sentence, then expand.

This single habit will make your communication significantly crisper and will likely push you into Strong Hire territory because your design thinking is already there. The packaging just needs tightening.

#
I would try that approach