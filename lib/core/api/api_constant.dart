// const String baseUrl = 'http://localhost:8000/admin/api/v1';
//const String baseUrl = 'http://192.168.0.115:8000/admin/api/v1';
const String simpleBaseUrl = 'https://lelamonline.com';
  const String baseUrl = 'https://lelamonline.com/admin/api/v1';
const String token = '5cb2c9b569416b5db1604e0e12478ded';

//====================== Authentication ==============================//
const String login = '$baseUrl/login?token=$token';
const String register = '$baseUrl/register?token=$token';

//====================== Categories & Products =======================//
const String categories = '$baseUrl/list-category.php?token=$token';
const String products = '$baseUrl/products?token=$token';
const String banner = '$baseUrl/banner.php?token=$token';
const String usedCarsProducts =
    '$baseUrl/list-category-post-marketplace.php?token=$token&category_id=1&user_zone_id=0';
const String locations = '$baseUrl/list-location.php?token=$token';

//====================== Post details =======================//
const String attributeValue =
    '$baseUrl//post-attribute-values.php?token=$token';
const String addPostReview = '$baseUrl/add-post-review.php';

//====================== Feature Posts ===============================//
const String brand = '$baseUrl/list-brand.php?token=$token';
const String brandModel = '$baseUrl/list-model.php?token=$token&brand_id=5';
const String modelVariations =
    '$baseUrl/list-model-variations.php?token=$token&brands_model_id=3';
const String attribute =
    '$baseUrl/filter-attribute.php?token=$token&category_id=0';
const String attributeVariations =
    '$baseUrl/filter-attribute-variations.php?token=$token';

//others
const String getImageFromServer = '$baseUrl/get-image.php?file=';
const String getImagePostImageUrl = '$simpleBaseUrl/admin/';
const String faqUrl = '$baseUrl/list-faq.php';
const String searchAnyProduct = '$baseUrl/search-post.php';
const String notifications = '$baseUrl/fetch-notifications.php';
const String allusers = '$baseUrl/index.php';
const String userDetails = '$baseUrl/user-details.php';
const String otpSendUrl = '$baseUrl/otp-send.php';
const String userRegister = '$baseUrl/register.php';
const String userProfileUpdate = '$baseUrl/user-profile-update.php';
const String shortlist = '$baseUrl/list-shortlist.php';

//======================================MyBids=======================================================//

const String myBidLow = '$baseUrl/my-bids-low.php';
const String myBidHigh = '$baseUrl//my-bids-high.php';
const String myBids = '$baseUrl/my-bids.php';
const String currentHighestBid = '$baseUrl/current-higest-bid-for-post.php';
const String increaseBid = '$baseUrl/increase-bid.php';
const String proceedmeetingwithoutBid =
    '$baseUrl/procced-meeting-without-bid.php';
const String proceedmeetingwithBid = '$baseUrl/procced-meeting-with-bid.php';

//=======================================Meeting======================================================//
const String mymeetings = '$baseUrl/my-meetings.php';
const String meetingTimes = '$baseUrl/meeting-times.php';

//my meeting common endpoints
const String meetingEditDate = '$baseUrl/my-meeting-edit-date.php';
const String meetingEditTime = '$baseUrl/my-meeting-fix-time.php';
const String proceedWithBid = '$baseUrl/my-meeting-proceed-with-bid.php';

//Date fix
const String dateFix = '$baseUrl/my-meeting-date-fix.php';

//Meeting Request
const String myMeetingRequest = '$baseUrl/my-meeting-request.php';
const String myMeetingRequestStatus =
    '$baseUrl/my-meeting-request-post-status.php';
const String sendLocation = '$baseUrl/my-meeting-send-location-request.php';

//my meeting await location
const String myMeetingAwaitLocation =
    '$baseUrl/my-meeting-awaiting-location.php';
const String myMeetingAwaitRequestStatus =
    '$baseUrl/my-meeting-awaitinglocation-post-status.php';

//Ready for meeting
const String readyForMeeting = '$baseUrl/my-meeting-ready-for-meeting.php';
const String readyForMeetingStatus =
    '$baseUrl/my-meeting-readyformeeting-post-status.php';

//meeting done
const String meetingDone = '$baseUrl/my-meeting-done.php';
const String meetingDoneStatus = '$baseUrl/my-meeting-done-post-status.php';
const String meetingDoneOfferPrice = '$baseUrl/my-meetings-offer-price.php';
const String meetingDoneNotInterested =
    '$baseUrl/my-meetings-not-intersted.php';
const String meetingDoneRevisit = '$baseUrl/my-meetings-revisit.php';
const String meetingDoneRevisitDecisionPending =
    '$baseUrl/my-meetings-decision-pendding.php';

//================================================Expired=====================================//

const String expired = '$baseUrl/my-meeting-expired.php';

//================================================Sell=====================================//

const String sellPostLowBid = '$baseUrl/sell-post-low-bid.php';
const String sellPostHighBid = '$baseUrl/sell-post-high-bid.php';

const String sellDateFixedList = '$baseUrl/sell-meeting-date-fixed.php';
const String upcommingMeetingList = '$baseUrl/sell-upcoming-meetings.php';
const String locationRequestList = '$baseUrl/sell-location-request';
const String shareLocation = '$baseUrl/sell-share-location.php';
const String meetingReschedule = '$baseUrl/sell-meeting-reschedule.php';
const String waitingForMeetingList = '$baseUrl/sell-waiting-for-meeting.php';
const String sellmeetingDone = '$baseUrl/sell-meeting-done.php';
const String skipmeeting = '$baseUrl/sell-skip-meeting.php';
const String meetingDoneList = '$baseUrl/sell-meeting-done-list.php';

const String rescheduleRequestList =
    '$baseUrl/sell-junk-reschedule-request.php';
const String skipped = '$baseUrl/sell-junk-skipped.php';
const String attemptsOver = '$baseUrl/sell-junk-attemps-over.php';
const String inActive = '$baseUrl/sell-junk-inactive.php';
const String canceled = '$baseUrl/sell-junk-canceled.php';
const String soldout = '$baseUrl/sell-junk-sold-out.php';



