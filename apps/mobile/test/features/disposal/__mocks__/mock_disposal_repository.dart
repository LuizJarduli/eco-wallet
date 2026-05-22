import 'package:mocktail/mocktail.dart';

import 'package:eco_wallet/features/disposal/domain/repositories/disposal_repository.dart';
import 'package:eco_wallet/features/disposal/domain/services/disposal_location_provider.dart';

class MockDisposalRepository extends Mock implements DisposalRepository {}

class MockDisposalLocationProvider extends Mock
    implements DisposalLocationProvider {}
