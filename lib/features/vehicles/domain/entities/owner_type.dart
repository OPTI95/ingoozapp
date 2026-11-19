/// Type of the vehicle owner. The API stores this in the single `owner_type`
/// string; the "other" variant is encoded as `other:<label>` (there is no
/// separate owner_type_other_label field server-side).
enum OwnerType { individual, soleProprietor, legalEntity, other }

extension OwnerTypeX on OwnerType {
  String get value {
    switch (this) {
      case OwnerType.individual:
        return 'individual';
      case OwnerType.soleProprietor:
        return 'sole';
      case OwnerType.legalEntity:
        return 'legal';
      case OwnerType.other:
        return 'other';
    }
  }

  static OwnerType fromValue(String? value) {
    if (value != null && value.startsWith('other')) {
      return OwnerType.other;
    }
    switch (value) {
      case 'sole':
        return OwnerType.soleProprietor;
      case 'legal':
        return OwnerType.legalEntity;
      case 'individual':
      default:
        return OwnerType.individual;
    }
  }

  static String? otherLabelFromValue(String? value) {
    if (value == null || !value.startsWith('other:')) return null;
    final label = value.substring('other:'.length).trim();
    return label.isEmpty ? null : label;
  }

  static String encodeValue(OwnerType type, {String? otherLabel}) {
    if (type != OwnerType.other) return type.value;
    final label = otherLabel?.trim();
    if (label == null || label.isEmpty) return 'other';
    return 'other:$label';
  }
}
