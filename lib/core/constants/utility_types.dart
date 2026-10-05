/// Supported utility providers for Bangladesh.
enum UtilityType {
  desco,
  dpdc,
  wasa,
  titas,
  internet,
  btcl,
}

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
