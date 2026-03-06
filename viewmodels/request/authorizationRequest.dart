class LoginRequest {
  String email;
  String password;

  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
  };
}
class RegisterRequest {
  String email;
  String password;
  String confirmPassword;
  String phone;
  String address;

  RegisterRequest({
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.phone,
    required this.address,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
    'confirmPassword': confirmPassword,
    'phone': phone,
    'address': address,
  };
}

