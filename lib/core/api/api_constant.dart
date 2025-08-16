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
    

//====================== Feature Posts ===============================//
const String listFeaturePost = '$baseUrl/list-feature-post.php?token=$token';

