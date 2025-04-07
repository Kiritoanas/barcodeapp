import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'database_helper.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Barcode Scanner',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Map<String, dynamic>> _barcodes = [];
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _loadBarcodes();
  }

  Future<void> _loadBarcodes() async {
    final barcodes = await _dbHelper.getAllBarcodes();
    setState(() {
      _barcodes = barcodes;
    });
  }

  void _startScanning() {
    setState(() => _isScanning = true);
  }

  void _stopScanning() {
    setState(() => _isScanning = false);
  }

  Future<void> _onBarcodeDetected(String code) async {
    _stopScanning();
    final existingBarcode = await _dbHelper.getBarcodeInfo(code);
    
    if (existingBarcode != null) {
      if (!mounted) return;
      _showBarcodeInfo(existingBarcode);
    } else {
      if (!mounted) return;
      _addNewBarcode(code);
    }
  }

  void _showBarcodeInfo(Map<String, dynamic> barcode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Barcode Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Code: ${barcode['code']}'),
            const SizedBox(height: 8),
            Text('Description: ${barcode['description']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _addNewBarcode(String code) {
    showDialog(
      context: context,
      builder: (context) {
        String description = '';
        return AlertDialog(
          title: const Text('Add Barcode Information'),
          content: TextField(
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Enter information about this barcode',
            ),
            onChanged: (value) => description = value,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await _dbHelper.insertBarcode(code, description);
                if (!mounted) return;
                Navigator.pop(context);
                _loadBarcodes();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barcode Scanner'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isScanning
          ? MobileScanner(
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty) {
                  _onBarcodeDetected(barcodes.first.rawValue ?? '');
                }
              },
            )
          : ListView.builder(
              itemCount: _barcodes.length,
              itemBuilder: (context, index) {
                final barcode = _barcodes[index];
                return ListTile(
                  title: Text(barcode['code']),
                  subtitle: Text(barcode['description']),
                  onTap: () => _showBarcodeInfo(barcode),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isScanning ? _stopScanning : _startScanning,
        tooltip: _isScanning ? 'Stop scanning' : 'Start scanning',
        child: Icon(_isScanning ? Icons.stop : Icons.qr_code_scanner),
      ),
    );
  }
}
