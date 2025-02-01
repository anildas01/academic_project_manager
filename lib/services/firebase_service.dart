import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/password_validator.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Check if contact exists in the appropriate collection
  Future<bool> verifyContact(String contact, String role) async {
    try {
      // Format the contact if it's a phone number
      if (!contact.contains('@')) {
        // Remove any spaces or special characters
        contact = contact.replaceAll(RegExp(r'[^\d]'), '');
      }

      print('Checking contact: $contact in ${role.toLowerCase()} collection');

      // Determine if input is email or phone
      bool isEmail = contact.contains('@');
      String fieldToCheck = isEmail ? 'email' : 'phone';

      // Use correct collection name (plural)
      String collectionName =
          role.toLowerCase() + 's'; // 'students' or 'faculty'

      print(
          'Querying collection: $collectionName with field: $fieldToCheck = $contact');

      // Check in the appropriate collection
      final QuerySnapshot result = await _firestore
          .collection(collectionName)
          .where(fieldToCheck, isEqualTo: contact)
          .get();

      print('Query result docs length: ${result.docs.length}');
      if (result.docs.isNotEmpty) {
        // Print the found document for debugging
        print('Found document data: ${result.docs.first.data()}');

        // Generate and send OTP
        await generateAndSendOTP(contact);
        return true;
      } else {
        print('Contact not found in $collectionName collection');
        return false;
      }
    } catch (e) {
      print('Error verifying contact: $e');
      print(StackTrace.current);
      return false;
    }
  }

  // Generate and store OTP
  Future<void> generateAndSendOTP(String contact) async {
    try {
      // Generate a 6-digit OTP
      String otp = (100000 + DateTime.now().millisecond % 900000).toString();

      // Store OTP in Firestore
      await _firestore.collection('otps').doc(contact).set({
        'otp': otp,
        'timestamp': FieldValue.serverTimestamp(),
        'verified': false,
        'attempts': 0
      });

      print('OTP generated and stored: $otp for contact: $contact');

      // For email
      if (contact.contains('@')) {
        // TODO: Implement email sending
        print('Email OTP: $otp'); // For testing only
      }
      // For phone
      else {
        // TODO: Implement SMS sending
        print('SMS OTP: $otp'); // For testing only
      }
    } catch (e) {
      print('Error generating OTP: $e');
      print(StackTrace.current);
      throw Exception('Failed to generate OTP');
    }
  }

  // Verify OTP
  Future<bool> verifyOTP(String contact, String otp) async {
    try {
      DocumentSnapshot otpDoc =
          await _firestore.collection('otps').doc(contact).get();

      if (!otpDoc.exists) {
        print('No OTP document found for contact: $contact');
        return false;
      }

      Map<String, dynamic> otpData = otpDoc.data() as Map<String, dynamic>;

      // Check if OTP is expired (5 minutes validity)
      Timestamp timestamp = otpData['timestamp'] as Timestamp;
      DateTime otpTime = timestamp.toDate();
      if (DateTime.now().difference(otpTime).inMinutes > 5) {
        print('OTP expired');
        return false;
      }

      // Check if too many attempts
      if (otpData['attempts'] >= 3) {
        print('Too many attempts');
        return false;
      }

      // Increment attempts
      await _firestore
          .collection('otps')
          .doc(contact)
          .update({'attempts': FieldValue.increment(1)});

      // Check if OTP matches
      if (otpData['otp'] == otp) {
        // Mark as verified
        await _firestore
            .collection('otps')
            .doc(contact)
            .update({'verified': true});
        print('OTP verified successfully');
        return true;
      }

      print('OTP does not match');
      return false;
    } catch (e) {
      print('Error verifying OTP: $e');
      print(StackTrace.current);
      return false;
    }
  }

  // Set password and complete registration
  Future<bool> completeRegistration(
      String contact, String password, String role) async {
    try {
      // Create auth user with email (if contact is email)
      UserCredential userCredential;
      if (contact.contains('@')) {
        userCredential = await _auth.createUserWithEmailAndPassword(
          email: contact,
          password: password,
        );
      } else {
        // For phone numbers, you might want to use phone authentication
        // or create a custom auth system
        userCredential = await _auth.createUserWithEmailAndPassword(
          email: '$contact@yourdomain.com',
          password: password,
        );
      }

      // Store user data in Firestore
      await _firestore
          .collection(role.toLowerCase())
          .doc(userCredential.user!.uid)
          .set({
        'contact': contact,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error completing registration: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getStudentDetails(String contact) async {
    try {
      QuerySnapshot result;

      // Check if the contact is email or phone
      if (contact.contains('@')) {
        result = await _firestore
            .collection('students')
            .where('email', isEqualTo: contact)
            .get();
      } else {
        result = await _firestore
            .collection('students')
            .where('phone', isEqualTo: contact)
            .get();
      }

      if (result.docs.isNotEmpty) {
        // Get the first matching document
        var studentData = result.docs.first.data() as Map<String, dynamic>;
        print('Found student details: $studentData');
        return {
          'email': studentData['email'] ?? '',
          'phone': studentData['phone'] ?? '',
          'name': studentData['name'] ?? '',
        };
      }
      return null;
    } catch (e) {
      print('Error fetching student details: $e');
      return null;
    }
  }

  Future<bool> storeStudentCredentials(String contact, String password) async {
    String? validationError = PasswordValidator.validatePassword(password);
    if (validationError != null) {
      print('Password validation failed: $validationError');
      return false;
    }

    try {
      // First, fetch complete student data from students collection
      QuerySnapshot studentQuery;
      if (contact.contains('@')) {
        studentQuery = await _firestore
            .collection('students')
            .where('email', isEqualTo: contact)
            .get();
      } else {
        studentQuery = await _firestore
            .collection('students')
            .where('phone', isEqualTo: contact)
            .get();
      }

      if (studentQuery.docs.isEmpty) {
        print('No student found with this contact info');
        return false;
      }

      // Get the complete student data
      Map<String, dynamic> studentData =
          studentQuery.docs.first.data() as Map<String, dynamic>;
      print('Found student data: $studentData');

      // Create user ID from email
      String userId =
          studentData['email'].replaceAll('@', '_').replaceAll('.', '_');

      // Store complete student data along with login credentials
      await _firestore.collection('student_logins').doc(userId).set({
        'email': studentData['email'],
        'phone': studentData['phone'],
        'password': password,
        'name': studentData['name'],
        'department': studentData['department'],
        'year': studentData['year'],
        'semester': studentData['semester'],
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': null,
        'passwordStrength': PasswordValidator.calculateStrength(password),
      });

      print('Student credentials stored successfully with complete data');
      return true;
    } catch (e) {
      print('Error storing student credentials: $e');
      print(StackTrace.current);
      return false;
    }
  }

  // Similar update for faculty credentials if needed
  Future<Map<String, dynamic>?> getFacultyDetails(String contact) async {
    try {
      QuerySnapshot result;

      if (contact.contains('@')) {
        result = await _firestore
            .collection('faculty')
            .where('email', isEqualTo: contact)
            .get();
      } else {
        result = await _firestore
            .collection('faculty')
            .where('phone', isEqualTo: contact)
            .get();
      }

      if (result.docs.isNotEmpty) {
        var facultyData = result.docs.first.data() as Map<String, dynamic>;
        print('Found faculty details: $facultyData');
        return {
          'email': facultyData['email'] ?? '',
          'phone': facultyData['phone'] ?? '',
          'name': facultyData['name'] ?? '',
        };
      }
      return null;
    } catch (e) {
      print('Error fetching faculty details: $e');
      return null;
    }
  }

  Future<bool> storeFacultyCredentials(String contact, String password) async {
    String? validationError = PasswordValidator.validatePassword(password);
    if (validationError != null) {
      print('Password validation failed: $validationError');
      return false;
    }

    try {
      // First, get faculty details from faculty collection
      Map<String, dynamic>? facultyDetails = await getFacultyDetails(contact);

      if (facultyDetails == null) {
        print('Error: Faculty details not found in database');
        return false;
      }

      String email = facultyDetails['email'];
      String phone = facultyDetails['phone'];

      // Generate a valid document ID using email
      String userId = email.replaceAll('@', '_').replaceAll('.', '_');

      print('Creating login document with ID: $userId');

      await _firestore.collection('faculty_logins').doc(userId).set({
        'email': email,
        'phone': phone,
        'password': password,
        'name': facultyDetails['name'],
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': null,
        'passwordStrength': PasswordValidator.calculateStrength(password),
      });

      print(
          'Faculty credentials stored successfully with both email and phone');
      return true;
    } catch (e) {
      print('Error storing faculty credentials: $e');
      print(StackTrace.current);
      return false;
    }
  }

  Future<Map<String, dynamic>?> verifyLogin(
      String contact, String password, String role) async {
    try {
      QuerySnapshot result;
      String collectionName = '${role.toLowerCase()}_logins';

      // Check if contact is email or phone
      if (contact.contains('@')) {
        result = await _firestore
            .collection(collectionName)
            .where('email', isEqualTo: contact)
            .where('password', isEqualTo: password)
            .get();
      } else {
        result = await _firestore
            .collection(collectionName)
            .where('phone', isEqualTo: contact)
            .where('password', isEqualTo: password)
            .get();
      }

      if (result.docs.isNotEmpty) {
        // Update last login timestamp
        String userId = result.docs.first.id;
        await _firestore.collection(collectionName).doc(userId).update({
          'lastLogin': FieldValue.serverTimestamp(),
        });

        // Return user data
        return result.docs.first.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error verifying login: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getAvailableStudents(
      String department, String year) async {
    try {
      print('Fetching students for $department, Year: $year');

      // Now we can directly query student_logins since it has all the data
      final QuerySnapshot loginSnapshot = await _firestore
          .collection('student_logins')
          .where('department', isEqualTo: department)
          .where('year', isEqualTo: year)
          .get();

      print('Found ${loginSnapshot.docs.length} matching students');

      final List<Map<String, dynamic>> availableStudents = loginSnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .map((student) => {
                'name': student['name'],
                'email': student['email'],
                'phone': student['phone'],
                'semester': student['semester'],
                'department': student['department'],
                'year': student['year'],
              })
          .toList();

      print('Available students: $availableStudents');
      return availableStudents;
    } catch (e) {
      print('Error fetching students: $e');
      print(StackTrace.current);
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAvailableFaculty(
      String department) async {
    try {
      print('Fetching faculty for $department');

      // First get all logged-in faculty from faculty_logins
      final QuerySnapshot loginSnapshot =
          await _firestore.collection('faculty_logins').get();

      // Get their emails
      final List<String> loggedInEmails = loginSnapshot.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['email'] as String)
          .toList();

      print('Found ${loggedInEmails.length} logged-in faculty members');

      // Then fetch faculty details from faculty collection
      final QuerySnapshot facultySnapshot = await _firestore
          .collection('faculty')
          .where('department', isEqualTo: department)
          .get();

      // Filter and map the results
      final List<Map<String, dynamic>> availableFaculty = facultySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .where((faculty) => loggedInEmails.contains(faculty['email']))
          .map((faculty) => {
                'name': faculty['name'],
                'email': faculty['email'],
                'phone': faculty['phone'],
                'department': faculty['department'],
                'designation': faculty['designation'] ?? 'Faculty',
              })
          .toList();

      print('Found ${availableFaculty.length} matching faculty members');
      return availableFaculty;
    } catch (e) {
      print('Error fetching faculty: $e');
      print(StackTrace.current);
      return [];
    }
  }

  Future<bool> createProjectGroup({
    required String groupName,
    required String creatorEmail,
    required List<String> memberEmails,
    required String facultyEmail,
    required String department,
    required int semester,
  }) async {
    try {
      // Create group document
      DocumentReference groupRef =
          await _firestore.collection('project_groups').add({
        'name': groupName,
        'creator': creatorEmail,
        'members': [creatorEmail],
        'pendingMembers': memberEmails,
        'faculty': facultyEmail,
        'facultyApproved': false,
        'department': department,
        'semester': semester,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      // Create invitations for members
      for (String email in memberEmails) {
        await _firestore.collection('invitations').add({
          'type': 'member',
          'groupId': groupRef.id,
          'groupName': groupName,
          'to': email,
          'from': creatorEmail,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // Create faculty request
      await _firestore.collection('invitations').add({
        'type': 'faculty',
        'groupId': groupRef.id,
        'groupName': groupName,
        'to': facultyEmail,
        'from': creatorEmail,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error creating project group: $e');
      return false;
    }
  }

  Stream<QuerySnapshot> getGroupInvitations(String email) {
    return _firestore
        .collection('invitations')
        .where('to', isEqualTo: email)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  Future<bool> respondToInvitation(String invitationId, bool accept) async {
    try {
      DocumentSnapshot invitation =
          await _firestore.collection('invitations').doc(invitationId).get();

      Map<String, dynamic> data = invitation.data() as Map<String, dynamic>;
      String groupId = data['groupId'];

      if (accept) {
        // Update group members if accepting
        await _firestore.collection('project_groups').doc(groupId).update({
          'members': FieldValue.arrayUnion([data['to']]),
          'pendingMembers': FieldValue.arrayRemove([data['to']]),
        });
      }

      // Update invitation status
      await _firestore
          .collection('invitations')
          .doc(invitationId)
          .update({'status': accept ? 'accepted' : 'declined'});

      return true;
    } catch (e) {
      print('Error responding to invitation: $e');
      return false;
    }
  }

  Future<Map<int, List<Map<String, dynamic>>>> getAvailableStudentsBySemester(
      String department) async {
    try {
      print('\n=== DEBUG: Student Fetching Process ===');
      print('Searching in department: "$department"');

      // 1. Get all student_logins
      final QuerySnapshot loginSnapshot =
          await _firestore.collection('student_logins').get();

      print('\n1. Student Logins found: ${loginSnapshot.docs.length}');
      loginSnapshot.docs.forEach((doc) {
        final data = doc.data() as Map<String, dynamic>;
        print('Login record:');
        print('- Email: ${data['email']}');
        print('- Department: ${data['department']}');
        print('- Semester: ${data['semester']}');
      });

      // 2. Filter by department
      var departmentStudents = loginSnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .where((data) {
        bool matches = data['department'].toString().toLowerCase().trim() ==
            department.toString().toLowerCase().trim();
        print('\nChecking department match for ${data['email']}:');
        print(
            'Student dept: "${data['department']?.toString().toLowerCase().trim()}"');
        print('Search dept: "${department.toString().toLowerCase().trim()}"');
        print('Matches: $matches');
        return matches;
      }).toList();

      print('\n2. Students in department: ${departmentStudents.length}');

      // 3. Group by semester
      Map<int, List<Map<String, dynamic>>> studentsBySemester = {};

      for (var studentData in departmentStudents) {
        int semester = studentData['semester'] as int;
        print('\nProcessing student: ${studentData['email']}');
        print('Semester: $semester');

        if (!studentsBySemester.containsKey(semester)) {
          studentsBySemester[semester] = [];
        }

        studentsBySemester[semester]!.add({
          'name': studentData['name'],
          'email': studentData['email'],
          'phone': studentData['phone'],
          'semester': semester,
          'department': studentData['department'],
          'year': studentData['year'],
        });
      }

      print('\n3. Final grouping:');
      studentsBySemester.forEach((semester, students) {
        print('Semester $semester: ${students.length} students');
        students.forEach((student) {
          print('- ${student['name']} (${student['email']})');
        });
      });

      return studentsBySemester;
    } catch (e) {
      print('\nERROR in getAvailableStudentsBySemester: $e');
      print(StackTrace.current);
      return {};
    }
  }

  Future<Map<String, Map<int, List<Map<String, dynamic>>>>>
      getAvailableStudentsByDeptAndSemester() async {
    try {
      final QuerySnapshot studentsSnapshot =
          await _firestore.collection('students').get();

      Map<String, Map<int, List<Map<String, dynamic>>>> result = {};

      for (var doc in studentsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final department = data['department'] as String;
        final semester = data['semester'] as int;

        result.putIfAbsent(department, () => {});
        result[department]!.putIfAbsent(semester, () => []);
        result[department]![semester]!.add({
          'name': data['name'],
          'email': data['email'],
          'phone': data['phone'],
        });
      }

      return result;
    } catch (e) {
      print('Error fetching students: $e');
      return {};
    }
  }
}
