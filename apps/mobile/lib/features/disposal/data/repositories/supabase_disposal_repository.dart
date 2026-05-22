import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:uuid/uuid.dart';

import 'package:eco_wallet/core/errors/disposal_exception.dart';
import 'package:eco_wallet/features/disposal/data/datasources/disposal_api_client.dart';
import 'package:eco_wallet/features/disposal/data/models/disposal_submission_model.dart';
import 'package:eco_wallet/features/disposal/data/models/drop_off_point_model.dart';
import 'package:eco_wallet/features/disposal/domain/entities/disposal_submission.dart';
import 'package:eco_wallet/features/disposal/domain/entities/drop_off_point.dart';
import 'package:eco_wallet/features/disposal/domain/entities/reward_rule.dart';
import 'package:eco_wallet/features/disposal/domain/repositories/disposal_repository.dart';

class SupabaseDisposalRepository implements DisposalRepository {
  SupabaseDisposalRepository({
    sb.SupabaseClient? client,
    DisposalApiClient? apiClient,
    Uuid? uuid,
  }) : _client = client ?? sb.Supabase.instance.client,
       _apiClient = apiClient ?? DisposalApiClient(),
       _uuid = uuid ?? const Uuid();

  static const _photoBucket = 'disposal-photos';
  static const _submissionSelect =
      'id,drop_off_id,storage_path,status,submitted_at,updated_at,'
      'estimated_liters,capture_latitude,capture_longitude,rejection_reason,'
      'drop_off_points(name)';

  final sb.SupabaseClient _client;
  final DisposalApiClient _apiClient;
  final Uuid _uuid;
  sb.RealtimeChannel? _submissionsChannel;
  DisposalSubmissionChanged? _submissionChanged;

  @override
  Future<List<DropOffPoint>> fetchActiveDropOffPoints() async {
    try {
      final rows = await _client
          .from('drop_off_points')
          .select('id,name,campus,address,latitude,longitude')
          .eq('active', true)
          .order('name');

      return (rows as List<dynamic>)
          .map(
            (row) =>
                DropOffPointModel.fromJson(row as Map<String, dynamic>).toEntity(),
          )
          .toList(growable: false);
    } on sb.PostgrestException catch (error) {
      throw DisposalException(_messageFromPostgrest(error));
    }
  }

  @override
  Future<RewardRule?> fetchActiveRewardRule() async {
    try {
      final row =
          await _client
              .from('reward_rules')
              .select('coins_per_liter,min_liters')
              .eq('active', true)
              .order('effective_from', ascending: false)
              .limit(1)
              .maybeSingle();

      if (row == null) {
        return null;
      }

      return RewardRule(
        coinsPerLiter: (row['coins_per_liter'] as num).toInt(),
        minLiters: (row['min_liters'] as num).toDouble(),
      );
    } on sb.PostgrestException catch (error) {
      throw DisposalException(_messageFromPostgrest(error));
    }
  }

  @override
  Future<DisposalSubmission> createSubmission(CreateDisposalInput input) async {
    final submissionId = _uuid.v4();
    final storagePath = '${input.userId}/$submissionId.jpg';

    try {
      await _client.storage.from(_photoBucket).uploadBinary(
        storagePath,
        Uint8List.fromList(input.photoBytes),
        fileOptions: const sb.FileOptions(
          contentType: 'image/jpeg',
          upsert: false,
        ),
      );
    } on sb.StorageException catch (error) {
      throw DisposalException(_messageFromStorage(error));
    }

    try {
      final row =
          await _client
              .from('disposal_submissions')
              .insert({
                'id': submissionId,
                'user_id': input.userId,
                'drop_off_id': input.dropOffId,
                'storage_path': storagePath,
                'status': 'submitted',
                'estimated_liters': input.estimatedLiters,
                'capture_latitude': input.captureLatitude,
                'capture_longitude': input.captureLongitude,
              })
              .select(_submissionSelect)
              .single();

      return DisposalSubmissionModel.fromJson(row).toEntity();
    } on sb.PostgrestException catch (error) {
      throw DisposalException(_messageFromPostgrest(error));
    }
  }

  @override
  Future<void> requestConfidenceScore({
    required String submissionId,
    required String accessToken,
  }) {
    return _apiClient.triggerConfidenceScore(
      submissionId: submissionId,
      accessToken: accessToken,
    );
  }

  @override
  Future<List<DisposalSubmission>> fetchMySubmissions({
    required String userId,
  }) async {
    try {
      final rows = await _client
          .from('disposal_submissions')
          .select(_submissionSelect)
          .eq('user_id', userId)
          .order('submitted_at', ascending: false);

      return (rows as List<dynamic>)
          .map(
            (row) =>
                DisposalSubmissionModel.fromJson(
                  row as Map<String, dynamic>,
                ).toEntity(),
          )
          .toList(growable: false);
    } on sb.PostgrestException catch (error) {
      throw DisposalException(_messageFromPostgrest(error));
    }
  }

  @override
  Future<DisposalSubmission?> fetchSubmissionById({
    required String userId,
    required String submissionId,
  }) async {
    try {
      final row =
          await _client
              .from('disposal_submissions')
              .select(_submissionSelect)
              .eq('user_id', userId)
              .eq('id', submissionId)
              .maybeSingle();

      if (row == null) {
        return null;
      }

      return DisposalSubmissionModel.fromJson(row).toEntity();
    } on sb.PostgrestException catch (error) {
      throw DisposalException(_messageFromPostgrest(error));
    }
  }

  @override
  void subscribeToMySubmissions({
    required String userId,
    required DisposalSubmissionChanged onChanged,
  }) {
    unsubscribeFromMySubmissions();
    _submissionChanged = onChanged;
    _submissionsChannel =
        _client
            .channel('disposal_submissions:$userId')
            .onPostgresChanges(
              event: sb.PostgresChangeEvent.all,
              schema: 'public',
              table: 'disposal_submissions',
              filter: sb.PostgresChangeFilter(
                type: sb.PostgresChangeFilterType.eq,
                column: 'user_id',
                value: userId,
              ),
              callback: (payload) {
                final record = payload.newRecord;
                if (record.isEmpty) {
                  return;
                }
                _submissionChanged?.call(
                  DisposalSubmissionModel.fromJson(record).toEntity(),
                );
              },
            )
            .subscribe();
  }

  @override
  void unsubscribeFromMySubmissions() {
    final channel = _submissionsChannel;
    if (channel != null) {
      _client.removeChannel(channel);
    }
    _submissionsChannel = null;
    _submissionChanged = null;
  }

  String _messageFromPostgrest(sb.PostgrestException error) {
    final message = error.message.toLowerCase();
    if (message.contains('permission') || message.contains('policy')) {
      return 'Sem permissão para registrar o descarte. Entre novamente.';
    }
    return 'Não foi possível registrar o descarte. Tente novamente.';
  }

  String _messageFromStorage(sb.StorageException error) {
    final message = error.message.toLowerCase();
    if (message.contains('payload too large') || message.contains('file size')) {
      return 'A foto é muito grande. Escolha outra imagem.';
    }
    return 'Não foi possível enviar a foto. Tente novamente.';
  }
}
