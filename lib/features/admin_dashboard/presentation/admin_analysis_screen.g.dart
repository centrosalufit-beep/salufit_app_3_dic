// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_analysis_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AdminAnalysis)
const adminAnalysisProvider = AdminAnalysisProvider._();

final class AdminAnalysisProvider
    extends $AsyncNotifierProvider<AdminAnalysis, List<AnalysisMetric>> {
  const AdminAnalysisProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminAnalysisProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminAnalysisHash();

  @$internal
  @override
  AdminAnalysis create() => AdminAnalysis();
}

String _$adminAnalysisHash() => r'250d339981742ced33c51b8d9945a82ce11633d4';

abstract class _$AdminAnalysis extends $AsyncNotifier<List<AnalysisMetric>> {
  FutureOr<List<AnalysisMetric>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref
            as $Ref<AsyncValue<List<AnalysisMetric>>, List<AnalysisMetric>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<AnalysisMetric>>,
                List<AnalysisMetric>
              >,
              AsyncValue<List<AnalysisMetric>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
