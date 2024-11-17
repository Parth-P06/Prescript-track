module prescription_tracking::PrescriptionTracker {
    use std::vector;
    use std::timestamp;
    use std::signer::address_of;
    use aptos_framework::account::exists_at;

    /// Error codes
    const E_PRESCRIPTION_EXPIRED: u64 = 1;
    const E_PRESCRIPTION_NOT_FOUND: u64 = 2;
    const E_UNAUTHORIZED: u64 = 3;

    /// Struct representing a prescription
    struct Prescription has store {
        patient_address: address,
        doctor_address: address,
        medication_name: vector<u8>,
        expiry_timestamp: u64,
        is_valid: bool
    }

    /// Resource to store prescriptions for a patient
    struct PatientPrescriptions has key {
        prescriptions: vector<Prescription>
    }

    /// Create a new prescription for a patient
    public entry fun create_prescription(
        doctor: &signer,
        patient_addr: address,
        medication: vector<u8>,
        validity_period: u64
    ) acquires PatientPrescriptions {
        let prescription = Prescription {
            patient_address: patient_addr,
            doctor_address: address_of(doctor),
            medication_name: medication,
            expiry_timestamp: timestamp::now_seconds() + validity_period,
            is_valid: true
        };

        if (!exists_at(patient_addr)) {
            move_to(doctor, PatientPrescriptions { prescriptions: vector::empty() });
        };
        
        let patient_prescriptions = borrow_global_mut<PatientPrescriptions>(patient_addr);
        vector::push_back(&mut patient_prescriptions.prescriptions, prescription);
    }

    /// Verify if a prescription is valid (without returning any value)
    public entry fun verify_prescription(
        patient_addr: address,
        medication: vector<u8>
    ) acquires PatientPrescriptions {
        assert!(exists_at(patient_addr), E_PRESCRIPTION_NOT_FOUND);
        
        let patient_prescriptions = borrow_global<PatientPrescriptions>(patient_addr);
        let current_time = timestamp::now_seconds();
        
        let mut is_valid_prescription = false;
        let len = vector::length(&patient_prescriptions.prescriptions);
        
        let i = 0;
        while (i < len) {
            let prescription = vector::borrow(&patient_prescriptions.prescriptions, i);
            if (prescription.medication_name == medication && 
                prescription.is_valid && 
                prescription.expiry_timestamp > current_time) {
                is_valid_prescription = true;
                break;
            };
            i = i + 1;
        };

        // If no valid prescription was found, throw an error
        assert!(is_valid_prescription, E_PRESCRIPTION_EXPIRED);
    }
}
