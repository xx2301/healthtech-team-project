class PatientService {
    constructor() {
        this.patients = []; // In-memory patient storage
        this.nextId = 1;
    }

    getAllPatients() {
        return {
            success: true,
            data: this.patients, 
            count: this.patients.length,
            message: "Retrieved all patients"
        };
    }

    getPatientById(id) {
        const patient = this.patients.find(p => p.id === id);
        if (patient) {
            return {
                success: true,
                data: patient
            };
        }
        return {
            success: false,
            message: "Patient not found"
        };
    }

    createPatient(patientData) {
        const newPatient = {
            id: this.nextId++,
            ...patientData,
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString()
        };

        this.patients.push(newPatient);

        return {
            success: true,
            data: newPatient,
            message: "Patient created successfully"
        };
    }

    updatePatient(id, updateData) {
        const patientIndex = this.patients.findIndex(p => p.id === id);
        if (patientIndex === -1) {
            return {
                success: false,
                message: "Patient not found"
            };
        }

        this.patients[patientIndex] = {
            ...this.patients[patientIndex],
            ...updateData,
            updatedAt: new Date().toISOString()
        };

        return {
            success: true,
            data: this.patients[patientIndex],
            message: "Patient updated successfully"
        };
    }

    deletePatient(id) {
        const initialLength = this.patients.length;
        this.patients = this.patients.filter(p => p.id !== id);

        if (this.patients.length < initialLength) {
            return {
                success: true,
                message: "Patient deleted successfully"
            };
        }
        return {
            success: false,
            message: "Patient not found"
        };
    }

    initializeTestData() {
        this.patients = [
            {
                id: 1,
                name: "Zhang Wei",
                age: 45,
                gender: "male",
                condition: "Hypertension",
                contact: "13800138001",
                address: "Beijing Chaoyang District",
                lastVisit: "2024-01-15",
                status: "stable"
            },
            {
                id: 2,
                name: "Lee Fang",
                age: 32,
                gender: "female",
                condition: "Diabetes",
                contact: "13800138002",
                address: "Shanghai Pudong New District",
                lastVisit: "2024-01-10",
                status: "monitoring"
            }
        ];
        this.nextId = 3;

        return {
            success: true,
            message: "Test data initialized"
        };
    }
}

module.exports = new PatientService();