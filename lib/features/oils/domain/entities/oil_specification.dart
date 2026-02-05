import 'oil_approval.dart';

class OilSpecification {
  final int id;
  final String title;
  final int viscosityId;
  final String viscosityTitle;
  final List<OilApproval> aceas;
  final List<OilApproval> apis;
  final List<OilApproval> oemApprovals;
  final List<OilApproval> ilsacs;

  OilSpecification({
    required this.id,
    required this.title,
    required this.viscosityId,
    required this.viscosityTitle,
    required this.aceas,
    required this.apis,
    required this.oemApprovals,
    required this.ilsacs,
  });
}
