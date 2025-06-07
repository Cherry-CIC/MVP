import 'package:cherry_mvp/features/discover/discover_repository.dart';
import 'package:cherry_mvp/core/models/model.dart';
import 'package:flutter/cupertino.dart';
import 'package:logging/logging.dart';

class DiscoverViewModel extends ChangeNotifier {

  // ignore: unused_field
  final _log = Logger('DiscoverViewModel');
  final DiscoverRepository discoverRepository;

  DiscoverViewModel({required this.discoverRepository});

  List<Charity> fetchCharities()  {
    return discoverRepository.fetchCharities();
  }

}
