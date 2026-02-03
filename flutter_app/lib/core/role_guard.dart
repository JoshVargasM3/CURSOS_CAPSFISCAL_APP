enum UserRole { admin, checker, customer, unknown }

UserRole parseRole(String? role) {
  switch (role) {
    case 'admin':
      return UserRole.admin;
    case 'checker':
      return UserRole.checker;
    case 'customer':
      return UserRole.customer;
    default:
      return UserRole.unknown;
  }
}

bool roleAllows(UserRole role, List<UserRole> allowed) {
  return allowed.contains(role);
}
