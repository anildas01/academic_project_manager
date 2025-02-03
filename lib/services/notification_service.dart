import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Stream<QuerySnapshot> getNotifications(String userEmail) {
    print('Fetching notifications for email: $userEmail');

    return _firestore
        .collection('notifications')
        .where('recipientEmail', isEqualTo: userEmail)
        .where('status', isEqualTo: 'pending')
        // Temporarily remove orderBy until index is created
        //.orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Future<void> sendGroupInvitation({
    required List<String> memberEmails,
    required String facultyEmail,
    required String groupName,
    required String creatorName,
    required String department,
    required String groupId,
  }) async {
    try {
      // Create notifications for student members
      for (String email in memberEmails) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'type': 'group_invitation',
          'recipient': email,
          'groupName': groupName,
          'groupId': groupId,
          'creatorName': creatorName,
          'department': department,
          'status': 'pending',
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      // Create notification for faculty
      await FirebaseFirestore.instance.collection('notifications').add({
        'type': 'faculty_request',
        'recipient': facultyEmail,
        'groupName': groupName,
        'groupId': groupId,
        'creatorName': creatorName,
        'department': department,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error sending notifications: $e');
      rethrow;
    }
  }

  static Future<void> updateNotificationStatus(
    String notificationId,
    String status,
  ) async {
    try {
      // Get the notification data first
      final notificationDoc = await _firestore
          .collection('notifications')
          .doc(notificationId)
          .get();
      final notificationData = notificationDoc.data() as Map<String, dynamic>;

      // Start a batch write
      WriteBatch batch = _firestore.batch();

      // Update notification status
      batch.update(_firestore.collection('notifications').doc(notificationId),
          {'status': status});

      // If accepted, check and update group status
      if (status == 'accepted') {
        // Find the group
        final groupsQuery = await _firestore
            .collection('groups')
            .where('name', isEqualTo: notificationData['groupName'])
            .get();

        if (groupsQuery.docs.isNotEmpty) {
          final groupDoc = groupsQuery.docs.first;
          final groupData = groupDoc.data();

          // For faculty acceptance
          if (notificationData['role'] == 'faculty') {
            batch.update(groupDoc.reference, {
              'facultyStatus': 'accepted',
            });
          }

          // For student acceptance
          if (notificationData['role'] == 'student') {
            final List<String> acceptedMembers =
                List<String>.from(groupData['acceptedMembers'] ?? []);
            acceptedMembers.add(notificationData['recipientEmail']);
            batch.update(groupDoc.reference, {
              'acceptedMembers': acceptedMembers,
            });
          }

          // Check if all members and faculty have accepted
          final allNotifications = await _firestore
              .collection('notifications')
              .where('groupName', isEqualTo: notificationData['groupName'])
              .get();

          bool allAccepted = true;
          for (var doc in allNotifications.docs) {
            if (doc.data()['status'] != 'accepted') {
              allAccepted = false;
              break;
            }
          }

          // If everyone has accepted, update group status
          if (allAccepted) {
            batch.update(groupDoc.reference, {'status': 'accepted'});
          }
        }
      }

      // Commit the batch
      await batch.commit();
      print('Updated notification and group status');
    } catch (e) {
      print('Error updating notification status: $e');
      throw 'Failed to update status';
    }
  }

  // Add method to verify notifications exist
  static Future<void> debugCheckNotifications(String email) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('notifications')
          .where('recipientEmail', isEqualTo: email)
          .get();

      print('\nDebug Check Notifications:');
      print('Email being checked: $email');
      print('Found ${snapshot.docs.length} notifications');
      for (var doc in snapshot.docs) {
        print('Notification: ${doc.data()}');
      }
    } catch (e) {
      print('Error checking notifications: $e');
    }
  }
}
