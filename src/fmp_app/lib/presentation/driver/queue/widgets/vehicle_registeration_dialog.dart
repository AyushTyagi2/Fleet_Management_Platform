import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fmp_app/app_session.dart';
// Adjust this import path to match your project structure:
import 'package:fmp_app/core/network/auth_api.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Unskippable vehicle registration dialog.
//
// Shown once before the driver enters the shipment queue.
// Calls POST /drivers/driver-details via AuthApi.submitDriverDetails().
// On success sets AppSession.hasVehicle = true so the dialog is skipped
// for the rest of the session (persist via SharedPreferences if needed).
//
// Usage — in DriverQueueScreen.initState via postFrameCallback:
//
//   await VehicleRegistrationDialog.showIfNeeded(
//     context,
//     driverId: AppSession.driverId ?? '',
//     alreadyRegistered: AppSession.hasVehicle,
//   );
// ─────────────────────────────────────────────────────────────────────────────

class VehicleRegistrationDialog extends StatefulWidget {
  final String driverId;

  const VehicleRegistrationDialog({super.key, required this.driverId});

  static Future<void> showIfNeeded(
    BuildContext context, {
    required String driverId,
    bool alreadyRegistered = false,
  }) async {
    if (alreadyRegistered) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => VehicleRegistrationDialog(driverId: driverId),
    );
  }

  @override
  State<VehicleRegistrationDialog> createState() =>
      _VehicleRegistrationDialogState();
}

// ── Vehicle type options ──────────────────────────────────────────────────────
const _vehicleTypes = [
  _VehicleOption('Mini Truck',   Icons.local_shipping_outlined,  '< 1 Ton'),
  _VehicleOption('Light Truck',  Icons.local_shipping,           '1–3 Ton'),
  _VehicleOption('Medium Truck', Icons.fire_truck,               '3–8 Ton'),
  _VehicleOption('Heavy Truck',  Icons.agriculture_outlined,     '8–20 Ton'),
  _VehicleOption('Trailer',      Icons.rv_hookup,                '20+ Ton'),
  _VehicleOption('Refrigerated', Icons.ac_unit,                  'Any'),
];

class _VehicleRegistrationDialogState
    extends State<VehicleRegistrationDialog> {
  final _formKey     = GlobalKey<FormState>();
  final _plateCtrl   = TextEditingController();
  final _licenseCtrl = TextEditingController();
  final _authApi     = AuthApi();

  String? _selectedType;
  bool    _isSubmitting = false;
  String? _errorMsg;

  @override
  void dispose() {
    _plateCtrl.dispose();
    _licenseCtrl.dispose();
    super.dispose();
  }

  String get _normalisedPlate =>
      _plateCtrl.text.trim().toUpperCase().replaceAll(RegExp(r'\s+'), ' ');

  // ── Validators ────────────────────────────────────────────────────────────

  String? _validatePlate(String? v) {
    if (v == null || v.trim().isEmpty) return 'Vehicle number is required';
    final cleaned = v.trim().replaceAll(' ', '').toUpperCase();
    final re = RegExp(r'^[A-Z]{2}[0-9]{2}[A-Z]{0,2}[0-9]{4}$');
    if (!re.hasMatch(cleaned)) {
      return 'Enter a valid plate number (e.g. DL 01 AB 1234)';
    }
    return null;
  }

  String? _validateLicense(String? v) {
    if (v == null || v.trim().isEmpty) return 'License number is required';
    if (v.trim().length < 6) return 'Enter a valid license number';
    return null;
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _handleSubmit() async {
    setState(() => _errorMsg = null);

    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedType == null) {
      setState(() => _errorMsg = 'Please select a vehicle type');
      return;
    }

    // AppSession.email holds the driver's identifier sent as "Phone" in the API
    final email = AppSession.email;
    if (email == null || email.isEmpty) {
      setState(() => _errorMsg = 'Session error: please re-login.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _authApi.submitDriverDetails(
        email:         email,
        vehicleNumber: _normalisedPlate,
        vehicleType:   _selectedType!,
        licenseNumber: _licenseCtrl.text.trim().toUpperCase(),
      );

      if (!mounted) return;

      AppSession.hasVehicle = true;
      // Persist across sessions if needed:
      // final prefs = await SharedPreferences.getInstance();
      // await prefs.setBool('hasVehicle', true);

      Navigator.of(context).pop(); // dismiss → queue screen proceeds
    } on Exception catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      setState(() {
        _errorMsg     = msg.isNotEmpty ? msg : 'Something went wrong. Please try again.';
        _isSubmitting = false;
      });
    }
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: _buildCard(context),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1B3A6B), Color(0xFF2E75B6)],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.local_shipping,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Vehicle Registration',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Complete your vehicle details before entering the shipment queue.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          // ── Form body ─────────────────────────────────────────────────────
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Vehicle plate
                    const _FieldLabel('Vehicle Number'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _plateCtrl,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9 ]')),
                        LengthLimitingTextInputFormatter(17),
                      ],
                      decoration: _inputDecoration(
                        hint: 'e.g. DL 01 AB 1234',
                        icon: Icons.pin_outlined,
                      ),
                      validator: _validatePlate,
                    ),

                    const SizedBox(height: 16),

                    // License number
                    const _FieldLabel('Driving License Number'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _licenseCtrl,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-]')),
                        LengthLimitingTextInputFormatter(20),
                      ],
                      decoration: _inputDecoration(
                        hint: 'e.g. DL-0420110012345',
                        icon: Icons.badge_outlined,
                      ),
                      validator: _validateLicense,
                    ),

                    const SizedBox(height: 20),

                    // Vehicle type grid
                    const _FieldLabel('Vehicle Type'),
                    const SizedBox(height: 8),
                    _VehicleTypeGrid(
                      selected: _selectedType,
                      onSelect: (t) => setState(() {
                        _selectedType = t;
                        _errorMsg     = null;
                      }),
                    ),

                    // Error banner
                    if (_errorMsg != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline,
                                color: Colors.red.shade600, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMsg!,
                                style: TextStyle(
                                    color: Colors.red.shade700, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),

          // ── Submit button ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B3A6B),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      const Color(0xFF1B3A6B).withOpacity(0.7),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Confirm & Enter Queue',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(
          {required String hint, required IconData icon}) =>
      InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF1B3A6B), size: 20),
        filled: true,
        fillColor: const Color(0xFFF5F7FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF2E75B6), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.red.shade300),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      );
}

// ── Vehicle type grid ─────────────────────────────────────────────────────────

class _VehicleTypeGrid extends StatelessWidget {
  final String?              selected;
  final ValueChanged<String> onSelect;

  const _VehicleTypeGrid({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _vehicleTypes.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:   3,
        childAspectRatio: 1.05,
        crossAxisSpacing: 8,
        mainAxisSpacing:  8,
      ),
      itemBuilder: (_, i) {
        final opt        = _vehicleTypes[i];
        final isSelected = selected == opt.label;
        return GestureDetector(
          onTap: () => onSelect(opt.label),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF1B3A6B)
                  : const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF1B3A6B)
                    : Colors.grey.shade200,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(opt.icon,
                    color: isSelected ? Colors.white : const Color(0xFF1B3A6B),
                    size: 26),
                const SizedBox(height: 4),
                Text(
                  opt.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  opt.capacity,
                  style: TextStyle(
                    fontSize: 9,
                    color: isSelected
                        ? Colors.white.withOpacity(0.75)
                        : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: Color(0xFF1B3A6B),
        ),
      );
}

@immutable
class _VehicleOption {
  final String   label;
  final IconData icon;
  final String   capacity;
  const _VehicleOption(this.label, this.icon, this.capacity);
}