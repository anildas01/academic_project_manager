import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/notification_service.dart';

class NotificationsPanel extends StatelessWidget {
  final String userEmail;
  final String userType;
  final Map<String, dynamic> userData;
  final VoidCallback? onCreateGroup;

  const NotificationsPanel({
    super.key,
    required this.userEmail,
    required this.userType,
    required this.userData,
    this.onCreateGroup,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Dashboard
        ListTile(
          leading: const Icon(Icons.dashboard),
          title: const Text('Dashboard'),
          onTap: () {
            // Handle dashboard navigation
          },
        ),

        const Divider(),
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Notifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Notifications List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .where('recipient', isEqualTo: userEmail)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final notifications = snapshot.data?.docs ?? [];

              if (notifications.isEmpty) {
                return const Center(child: Text('No notifications'));
              }

              return ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification =
                      notifications[index].data() as Map<String, dynamic>;
                  final notificationId = notifications[index].id;

                  return NotificationItem(
                    notificationId: notificationId,
                    notification: notification,
                    userType: userType,
                    onAccept: () =>
                        _handleAccept(context, notification, notificationId),
                    onDecline: () =>
                        _handleDecline(context, notification, notificationId),
                  );
                },
              );
            },
          ),
        ),

        // Bottom Menu Items
        const Divider(),
        ListTile(
          leading: const Icon(Icons.settings),
          title: const Text('Settings'),
          onTap: () {
            // Handle settings
          },
        ),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text('Logout', style: TextStyle(color: Colors.red)),
          onTap: () {
            // Handle logout
          },
        ),
      ],
    );
  }

  void _handleAccept(BuildContext context, Map<String, dynamic> notification,
      String notificationId) async {
    try {
      final notificationRef = FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId);

      final groupRef = FirebaseFirestore.instance
          .collection('groups')
          .doc(notification['groupId']);

      if (userType == 'student') {
        // Update group's acceptedMembers list
        await groupRef.update({
          'acceptedMembers': FieldValue.arrayUnion([userEmail])
        });
      } else if (userType == 'faculty') {
        // Update group's faculty status
        await groupRef.update({'facultyStatus': 'accepted'});
      }

      // Update notification status
      await notificationRef.update({'status': 'accepted'});

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation accepted')),
        );
      }
    } catch (e) {
      print('Error accepting invitation: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _handleDecline(BuildContext context, Map<String, dynamic> notification,
      String notificationId) async {
    try {
      final notificationRef = FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId);

      await notificationRef.update({'status': 'rejected'});

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation declined')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

class NotificationItem extends StatelessWidget {
  final String notificationId;
  final Map<String, dynamic> notification;
  final String userType;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const NotificationItem({
    super.key,
    required this.notificationId,
    required this.notification,
    required this.userType,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        title: const Text('Group Invitation'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Group: ${notification['groupName']}'),
            Text('Created by: ${notification['creatorName']}'),
          ],
        ),
        trailing: notification['status'] == 'pending'
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: onAccept,
                    child: const Text('Accept'),
                  ),
                  TextButton(
                    onPressed: onDecline,
                    child: const Text('Reject'),
                  ),
                ],
              )
            : Text(notification['status'].toUpperCase()),
      ),
    );
  }
}
