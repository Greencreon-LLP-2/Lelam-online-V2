// lib/core/model/core_data_model.dart
class CoreDataModel {
  final String id;
  final String siteUrl;
  final String version;
  final String siteTitle;
  final String siteDescription;
  final String metaKeyword;
  final String metaDetails;
  final String logo;
  final String minLogo;
  final String favIcon;
  final String webLogo;
  final String appLogo;
  final String address;
  final String defaultCountry;
  final String siteEmail;
  final String whatsappNo;
  final String sendgridAPI;
  final bool ifGoogleMap;
  final String googleMapAPI;
  final bool ifFirebase;
  final String firebaseConfig;
  final String firebaseAPI;
  final bool codStatus;
  final bool razorpayStatus;
  final String razoKeyId;
  final String razoKeySecret;
  final bool ccavenueStatus;
  final bool ccavenueTestmode;
  final String ccavenueMerchantId;
  final String ccavenueAccessCode;
  final String ccavenueWorkingKey;
  final bool ifPhonepe;
  final String phonepeMerchantId;
  final String phonepeSaltkey;
  final String phonepeMode;
  final bool ifQrcodePayment;
  final String upid;
  final bool ifOnesignal;
  final String onesignalId;
  final String onesignalKey;
  final String smtpHost;
  final String smtpPort;
  final String smtpUsername;
  final String smtpPassword;
  final bool ifTestotp;
  final bool ifMsg91;
  final String msg91Apikey;
  final bool ifTextlocal;
  final String textlocalApikey;
  final bool ifGreensms;
  final String greensmsAccessToken;
  final String greensmsAccessTokenKey;
  final String smsSenderid;
  final String smsEntityId;
  final String smsDltid;
  final String smsMsg;
  final bool ifAuctionStart;
  final String auctionCategoryId;
  final String updatedOn;

  CoreDataModel({
    required this.id,
    required this.siteUrl,
    required this.version,
    required this.siteTitle,
    required this.siteDescription,
    required this.metaKeyword,
    required this.metaDetails,
    required this.logo,
    required this.minLogo,
    required this.favIcon,
    required this.webLogo,
    required this.appLogo,
    required this.address,
    required this.defaultCountry,
    required this.siteEmail,
    required this.whatsappNo,
    required this.sendgridAPI,
    required this.ifGoogleMap,
    required this.googleMapAPI,
    required this.ifFirebase,
    required this.firebaseConfig,
    required this.firebaseAPI,
    required this.codStatus,
    required this.razorpayStatus,
    required this.razoKeyId,
    required this.razoKeySecret,
    required this.ccavenueStatus,
    required this.ccavenueTestmode,
    required this.ccavenueMerchantId,
    required this.ccavenueAccessCode,
    required this.ccavenueWorkingKey,
    required this.ifPhonepe,
    required this.phonepeMerchantId,
    required this.phonepeSaltkey,
    required this.phonepeMode,
    required this.ifQrcodePayment,
    required this.upid,
    required this.ifOnesignal,
    required this.onesignalId,
    required this.onesignalKey,
    required this.smtpHost,
    required this.smtpPort,
    required this.smtpUsername,
    required this.smtpPassword,
    required this.ifTestotp,
    required this.ifMsg91,
    required this.msg91Apikey,
    required this.ifTextlocal,
    required this.textlocalApikey,
    required this.ifGreensms,
    required this.greensmsAccessToken,
    required this.greensmsAccessTokenKey,
    required this.smsSenderid,
    required this.smsEntityId,
    required this.smsDltid,
    required this.smsMsg,
    required this.ifAuctionStart,
    required this.auctionCategoryId,
    required this.updatedOn,
  });

  factory CoreDataModel.fromJson(Map<String, dynamic> json) {
    return CoreDataModel(
      id: json['id']?.toString() ?? '1',
      siteUrl: json['siteurl']?.toString() ?? '',
      version: json['version']?.toString() ?? '',
      siteTitle: json['site_title']?.toString() ?? '',
      siteDescription: json['site_description']?.toString() ?? '',
      metaKeyword: json['meta_keyword']?.toString() ?? '',
      metaDetails: json['meta_details']?.toString() ?? '',
      logo: json['logo']?.toString() ?? '',
      minLogo: json['min_logo']?.toString() ?? '',
      favIcon: json['fav_icon']?.toString() ?? '',
      webLogo: json['web_logo']?.toString() ?? '',
      appLogo: json['app_logo']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      defaultCountry: json['default_country']?.toString() ?? '0',
      siteEmail: json['site_email']?.toString() ?? '',
      whatsappNo: json['whatsapp_no']?.toString() ?? '',
      sendgridAPI: json['sendgrid_API']?.toString() ?? '',
      ifGoogleMap: (json['if_googlemap']?.toString() == '1'),
      googleMapAPI: json['googlemap_API']?.toString() ?? '',
      ifFirebase: (json['if_firebase']?.toString() == '1'),
      firebaseConfig: json['firebase_config']?.toString() ?? '',
      firebaseAPI: json['firebase_API']?.toString() ?? '',
      codStatus: (json['cod_status']?.toString() == '1'),
      razorpayStatus: (json['razorpay_status']?.toString() == '1'),
      razoKeyId: json['razo_key_id']?.toString() ?? '',
      razoKeySecret: json['razo_key_secret']?.toString() ?? '',
      ccavenueStatus: (json['ccavenue_status']?.toString() == '1'),
      ccavenueTestmode: (json['ccavenue_testmode']?.toString() == '1'),
      ccavenueMerchantId: json['ccavenue_merchant_id']?.toString() ?? '',
      ccavenueAccessCode: json['ccavenue_access_code']?.toString() ?? '',
      ccavenueWorkingKey: json['ccavenue_working_key']?.toString() ?? '',
      ifPhonepe: (json['if_phonepe']?.toString() == '1'),
      phonepeMerchantId: json['phonepe_merchantId']?.toString() ?? '',
      phonepeSaltkey: json['phonepe_saltkey']?.toString() ?? '',
      phonepeMode: json['phonepe_mode']?.toString() ?? '',
      ifQrcodePayment: (json['if_qrcodepayment']?.toString() == '1'),
      upid: json['upid']?.toString() ?? '',
      ifOnesignal: (json['if_onesignal']?.toString() == '1'),
      onesignalId: json['onesignal_id']?.toString() ?? '',
      onesignalKey: json['onesignal_key']?.toString() ?? '',
      smtpHost: json['smtp_host']?.toString() ?? '',
      smtpPort: json['smtp_port']?.toString() ?? '',
      smtpUsername: json['smtp_username']?.toString() ?? '',
      smtpPassword: json['smtp_password']?.toString() ?? '',
      ifTestotp: (json['if_testotp']?.toString() == '1'),
      ifMsg91: (json['if_msg91']?.toString() == '1'),
      msg91Apikey: json['msg91_apikey']?.toString() ?? '',
      ifTextlocal: (json['if_textlocal']?.toString() == '1'),
      textlocalApikey: json['textlocal_apikey']?.toString() ?? '',
      ifGreensms: (json['if_greensms']?.toString() == '1'),
      greensmsAccessToken: json['greensms_accessToken']?.toString() ?? '',
      greensmsAccessTokenKey: json['greensms_accessTokenKey']?.toString() ?? '',
      smsSenderid: json['sms_senderid']?.toString() ?? '',
      smsEntityId: json['sms_entityId']?.toString() ?? '',
      smsDltid: json['sms_dltid']?.toString() ?? '',
      smsMsg: json['sms_msg']?.toString() ?? '',
      ifAuctionStart: (json['if_auction_start']?.toString() == '1'),
      auctionCategoryId: json['auction_category_id']?.toString() ?? '',
      updatedOn: json['updated_on']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'siteurl': siteUrl,
      'version': version,
      'site_title': siteTitle,
      'site_description': siteDescription,
      'meta_keyword': metaKeyword,
      'meta_details': metaDetails,
      'logo': logo,
      'min_logo': minLogo,
      'fav_icon': favIcon,
      'web_logo': webLogo,
      'app_logo': appLogo,
      'address': address,
      'default_country': defaultCountry,
      'site_email': siteEmail,
      'whatsapp_no': whatsappNo,
      'sendgrid_API': sendgridAPI,
      'if_googlemap': ifGoogleMap ? '1' : '0',
      'googlemap_API': googleMapAPI,
      'if_firebase': ifFirebase ? '1' : '0',
      'firebase_config': firebaseConfig,
      'firebase_API': firebaseAPI,
      'cod_status': codStatus ? '1' : '0',
      'razorpay_status': razorpayStatus ? '1' : '0',
      'razo_key_id': razoKeyId,
      'razo_key_secret': razoKeySecret,
      'ccavenue_status': ccavenueStatus ? '1' : '0',
      'ccavenue_testmode': ccavenueTestmode ? '1' : '0',
      'ccavenue_merchant_id': ccavenueMerchantId,
      'ccavenue_access_code': ccavenueAccessCode,
      'ccavenue_working_key': ccavenueWorkingKey,
      'if_phonepe': ifPhonepe ? '1' : '0',
      'phonepe_merchantId': phonepeMerchantId,
      'phonepe_saltkey': phonepeSaltkey,
      'phonepe_mode': phonepeMode,
      'if_qrcodepayment': ifQrcodePayment ? '1' : '0',
      'upid': upid,
      'if_onesignal': ifOnesignal ? '1' : '0',
      'onesignal_id': onesignalId,
      'onesignal_key': onesignalKey,
      'smtp_host': smtpHost,
      'smtp_port': smtpPort,
      'smtp_username': smtpUsername,
      'smtp_password': smtpPassword,
      'if_testotp': ifTestotp ? '1' : '0',
      'if_msg91': ifMsg91 ? '1' : '0',
      'msg91_apikey': msg91Apikey,
      'if_textlocal': ifTextlocal ? '1' : '0',
      'textlocal_apikey': textlocalApikey,
      'if_greensms': ifGreensms ? '1' : '0',
      'greensms_accessToken': greensmsAccessToken,
      'greensms_accessTokenKey': greensmsAccessTokenKey,
      'sms_senderid': smsSenderid,
      'sms_entityId': smsEntityId,
      'sms_dltid': smsDltid,
      'sms_msg': smsMsg,
      'if_auction_start': ifAuctionStart ? '1' : '0',
      'auction_category_id': auctionCategoryId,
      'updated_on': updatedOn,
    };
  }

  @override
  String toString() {
    return 'CoreDataModel(siteTitle: $siteTitle, version: $version, onesignalId: $onesignalId)';
  }
}