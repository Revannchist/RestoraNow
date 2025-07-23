import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class UserApiService {
  static const String baseUrl = 'http://localhost:5294/api/User';

  // Create a new user
  Future<UserModel> createUser(UserModel user, String password) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'firstName': user.firstName,
        'lastName': user.lastName,
        'email': user.email,
        'phoneNumber': user.phoneNumber,
        'isActive': user.isActive,
        'roles': user.roles,
        'password': password,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return UserModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create user: ${response.statusCode}');
    }
  }

  // Read all users (with optional search parameters)
  Future<List<UserModel>> getUsers({
    String? name,
    String? username,
    bool? isActive,
    bool includeTotalCount = false,
    bool retrieveAll = true,
    int page = 1,
    int pageSize = 10,
  }) async {
    final queryParams = {
      if (name != null) 'Name': name,
      if (username != null) 'Username': username,
      if (isActive != null) 'IsActive': isActive.toString(),
      'IncludeTotalCount': includeTotalCount.toString(),
      'RetrieveAll': retrieveAll.toString(),
      'Page': page.toString(),
      'PageSize': pageSize.toString(),
    };

    final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: {'accept': 'application/json'});

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> items = data['items'];
      return items.map((json) => UserModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load users: ${response.statusCode}');
    }
  }

  // Read a single user by ID
  Future<UserModel> getUserById(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/$id'),
      headers: {'accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load user: ${response.statusCode}');
    }
  }

  // Update a user
  Future<UserModel> updateUser(int id, UserModel user) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'firstName': user.firstName,
        'lastName': user.lastName,
        'email': user.email,
        'phoneNumber': user.phoneNumber,
        'isActive': user.isActive,
        'roles': user.roles,
      }),
    );

    if (response.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update user: ${response.statusCode}');
    }
  }

  // Delete a user
  Future<void> deleteUser(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/$id'),
      headers: {'accept': 'application/json'},
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete user: ${response.statusCode}');
    }
  }
}