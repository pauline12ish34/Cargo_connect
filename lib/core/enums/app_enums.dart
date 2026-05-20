enum UserRole { driver, cargoOwner, admin }

enum BookingStatus { pending, accepted, declined, inProgress, completed, cancelled }

enum VehicleType {
  truck,
  van,
  pickup,
  lorry,
  miniTruck,
  flatbed,
  refrigerated,
  tipper,
  containerTruck,
  boxTruck,
  motorcycle,
}

extension VehicleTypeDisplay on VehicleType {
  String get displayName {
    switch (this) {
      case VehicleType.truck:
        return 'Truck';
      case VehicleType.van:
        return 'Van';
      case VehicleType.pickup:
        return 'Pickup';
      case VehicleType.lorry:
        return 'Lorry';
      case VehicleType.miniTruck:
        return 'Mini Truck';
      case VehicleType.flatbed:
        return 'Flatbed Truck';
      case VehicleType.refrigerated:
        return 'Refrigerated Truck';
      case VehicleType.tipper:
        return 'Tipper Truck';
      case VehicleType.containerTruck:
        return 'Container Truck';
      case VehicleType.boxTruck:
        return 'Box Truck';
      case VehicleType.motorcycle:
        return 'Motorcycle';
    }
  }
}

enum VehicleCapacity {
  small, // Under 1 ton
  medium, // 1-3 tons
  large, // 3-5 tons
  extraLarge, // 5+ tons
}
