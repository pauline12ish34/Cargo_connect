enum UserRole { driver, cargoOwner, admin }

enum BookingStatus { pending, accepted, declined, inProgress, completed, cancelled }

enum VehicleType { truck, van, pickup, lorry }

enum VehicleCapacity {
  small, // Under 1 ton
  medium, // 1-3 tons
  large, // 3-5 tons
  extraLarge, // 5+ tons
}
