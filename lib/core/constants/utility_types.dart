/// Supported utility providers for Bangladesh.
enum UtilityType {
  desco,
  dpdc,
  wasa,
  titas,
  internet,
  btcl,
}

/// Official portal fallbacks (also used as Remote Config defaults).
const Map<String, String> kDefaultPaymentUrls = {
  'desco': 'https://selfservice.desco.org.bd/',
  'dpdc': 'https://ebill.dpdc.org.bd/',
  'wasa': 'https://dphe.portal.gov.bd/', // placeholder
  'titas': 'https://bill.titasgas.org.bd/',
  'internet': '', // user sets manually per account
  'btcl': 'https://www.btcl.gov.bd/online-bill-pay',
};

/// bKash bill-pay deeplinks (scheme may change — override via Remote Config later).
const Map<String, String> kBkashBillUrls = {
  'desco': 'bkash://billpay/desco',
  'dpdc': 'bkash://billpay/dpdc',
  'wasa': 'bkash://billpay/wasa',
  'titas': 'bkash://billpay/titas',
};

extension UtilityTypeX on UtilityType {
  String get displayNameBn => switch (this) {
        UtilityType.desco => 'DESCO (ঢাকা উত্তর)',
        UtilityType.dpdc => 'DPDC (ঢাকা দক্ষিণ)',
        UtilityType.wasa => 'WASA (পানি)',
        UtilityType.titas => 'তিতাস গ্যাস',
        UtilityType.internet => 'ইন্টারনেট',
        UtilityType.btcl => 'BTCL',
      };

  String get displayNameEn => switch (this) {
        UtilityType.desco => 'DESCO (Dhaka North)',
        UtilityType.dpdc => 'DPDC (Dhaka South)',
        UtilityType.wasa => 'WASA (Water)',
        UtilityType.titas => 'Titas Gas',
        UtilityType.internet => 'Internet',
        UtilityType.btcl => 'BTCL',
      };

  String get shortLabel => name.toUpperCase();
}
