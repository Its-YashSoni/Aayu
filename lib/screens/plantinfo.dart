import 'package:flutter/material.dart';

class PlantInfoPage extends StatelessWidget {
  final String plantName;
  final Map<String, dynamic> plantData;

  PlantInfoPage({
    required this.plantName,
    required this.plantData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(plantName),
      ),
      body: PlantInfoItem(plantData: plantData),
    );
  }
}

class PlantInfoItem extends StatelessWidget {
  final Map<String, dynamic> plantData;

  PlantInfoItem({required this.plantData});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(10),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(10),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Plant Name: ${plantData['plantname']}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Image.network(
              plantData['plantimg'],
              width: MediaQuery.of(context).size.width,
              height: 200,
              fit: BoxFit.cover,
            ),
            SizedBox(height: 10),
            Text(
              'Plant Description: ${plantData['plantdescription']}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            Text(
              'Health Benefits:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(
                (plantData['healthbenifits'] as List<dynamic>).length,
                    (index) {
                  return Text(
                    '- ${(plantData['healthbenifits'] as List<dynamic>)[index]}',
                    style: TextStyle(fontSize: 14),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
