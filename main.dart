import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() {
  runApp(MyApp());
}
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BMI Calculator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: BMICalculator(),
    );
  }
}

class BMIDatabase {
  static final BMIDatabase instance = BMIDatabase._init();
  static Database? _database;
  BMIDatabase._init();

  static final String _dbName = 'bitp3453_bmi';
  static final String _tblName = 'bmi';
  static final String _colUsername = 'username';
  static final String _colWeight = 'weight';
  static final String _colHeight = 'height';
  static final String _colGender = 'gender';
  static final String _colStatus = 'bmi_status';

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tblName (
        $_colUsername TEXT PRIMARY KEY,
        $_colWeight REAL,
        $_colHeight REAL,
        $_colGender TEXT,
        $_colStatus TEXT
      )
    ''');
  }

  Future<void> insertData(Map<String, dynamic> data) async {
    final db = await instance.database;
    await db.insert(_tblName, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getData(String username) async {
    final db = await instance.database;
    final result = await db.query(_tblName,
        where: '$_colUsername = ?', whereArgs: [username]);

    return result.isNotEmpty ? result.first : null;
  }

  Future<List<Map<String, dynamic>>> getAllData() async {
    final db = await instance.database;
    return await db.query(_tblName);
  }
}

class BMICalculator extends StatefulWidget {
  @override
  _BMICalculatorState createState() => _BMICalculatorState();
}

class _BMICalculatorState extends State<BMICalculator> {
  final TextEditingController fullnameController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController bmivalueController = TextEditingController();
  final TextEditingController statusController = TextEditingController();
  String gender = " ";

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    final data = await BMIDatabase.instance.getAllData();

    if (data.isNotEmpty) {
      setState(() {
        fullnameController.text = data[0][BMIDatabase._colUsername];
        heightController.text = data[0][BMIDatabase._colHeight].toString();
        weightController.text = data[0][BMIDatabase._colWeight].toString();
        bmivalueController.text = '';
        statusController.text = data[0][BMIDatabase._colStatus];
        gender = data[0][BMIDatabase._colGender];
      });
    }
  }

  void calculateBMI() async {
    setState(() {
      double _height = double.parse(heightController.text) / 100;
      double _weight = double.parse(weightController.text);
      double bmi = _weight / (_height * _height);
      bmivalueController.text = bmi.toStringAsFixed(2);

      if (gender == 'Male') {
        if (bmi < 18.5)
          statusController.text = 'Underweight. Careful during strong wind!';
        else if (bmi >= 18.5 && bmi <= 24.9)
          statusController.text = 'That’s ideal! Please maintain';
        else if (bmi >= 25.0 && bmi <= 29.9)
          statusController.text = 'Overweight! Work out please';
        else
          statusController.text = 'Whoa Obese! Dangerous mate!';
      } else if (gender == 'Female') {
        if (bmi < 16)
          statusController.text = 'Underweight. Careful during strong wind!';
        else if (bmi >= 16 && bmi <= 22)
          statusController.text = 'That’s ideal! Please maintain';
        else if (bmi >= 22 && bmi <= 27)
          statusController.text = 'Overweight! Work out please';
        else
          statusController.text = 'Whoa Obese! Dangerous mate!';
      }

      BMIDatabase.instance.insertData({
        BMIDatabase._colUsername: fullnameController.text,
        BMIDatabase._colWeight: double.parse(weightController.text),
        BMIDatabase._colHeight: double.parse(heightController.text),
        BMIDatabase._colGender: gender,
        BMIDatabase._colStatus: statusController.text,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('BMI Calculator'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: fullnameController,
                decoration: InputDecoration(
                  labelText: 'Your Name',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: heightController,
                decoration: InputDecoration(
                  labelText: 'Height in cm; 170',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: weightController,
                decoration: InputDecoration(
                  labelText: 'Weight in KG',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: bmivalueController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Bmi Value',
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('Male'),
                    leading: Radio(
                      value: 'Male',
                      groupValue: gender,
                      onChanged: (String? value) {
                        setState(() {
                          gender = value!;
                        });
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: const Text('Female'),
                    leading: Radio(
                      value: 'Female',
                      groupValue: gender,
                      onChanged: (String? value) {
                        setState(() {
                          gender = value!;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: calculateBMI,
              child: Text('Calculate BMI and save'),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(statusController.text),
            )
          ],
        ),
      ),
    );
  }
}
