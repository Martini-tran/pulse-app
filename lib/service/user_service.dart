import '../domain/pulse_user.dart';

class UserService {


  Future<PulseUser> getCurrentUser() async {

    await Future.delayed(const Duration(seconds: 1));

    return const PulseUser(
      id: '1',
      name: 'Pulse User',
      email: 'user@pulse.com',
      avatar: 'https://example.com/avatar.jpg',
    );
  }

  Future<PulseUser> updateUser(PulseUser user) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return user;
  }


  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
  }


}