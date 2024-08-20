import 'package:flutter/material.dart';

class CallScreen extends StatefulWidget {
  const CallScreen({super.key});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final List<Map<String, dynamic>> _callList = [
    {
      'name': 'John Doe',
      'type': 'incoming',
      'time': '10:30 AM',
    },
    {
      'name': 'Jane Smith',
      'type': 'outgoing',
      'time': '9:45 AM',
    },
    {
      'name': 'Alice Johnson',
      'type': 'missed',
      'time': '8:15 AM',
    },
    {
      'name': 'Bob Brown',
      'type': 'incoming',
      'time': 'Yesterday',
    },
    {
      'name': 'Charlie Davis',
      'type': 'outgoing',
      'time': 'Yesterday',
    },
    {
      'name': 'Diana Evans',
      'type': 'missed',
      'time': '2 days ago',
    },
    {
      'name': 'Frank Green',
      'type': 'incoming',
      'time': '3 days ago',
    },
    {
      'name': 'Grace Harris',
      'type': 'outgoing',
      'time': '3 days ago',
    },
    {
      'name': 'Henry Irving',
      'type': 'missed',
      'time': '4 days ago',
    },
    {
      'name': 'Ivy Johnson',
      'type': 'incoming',
      'time': '4 days ago',
    },
  ];

  Icon _getCallIcon(String type) {
    switch (type) {
      case 'incoming':
        return const Icon(Icons.call_received, color: Colors.green);
      case 'outgoing':
        return const Icon(Icons.call_made, color: Colors.blue);
      case 'missed':
        return const Icon(Icons.call_missed, color: Colors.red);
      default:
        return const Icon(Icons.call, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ListView.separated(
            itemBuilder: (_, i) {
              return ListTile(
                leading: _getCallIcon(_callList[i]['type']),
                title: Text(_callList[i]['name']),
                subtitle: Text(_callList[i]['time']),
                trailing: const Icon(Icons.info_outline),
                onTap: () {
                  // Handle call details action
                },
              );
            },
            separatorBuilder: (_, i) {
              return const Divider();
            },
            itemCount: _callList.length,
          ),
        ),
      ],
    );
  }
}
