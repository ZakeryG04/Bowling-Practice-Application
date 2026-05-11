import 'package:flutter/material.dart';
import '../services/spare_service.dart';

class SpareTrackerPage extends StatefulWidget {
  const SpareTrackerPage({super.key});

  @override
  State<SpareTrackerPage> createState() => _SpareTrackerPageState();
}

class _SpareTrackerPageState extends State<SpareTrackerPage> {
  final SpareService _spareService = SpareService();

  String _selectedSpare = '10 Pin\'s';
  int _made = 0;
  int _total = 0;
  bool _isSubmitting = false;
  final List<Map<String, dynamic>> _pendingAttempts = [];

  final List<String> _spareTypes = [
    '10 Pin\'s',
    '7 Pin\'s',
    '3-6-10\'s',
    'Clean Frames',
  ];

  void _selectSpare(String spare) {
    setState(() {
      _selectedSpare = spare;
      _made = 0;
      _total = 0;
    });
  }

  void _recordSpare(bool made) {
    setState(() {
      _pendingAttempts.add({
        'target_spare': _selectedSpare,
        'makes': made ? 1 : 0,
        'misses': made ? 0 : 1,
        'created_at': DateTime.now(),
      });
      _total++;
      if (made) _made++;
    });
  }

  Future<void> _submitSession() async {
    if (_pendingAttempts.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No spare attempts to submit.')),
        );
      }
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _spareService.saveSpareSession(
        spareAttempts: List<Map<String, dynamic>>.from(_pendingAttempts),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Spare session submitted successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      }

      setState(() {
        _pendingAttempts.clear();
        _made = 0;
        _total = 0;
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit session: $error'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  double get _percentage => _total == 0 ? 0.0 : (_made / _total) * 100;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Select Spare Type',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            children: _spareTypes.map((spare) {
              final isSelected = _selectedSpare == spare;
              return ElevatedButton(
                onPressed: () => _selectSpare(spare),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSelected
                      ? const Color.fromARGB(255, 109, 51, 40)
                      : Colors.grey[300],
                  foregroundColor: isSelected ? Colors.white : Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  minimumSize: const Size(0, 0),
                ),
                child: Text(spare, style: const TextStyle(fontSize: 14)),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 200, 160, 150),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  _selectedSpare,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_percentage.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 109, 51, 40),
                  ),
                ),
                Text('$_made / $_total', style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => _recordSpare(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(16),
                ),
                child: const Icon(Icons.check, size: 24, color: Colors.white),
              ),
              ElevatedButton(
                onPressed: () => _recordSpare(false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(16),
                ),
                child: const Icon(Icons.close, size: 24, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _isSubmitting ? null : _submitSession,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send),
            label: const Text('Submit Session'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pending attempts: ${_pendingAttempts.length}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
