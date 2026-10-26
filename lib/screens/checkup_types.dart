// ─────────────────────────────────────────────────────────────────────────────
// CHECKUP TYPES — OB-GYN / women's reproductive health only
// ─────────────────────────────────────────────────────────────────────────────

/// Label of the dropdown option that lets the user type their own type.
const String kOthersLabel = 'Others';

/// Options shown in the "Appointment Type" dropdown.
const List<String> kAppointmentTypes = [
  'OB-GYN Consultation',
  'Pap Smear',
  'HPV Test',
  'Clinical Breast Exam',
  'Breast Ultrasound / Mammogram',
  'Pelvic Ultrasound',
  'Transvaginal Ultrasound',
  'Hormone Panel',
  'PCOS Check-up',
  'Fibroid / Ovarian Cyst Monitoring',
  'STI Screening',
  'Contraception Consultation',
  'Fertility Consultation',
  'Prenatal Check-up',
  'Postpartum Check-up',
  'Menopause Consultation',
  kOthersLabel,
];

class CheckupSuggestion {
  final String title;
  final String icon;
  final String frequency;
  final String note;
  const CheckupSuggestion({
    required this.title,
    required this.icon,
    required this.frequency,
    required this.note,
  });
}

const List<CheckupSuggestion> kSuggestions = [
  CheckupSuggestion(
    title: 'OB-GYN Consultation',
    icon: '👩‍⚕️',
    frequency: 'Yearly',
    note: 'Annual well-woman exam',
  ),
  CheckupSuggestion(
    title: 'Pap Smear',
    icon: '🔬',
    frequency: 'Every 3 years',
    note: 'Cervical cancer screening',
  ),
  CheckupSuggestion(
    title: 'HPV Test',
    icon: '🧪',
    frequency: 'Every 5 years',
    note: 'Screens for high-risk HPV types',
  ),
  CheckupSuggestion(
    title: 'Clinical Breast Exam',
    icon: '🏥',
    frequency: 'Yearly',
    note: 'By a healthcare professional',
  ),
  CheckupSuggestion(
    title: 'Breast Ultrasound / Mammogram',
    icon: '🎗️',
    frequency: 'As advised',
    note: 'Imaging for breast health',
  ),
  CheckupSuggestion(
    title: 'Pelvic Ultrasound',
    icon: '📡',
    frequency: 'As advised',
    note: 'For PCOS or fibroid monitoring',
  ),
  CheckupSuggestion(
    title: 'Transvaginal Ultrasound',
    icon: '📡',
    frequency: 'As advised',
    note: 'Detailed view of uterus and ovaries',
  ),
  CheckupSuggestion(
    title: 'Hormone Panel',
    icon: '⚗️',
    frequency: 'As needed',
    note: 'Estrogen, progesterone, thyroid',
  ),
  CheckupSuggestion(
    title: 'PCOS Check-up',
    icon: '🩺',
    frequency: 'As needed',
    note: 'Follow-up for irregular cycles',
  ),
  CheckupSuggestion(
    title: 'Fibroid / Ovarian Cyst Monitoring',
    icon: '🩻',
    frequency: 'As advised',
    note: 'Track size and symptoms',
  ),
  CheckupSuggestion(
    title: 'STI Screening',
    icon: '🛡️',
    frequency: 'Yearly',
    note: 'Recommended for sexually active women',
  ),
  CheckupSuggestion(
    title: 'Contraception Consultation',
    icon: '💊',
    frequency: 'As needed',
    note: 'Birth control options and review',
  ),
  CheckupSuggestion(
    title: 'Fertility Consultation',
    icon: '🌱',
    frequency: 'As needed',
    note: 'Planning or trouble conceiving',
  ),
  CheckupSuggestion(
    title: 'Prenatal Check-up',
    icon: '🤰',
    frequency: 'As advised',
    note: 'Regular visits during pregnancy',
  ),
  CheckupSuggestion(
    title: 'Postpartum Check-up',
    icon: '👶',
    frequency: 'As advised',
    note: 'Recovery check after delivery',
  ),
  CheckupSuggestion(
    title: 'Menopause Consultation',
    icon: '🌸',
    frequency: 'As needed',
    note: 'Symptoms and hormone therapy options',
  ),
];