import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class NotificationListPage extends StatefulWidget {
  const NotificationListPage({Key? key}) : super(key: key);

  @override
  State<NotificationListPage> createState() => _NotificationListPageState();
}

class _NotificationListPageState extends State<NotificationListPage> {
  List<dynamic> _notifications = [];
  bool _loading = true;
  int _page = 1;
  bool _hasMore = true;
  final int _limit = 20;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  String _getBaseUrl() {
    if (kIsWeb) return 'http://localhost:3001';
    if (Platform.isAndroid) return 'http://10.0.2.2:3001';
    if (Platform.isIOS) return 'http://localhost:3001';
    return 'http://localhost:3001';
  }

  Future<void> _fetchNotifications({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _page = 1;
        _notifications = [];
        _hasMore = true;
        _loading = true;
      });
    }

    if (!_hasMore || _loadingMore) return;

    setState(() => _loadingMore = !refresh);

    try {
      final token = await _getToken();
      if (token == null) return;

      final url = Uri.parse('${_getBaseUrl()}/api/notifications?page=$_page&limit=$_limit');
      final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List<dynamic> newNotifications = json['data'];
        final pagination = json['pagination'];

        setState(() {
          if (refresh) {
            _notifications = newNotifications;
          } else {
            _notifications.addAll(newNotifications);
          }
          _hasMore = newNotifications.length == _limit && _notifications.length < pagination['total'];
          _page++;
          _loading = false;
          _loadingMore = false;
        });
      } else {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _loadingMore = false;
      });
      print('Error fetching notifications: $e');
    }
  }

  Future<void> _markAsRead(String id) async {
    try {
      final token = await _getToken();
      if (token == null) return;
      final response = await http.put(
        Uri.parse('${_getBaseUrl()}/api/notifications/$id/read'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        setState(() {
          final index = _notifications.indexWhere((n) => n['_id'] == id);
          if (index != -1) {
            _notifications[index]['isRead'] = true;
          }
        });
      }
    } catch (e) {
      print('Error marking as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final token = await _getToken();
      if (token == null) return;
      final response = await http.put(
        Uri.parse('${_getBaseUrl()}/api/notifications/read-all'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        setState(() {
          for (var n in _notifications) {
            n['isRead'] = true;
          }
        });
      }
    } catch (e) {
      print('Error marking all as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: _markAllAsRead,
            tooltip: 'Mark all as read',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(child: Text('No notifications'))
              : RefreshIndicator(
                  onRefresh: () => _fetchNotifications(refresh: true),
                  child: ListView.builder(
                    itemCount: _notifications.length + (_hasMore ? 1 : 0),
                    itemBuilder: (ctx, index) {
                      if (index == _notifications.length) {
                        // Load more indicator
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: _loadingMore
                                ? const CircularProgressIndicator()
                                : const Text('No more notifications'),
                          ),
                        );
                      }
                      final notification = _notifications[index];
                      final isRead = notification['isRead'] ?? false;
                      final createdAt = DateTime.parse(notification['createdAt']);
                      return Dismissible(
                        key: Key(notification['_id']),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Colors.green,
                          child: const Icon(Icons.done, color: Colors.white),
                        ),
                        onDismissed: (_) => _markAsRead(notification['_id']),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: notification['type'] == 'threshold_alert'
                                ? Colors.red
                                : Colors.blue,
                            child: Icon(
                              notification['type'] == 'threshold_alert'
                                  ? Icons.warning
                                  : Icons.info,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(notification['title'] ?? 'Alert'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(notification['message'] ?? ''),
                              Text(
                                _formatDate(createdAt),
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          trailing: isRead
                              ? null
                              : Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                          onTap: () {
                            if (!isRead) {
                              _markAsRead(notification['_id']);
                            }
                            final type = notification['type'] ?? '';
                            if (type == 'doctor_application') {
                              Navigator.pushNamed(context, '/admin/review');
                            } else if (type == 'threshold_alert') {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Threshold alert')),
                              );
                            } else {
                              // nothing first
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}