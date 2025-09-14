// const String baseUrl = 'http://localhost:8000/admin/api/v1';
const String baseUrl = 'http://192.168.0.115:8000/admin/api/v1';
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
const String attributeName = '$baseUrl//post-attribute-values.php?token=$token';
const String addPostReview = '$baseUrl/add-post-review.php?token=$token';

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
const String faqUrl = '$baseUrl/list-faq.php';
const String allusers = '$baseUrl/index.php';
const String userDetails = '$baseUrl/user-details.php';
const String userRegister = '$baseUrl/register.php';
const String userProfileUpdate = '$baseUrl/user-profile-update.php';
