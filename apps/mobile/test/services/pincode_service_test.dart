import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kirana_mobile/core/services/pincode_service.dart';

void main() {
  late PincodeService service;

  setUp(() {
    service = PincodeService();
  });

  group('PincodeService API Lookup Tests', () {
    test(
        'returns Success with State, District, and Localities for valid PIN code 560038',
        () async {
      final mockClient = MockClient((request) async {
        expect(request.url.toString(),
            'https://api.postalpincode.in/pincode/560038');
        return http.Response('''
[
  {
    "Message": "Number of pincode found: 2",
    "Status": "Success",
    "PostOffice": [
      {
        "Name": "Indiranagar",
        "District": "Bangalore",
        "State": "Karnataka"
      },
      {
        "Name": "HAL II Stage",
        "District": "Bangalore",
        "State": "Karnataka"
      }
    ]
  }
]
''', 200);
      });

      final result =
          await service.fetchAddressFromPincode('560038', client: mockClient);

      expect(result.isSuccess, isTrue);
      final data = result.dataOrNull!;
      expect(data.state, 'Karnataka');
      expect(data.district, 'Bangalore');
      expect(data.localities, ['Indiranagar', 'HAL II Stage']);
    });

    test('returns ValidationFailure for non-existent / invalid PIN code',
        () async {
      final mockClient = MockClient((request) async {
        return http.Response('''
[
  {
    "Message": "No Records Found.",
    "Status": "Error",
    "PostOffice": null
  }
]
''', 200);
      });

      final result =
          await service.fetchAddressFromPincode('000000', client: mockClient);

      expect(result.isError, isTrue);
      expect(
          result.failureOrNull?.message, 'No address found for this PIN code.');
    });

    test('returns ValidationFailure when pincode is not 6 numeric digits',
        () async {
      final resultShort = await service.fetchAddressFromPincode('5600');
      expect(resultShort.isError, isTrue);

      final resultAlpha = await service.fetchAddressFromPincode('5600AB');
      expect(resultAlpha.isError, isTrue);
    });

    test('returns NetworkFailure on HTTP error response or network timeout',
        () async {
      final mockClient = MockClient((request) async {
        return http.Response('Server Error', 500);
      });

      final result =
          await service.fetchAddressFromPincode('560038', client: mockClient);

      expect(result.isError, isTrue);
      expect(result.failureOrNull?.message,
          'Could not fetch address. Check your connection.');
    });
  });
}
