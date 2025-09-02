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
const String attribute_name =
    '$baseUrl//post-attribute-values.php?token=$token';

//====================== Feature Posts ===============================//
const String brand = '$baseUrl/list-brand.php?token=$token';
const String brandModel = '$baseUrl/list-model.php?token=$token&brand_id=5';
const String modelVariations =
    '$baseUrl/list-model-variations.php?token=$token&brands_model_id=3';
const String attribute =
    '$baseUrl/filter-attribute.php?token=$token&category_id=0';
const String attributeVariations =
    '$baseUrl/filter-attribute-variations.php?token=$token';

//seller information

