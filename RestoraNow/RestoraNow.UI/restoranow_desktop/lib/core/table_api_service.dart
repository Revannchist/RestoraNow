import '../models/table_model.dart';
import '../providers/base/base_provider.dart';

class TableApiService extends BaseProvider<TableModel> {
  TableApiService() : super('Table');

  @override
  TableModel fromJson(Map<String, dynamic> json) {
    return TableModel.fromJson(json);
  }
}
