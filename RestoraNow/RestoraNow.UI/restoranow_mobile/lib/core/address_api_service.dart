import '../providers/base/base_provider.dart';
import '../models/address_model.dart';

class AddressApiService extends BaseProvider<AddressModel> {
  AddressApiService() : super('Address');

  @override
  AddressModel fromJson(Map<String, dynamic> json) {
    return AddressModel.fromJson(json);
  }
}
