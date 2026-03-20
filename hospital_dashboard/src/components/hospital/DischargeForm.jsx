/**
 * Discharge Form (H7) — Phase 2
 *
 * Used by hospital staff to register a patient into SalamaRecover
 * at the point of discharge. This creates the patient profile
 * and sends them an SMS/WhatsApp with download instructions.
 *
 * Fields: patient name, phone, surgery type, date, assigned doctor.
 */

export default function DischargeForm() {
  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-900 mb-6">Discharge Patient</h1>
      <div className="bg-white rounded-xl border border-gray-200 p-10 text-center">
        <span className="text-4xl">📋</span>
        <p className="text-gray-500 mt-3 text-lg">Discharge Form</p>
        <p className="text-gray-400 text-sm mt-1">
          Coming in Phase 2 — register patients into SalamaRecover at discharge
        </p>
      </div>
    </div>
  );
}
