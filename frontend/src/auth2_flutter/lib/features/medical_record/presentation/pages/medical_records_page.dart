import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:auth2_flutter/features/data/domain/presentation/cubits/auth_cubit.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class MedicalRecordsPage extends StatefulWidget {
  const MedicalRecordsPage({super.key});

  @override
  State<MedicalRecordsPage> createState() => _MedicalRecordsPageState();
}

class _MedicalRecordsPageState extends State<MedicalRecordsPage> {
  List<dynamic> _records = [];
  bool _isLoading = true;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;
  final int _limit = 20;
  String _searchName = '';
  bool _isAdmin = false;

  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchRecords();
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

  Future<void> _fetchRecords({int page = 1}) async {
    setState(() {
      _isLoading = true;
      _currentPage = page;
    });

    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final user = context.read<AuthCubit>().currentUser;
      _isAdmin = user?.role == 'admin' || user?.role == 'super_admin';

      final queryParams = {
        'page': page.toString(),
        'limit': _limit.toString(),
        if (_searchName.isNotEmpty) 'search': _searchName,
      };

      final url = Uri.parse('${_getBaseUrl()}/api/medical-records')
          .replace(queryParameters: queryParams);
      final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        setState(() {
          _records = json['data'] ?? [];
          _totalPages = json['pagination']['pages'] ?? 1;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load medical records');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildRecordCard(Map<String, dynamic> record) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    record['patientName'] ?? 'Unknown',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    record['visitType'] ?? '',
                    style: TextStyle(fontSize: 12, color: Colors.blue[800]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Date: ${_formatDate(DateTime.parse(record['visitDate']))}'),
            Text('Doctor: ${record['doctorName']} (${record['doctorSpecialization'] ?? 'N/A'})'),
            const SizedBox(height: 8),
            if (record['diagnosis'] != null) ...[
              const Text('Diagnosis:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(record['diagnosis']['primary'] ?? 'N/A'),
              if (record['diagnosis']['secondary']?.isNotEmpty ?? false)
                Text('Secondary: ${(record['diagnosis']['secondary'] as List).join(', ')}'),
            ],
            if (record['prescriptions'] != null && record['prescriptions'].isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Prescriptions:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...List.generate(record['prescriptions'].length, (index) {
                final p = record['prescriptions'][index];
                return Text('• ${p['medication']} ${p['dosage']} ${p['frequency']}');
              }),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().currentUser;
    final canAccess = user?.role == 'doctor' || user?.role == 'admin' || user?.role == 'super_admin';
    if (!canAccess) {
      return Scaffold(
        appBar: AppBar(title: const Text('Medical Records')),
        body: const Center(child: Text('You do not have permission to view this page.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Records'),
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Search by patient name'),
                    content: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(hintText: 'Enter patient name'),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _searchName = _searchController.text;
                            _currentPage = 1;
                          });
                          _fetchRecords(page: 1);
                          Navigator.pop(ctx);
                        },
                        child: const Text('Search'),
                      ),
                    ],
                  ),
                );
              },
            ),
          if (_isAdmin && _searchName.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  _searchName = '';
                  _searchController.clear();
                  _currentPage = 1;
                });
                _fetchRecords(page: 1);
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _records.isEmpty
                  ? const Center(child: Text('No medical records found.'))
                  : Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            itemCount: _records.length,
                            itemBuilder: (ctx, index) => _buildRecordCard(_records[index]),
                          ),
                        ),
                        if (_totalPages > 1)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.chevron_left),
                                  onPressed: _currentPage > 1
                                      ? () => _fetchRecords(page: _currentPage - 1)
                                      : null,
                                ),
                                Text('Page $_currentPage of $_totalPages'),
                                IconButton(
                                  icon: const Icon(Icons.chevron_right),
                                  onPressed: _currentPage < _totalPages
                                      ? () => _fetchRecords(page: _currentPage + 1)
                                      : null,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
