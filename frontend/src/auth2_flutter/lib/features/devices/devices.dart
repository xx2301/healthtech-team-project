import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:auth2_flutter/features/data/domain/presentation/components/appbar.dart';
import 'package:auth2_flutter/features/data/domain/presentation/components/drawer.dart';

class DevicesPage extends StatefulWidget {
  const DevicesPage({Key? key}) : super(key: key);

  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  List<dynamic> _devices = [];
  bool _isLoading = true;
  String? _error;
  String? _syncingDeviceId;

  final _nameController = TextEditingController();
  final _typeController = TextEditingController();
  final _modelController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _serialController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchDevices();
  }

  String _formatDateTime(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  String _getBaseUrl() {
    if (kIsWeb) return 'http://10.101.61.123:3001';
    if (Platform.isAndroid) return 'http://10.0.2.2:3001';
    if (Platform.isIOS) return 'http://10.101.61.123:3001';
    return 'http://10.101.61.123:3001';
  }

  Future<void> _fetchDevices() async {
    setState(() => _isLoading = true);
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('${_getBaseUrl()}/api/devices'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        setState(() {
          _devices = json['data'] ?? [];
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load devices');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _addDevice(Map<String, String> deviceData) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.post(
        Uri.parse('${_getBaseUrl()}/api/devices'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(deviceData),
      );

      if (response.statusCode == 201) {
        _fetchDevices();
      } else {
        print('Add device failed: ${response.body}');
        final errorMsg = jsonDecode(response.body)['error'] ?? 'Failed to add device';
        throw Exception(errorMsg);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _syncDevice(String deviceId) async {
    setState(() {
      _syncingDeviceId = deviceId;
    });

    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.post(
        Uri.parse('${_getBaseUrl()}/api/devices/sync/$deviceId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        await _fetchDevices();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Device synced successfully')),
        );
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Sync failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _syncingDeviceId = null;
      });
    }
  }

  Future<void> _deleteDevice(String id) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.delete(
        Uri.parse('${_getBaseUrl()}/api/devices/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        _fetchDevices();
      } else {
        throw Exception('Failed to delete device');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _toggleDeviceStatus(String id, bool isActive) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.put(
        Uri.parse('${_getBaseUrl()}/api/devices/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'isActive': !isActive}),
      );

      if (response.statusCode == 200) {
        _fetchDevices();
      } else {
        throw Exception('Failed to update device');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _simulateFault(String id) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.put(
        Uri.parse('${_getBaseUrl()}/api/devices/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'status': 'error'}),
      );

      if (response.statusCode == 200) {
        _fetchDevices();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fault simulated! Device status set to error.')),
        );
      } else {
        throw Exception('Failed to simulate fault');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showAddDeviceDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add Virtual Device'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Device Name *'),
                ),
                TextField(
                  controller: _typeController,
                  decoration: const InputDecoration(labelText: 'Device Type * (e.g., heart_rate, steps)'),
                ),
                TextField(
                  controller: _modelController,
                  decoration: const InputDecoration(labelText: 'Model'),
                ),
                TextField(
                  controller: _manufacturerController,
                  decoration: const InputDecoration(labelText: 'Manufacturer'),
                ),
                TextField(
                  controller: _serialController,
                  decoration: const InputDecoration(labelText: 'Serial Number'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _nameController.clear();
                _typeController.clear();
                _modelController.clear();
                _manufacturerController.clear();
                _serialController.clear();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_nameController.text.isEmpty || _typeController.text.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Name and type are required')),
                  );
                  return;
                }
                final deviceData = {
                  'name': _nameController.text,
                  'type': _typeController.text,
                  'model': _modelController.text,
                  'manufacturer': _manufacturerController.text,
                  'serialNumber': _serialController.text,
                };
                Navigator.pop(ctx);
                _addDevice(deviceData);
                _nameController.clear();
                _typeController.clear();
                _modelController.clear();
                _manufacturerController.clear();
                _serialController.clear();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DefaultAppBar(),
      drawer: DefaultDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Health Devices',
                            style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: _showAddDeviceDialog,
                                tooltip: 'Add Device',
                              ),
                              IconButton(
                                icon: const Icon(Icons.refresh),
                                onPressed: _fetchDevices,
                              ),
                            ],
                          ),
                        ],
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          "These are your external health devices (e.g., smartwatches, fitness trackers). "
                          "To manage your logged-in sessions, go to Personal Information.",
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ),
                      const SizedBox(height: 50),

                      Center(
                        child: Column(
                          children: [
                            SizedBox(
                              width: 250,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.black,
                                ),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('QR linking not implemented yet')),
                                  );
                                },
                                child: const Text("Link Device by QR"),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: 250,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.black,
                                ),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Bluetooth linking not implemented yet')),
                                  );
                                },
                                child: const Text("Link Device by Bluetooth"),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 50),

                      const Text(
                        'My Devices',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),

                      if (_devices.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Text('No devices yet. Tap + to add.'),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _devices.length,
                          itemBuilder: (ctx, index) {
                            final device = _devices[index];
                            final isActive = device['isActive'] ?? true;
                            final status = device['status'] ?? 'online';
                            final isError = status == 'error' || status == 'offline';
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                leading: Icon(
                                  Icons.devices,
                                  color: isError ? Colors.red : (isActive ? Colors.green : Colors.grey),
                                ),
                                title: Text(device['name'] ?? 'Unnamed'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Type: ${device['type']}'),
                                    if (device['model'] != null && device['model'].isNotEmpty)
                                      Text('Model: ${device['model']}'),
                                    Text('Status: ${isActive ? status : 'offline'}'),
                                    if (device['lastSyncAt'] != null)
                                      Text('Last sync: ${_formatDateTime(DateTime.parse(device['lastSyncAt']))}'),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_syncingDeviceId == device['_id'])
                                      const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                    else ...[
                                      if (isError)
                                        const Tooltip(
                                          message: 'Device error detected',
                                          child: Icon(Icons.error, color: Colors.red),
                                        ),
                                      IconButton(
                                        icon: const Icon(Icons.sync),
                                        onPressed: () => _syncDevice(device['_id']),
                                        tooltip: 'Sync now',
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          isActive ? Icons.toggle_on : Icons.toggle_off,
                                          color: isActive ? Colors.green : Colors.grey,
                                        ),
                                        onPressed: () => _toggleDeviceStatus(device['_id'], isActive),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.bug_report, color: Colors.orange),
                                        onPressed: () => _simulateFault(device['_id']),
                                        tooltip: 'Simulate fault',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _deleteDevice(device['_id']),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
    );
  }
}
